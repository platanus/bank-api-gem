# coding: utf-8
require 'rest-client'

module BankApi::Clients::BancoSecurity
  module Deposits
    SESSION_VALIDATION = "https://www.bancosecurity.cl/empresas/SessionValidation.asp"

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

    def setup_authentication
      response = RestClient::Request.execute(
        url: SESSION_VALIDATION, method: :post, headers: session_headers
      )
      new_cookies = response.headers[:set_cookie].first.delete(" ").split(";").map do |a|
        a.split("=")
      end
      new_cookies.each do |key, value|
        selenium_browser.manage.add_cookie(name: key, value: value)
      end
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
      parts = text.to_s.split(/\ DE | De | de /, 2)
      parts.last.to_s.strip
    end

    def deposit_range
      @deposit_range ||= begin
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check), end: today }
      end
    end

    def session_headers
      {
        "Origin" => "https://www.bancosecurity.cl",
        "Accept-Encoding" => "gzip, deflate, br",
        "Accept-Language" => "en-US,en;q=0.9",
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36",
        "Accept" => "*/*",
        "Referer" => "https://www.bancosecurity.cl/ConvivenciaEmpresas/CartolasTEF/Home?" + "
          tipoTransaccion=Recibidas",
        "X-Requested-With" => "XMLHttpRequest",
        "Connection" => "keep-alive",
        "Content-Length" => "0",
        "Cookie" => cookies
      }
    end

    def cookies
      selenium_browser.manage.all_cookies.map do |cookie|
        "#{cookie[:name]}=#{cookie[:value]}"
      end.join("; ")
    end

    def deposits_txt_url
      selenium_browser.execute_script("console.log(DescargarDocumentoTxtRecibidas)")
      log = selenium_browser.manage.logs.get(:browser).last
      /url = '(.*)';/.match(log.message).captures.first
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
