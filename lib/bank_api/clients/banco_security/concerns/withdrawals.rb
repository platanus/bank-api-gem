# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Withdrawals
    WITHDRAWALS_URL = 'https://www.bancosecurity.cl/ConvivenciaEmpresas/CartolasTEF/Home/ConsultarEnviadasEmpresas'

    def select_withdrawals_range
      browser.search('.BusquedaPorDefectoEnv a:contains("búsqueda avanzada")').click
      browser.search('#RadioEntreFechasEnviadoE').click
      fill_withdrawal_date_inputs
      wait('.ContenedorSubmitEnviadas .btn_buscar').click
      wait_for_withdrawals_fetch
    end

    def fill_withdrawal_date_inputs
      start_element = browser.search('#datePickerInicioEnviadoE').elements.first
      start_element.send_key "-"
      withdrawal_range[:start].strftime('%d%m%Y').chars.each do |c|
        start_element.send_key c
        sleep 0.1
      end
      end_element = browser.search('#datePickerFinEnviadoE').elements.first
      end_element.send_key "-"
      withdrawal_range[:end].strftime('%d%m%Y').chars.each do |c|
        end_element.send_key c
        sleep 0.1
      end
    end

    def wait_for_withdrawals_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').none? }
    end

    def withdrawals_from_json
      raise BankApi::Withdrawal::FetchError, "Couldn't fetch withdrawals" unless any_withdrawals?
      setup_authentication
      response = RestClient::Request.execute(
        url: WITHDRAWALS_URL, method: :post, headers: session_headers,
        payload: withdrawals_payload(deposit_range[:start], deposit_range[:end])
      )
      transactions = JSON.parse(response.body)["Items"]
      format_withdrawal_transactions(transactions)
    end

    def format_withdrawal_transactions(transactions)
      transactions.map do |t|
        datetime = Time.at(t["Fecha"].match(/(\d+)/)[0].to_i / 1000)
        {
          client: t["NombreDestino"],
          account_bank: t["BancoDestino"],
          account_number: t["CuentaDestino"],
          rut: Utils::BancoSecurity.format_rut(t["RutDestino"]),
          email: t["MailDestino"],
          date: datetime.to_date,
          time: datetime,
          amount: t["Monto"],
          trx_id: t["NumeroTransaccion"]
        }
      end
    end

    def withdrawals_payload(start_date, end_date)
      {
        "parametro" => "", "numeroCuenta" => account_number_variable, "monto" => 0, "opcion" => "",
        "fechaInicio" => "#{start_date} 0:00:00", "fechaFin" => "#{end_date} 0:00:00",
        "estado" => 1, "tipoTransaccion" => "", "take" => 1000, "skip" => 0, "page" => 1,
        "pageSize" => 1000, "sort[0][field]" => "Fecha", "sort[0][dir]" => "desc"
      }
    end

    def withdrawal_range
      @withdrawal_range ||= begin
        timezone = Timezone['America/Santiago']
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check), end: today }
      end
    end

    def total_withdrawals
      pages_info = wait(".k-pager-info")
      matches = pages_info.text.match(/(\d+)[a-z\s-]+(\d+)[a-z\s-]+(\d+)/)
      matches[3].to_i
    end

    def any_withdrawals?
      browser.search(
        "#gridPrincipalEnviadasE " \
        ".k-label:contains('No se han encontrado transacciones para la búsqueda seleccionada.')"
      ).none?
    end

    def account_number_variable
      selenium_browser.manage.logs.get(:browser).last
      selenium_browser.execute_script("console.log(nCuenta)")
      log = selenium_browser.manage.logs.get(:browser).last
      /\"(.*)\"/.match(log.message).captures.first
    end

    def validate_withdrawals(withdrawals)
      total_withdrawals_ = total_withdrawals
      unless withdrawals.count == total_withdrawals_
        raise BankApi::Withdrawal::QuantityError, "Expected #{total_withdrawals_} withdrawals," +
          " got #{withdrawals.count}."
      end
    end
  end
end
