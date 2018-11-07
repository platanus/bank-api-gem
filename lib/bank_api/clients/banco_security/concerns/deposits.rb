# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Deposits
    def select_deposits_range
      browser.search('.BusquedaPorDefectoRecibida a:contains("búsqueda avanzada")').click
      browser.search('#RadioEntreFechasRecibido').click
      fill_date_inputs
      wait('.ContenedorSubmitRecibidas .btn_buscar').click
      wait_for_deposits_fetch
    end

    def fill_date_inputs
      start_element = browser.search('#datePickerInicioRecibidas').elements.first
      start_element.send_key "-"
      deposit_range[:start].strftime('%d%m%Y').chars.each do |c|
        start_element.send_key c
        sleep 0.1
      end
      end_element = browser.search('#datePickerFinRecibido').elements.first
      end_element.send_key "-"
      deposit_range[:end].strftime('%d%m%Y').chars.each do |c|
        end_element.send_key c
        sleep 0.1
      end
    end

    def wait_for_deposits_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').any? }
      wait('.k-loading-image') { browser.search('.k-loading-image').none? }
    end

    def deposits_from_txt
      wait("") { any_deposits? }
      raise BankApi::Deposit::FetchError, "Couldn't fetch deposits" unless any_deposits?
      download = browser.download(deposits_txt_url)
      transactions = download.content.split("\n").drop(1).map { |r| r.split("|") }
      format_transactions(transactions)
    end

    def deposits_from_account_details
      data = browser.download(
        deposits_account_details_url
      ).content.encode("UTF-8", "iso-8859-3").split("\r\n")
      transactions = data[3, data.count - 11].reverse
      format_account_transactions(transactions)
    end

    def format_transactions(transactions)
      transactions.map do |t|
        datetime = timezone.local_to_utc(DateTime.parse(t[0]))
        {
          client: t[1],
          rut: format_rut(t[2]),
          date: datetime.to_date,
          time: datetime,
          amount: t[5].to_i
        }
      end
    end

    def format_account_transactions(transactions)
      transactions.inject([]) do |memo, t|
        parts = t.split(";")
        amount = parts[4].delete(",").to_i
        next memo if amount.zero?
        client = extract_client_name(parts[1])

        memo << {
          client: client,
          rut: nil,
          date: Date.strptime(parts[0], "%d/%m"),
          time: nil,
          amount: amount
        }

        memo
      end
    end

    def extract_client_name(text)
      parts = text.to_s.split(" De ")
      parts = text.to_s.split(" DE ") if parts.count == 1
      return text if parts.count > 2
      parts.last.to_s.strip
    end

    def deposit_range
      @deposit_range ||= begin
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

    def deposits_account_details_url
      browser.search("a:contains('Descargar TXT')").first.attribute("href")
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

    def timezone
      @timezone ||= Timezone['America/Santiago']
    end
  end
end
