# coding: utf-8
require 'rest-client'

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
      raise BankApi::Deposit::FetchError, "Couldn't fetch deposits" unless any_deposits?
      setup_authentication
      download = browser.download(deposits_txt_url)
      transactions = download.content.split("\n").drop(1).map { |r| r.split("|") }
      if transactions.empty?
        raise BankApi::Deposit::FetchError, "Couldn't fetch deposits, received #{download.content}"
      end
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
          rut: Utils::BancoSecurity.format_rut(t[2]),
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
      parts = text.to_s.split(/\ DE | De | de /, 2)
      parts.last.to_s.strip
    end

    def deposit_range
      @deposit_range ||= begin
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check), end: today }
      end
    end

    def deposits_txt_url
      selenium_browser.execute_script("console.log(DescargarDocumentoTxtRecibidas)")
      log = selenium_browser.manage.logs.get(:browser).last
      /url = '(.*)';/.match(log.message).captures.first
    end

    def deposits_account_details_url
      browser.search("a:contains('Descargar TXT')").first.attribute("href")
    end

    def any_deposits?
      browser.search(
        "#gridPrincipalRecibidas " \
        ".k-label:contains('No se han encontrado transacciones para la búsqueda seleccionada.')"
      ).none?
    end

    def timezone
      @timezone ||= Timezone['America/Santiago']
    end
  end
end
