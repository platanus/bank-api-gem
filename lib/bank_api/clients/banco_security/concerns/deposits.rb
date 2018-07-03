# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Deposits
    DATE_COLUMN = 0
    RUT_COLUMN = 2
    AMOUNT_COLUMN = 5

    def select_deposits_range
      browser.search('.BusquedaPorDefectoRecibida a:contains("búsqueda avanzada")').click
      browser.search('#RadioEntreFechasRecibido').click
      browser.search('#datePickerInicioRecibidas').set deposit_range[:start].strftime('%d/%m/%Y')
      browser.search('#datePickerFinRecibido').set deposit_range[:end].strftime('%d/%m/%Y')
      wait('.ContenedorSubmitRecibidas .btn_buscar').click
      wait_for_deposits_fetch
    end

    def wait_for_deposits_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').any? }
      wait('.k-loading-image') { browser.search('.k-loading-image').none? }
    end

    def deposits_from_txt
      return [] unless any_deposits?
      download = browser.download(deposits_txt_url)
      transactions = download.content.split("\n").drop(1).map { |r| r.split("|") }
      format_transactions(transactions)
    end

    def format_transactions(transactions)
      transactions.map do |t|
        {
          rut: format_rut(t[RUT_COLUMN]),
          date: Date.parse(t[DATE_COLUMN].split[0]),
          amount: t[AMOUNT_COLUMN].to_i
        }
      end
    end

    def deposit_range
      @deposit_range ||= begin
        timezone = Timezone['America/Santiago']
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check), end: today }
      end
    end

    def deposits_txt_url
      account_number = CGI.escape(selenium_browser.execute_script('return nCuenta'))
      start_ = CGI.escape("#{deposit_range[:start].strftime('%m/%d/%Y')} 00:00:00")
      end_ = CGI.escape("#{deposit_range[:end].strftime('%m/%d/%Y')} 00:00:00")
      "https://www.bancosecurity.cl/ConvivenciaEmpresas/CartolasTEF/Download/" +
        "CrearTxTRecibidas?numeroCuenta=#{account_number}&monto=0&" +
        "fechaInicio=#{start_}&fechaFin=#{end_}&estado=1"
    end

    def format_rut(rut)
      verification_digit = rut[-1]
      without_verification_digit = rut[0..-2].reverse.scan(/.{1,3}/).join(".").reverse
      "#{without_verification_digit}-#{verification_digit}"
    end

    def total_deposits
      pages_info = wait(".k-pager-info")
      matches = pages_info.text.match(/(\d+)[a-z\s-]+(\d+)[a-z\s-]+(\d+)/)
      matches[3].to_i
    end

    def any_deposits?
      browser.search(
        "#gridPrincipalRecibidas " \
        ".k-label:contains('No se han encontrado transacciones para la búsqueda seleccionada.')"
      ).none?
    end

    def validate_deposits(deposits)
      total_deposits_ = total_deposits
      unless deposits.count == total_deposits_
        raise BankApi::Deposit::QuantityError, "Expected #{total_deposits_} deposits," +
          " got #{deposits.count}."
      end
    end
  end
end
