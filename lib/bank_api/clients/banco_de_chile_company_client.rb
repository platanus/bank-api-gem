require 'rest-client'
require 'timezone'

require 'bank_api/clients/base_client'
require 'bank_api/utils/banco_de_chile'

module BankApi::Clients
  class BancoDeChileCompanyClient < BaseClient
    COMPANY_LOGIN_URL = 'https://www.empresas.bancochile.cl/cgi-bin/navega?pagina=enlinea/login_fus'
    COMPANY_DEPOSITS_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/ConsultaRecibidaAction.do'
    COMPANY_WITHDRAWALS_URL = 'https://www.empresas.bancochile.cl/TefMasivasWEB/consulta.do?accion=consulta&vacio=0'
    COMPANY_PREPARE_DEPOSITS_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/RespuestaConsultaRecibidaAction.do'
    COMPANY_PREPARE_WITHDRAWALS_URL = 'https://www.empresas.bancochile.cl/TefMasivasWEB/consulta.do'
    COMPANY_DEPOSITS_TXT_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/RespuestaConsultaRecibidaAction.do'
    COMPANY_WITHDRAWALS_TXT_URL = 'https://www.empresas.bancochile.cl/TefMasivasWEB/consulta.do'
    COMPANY_ACCOUNT_DEPOSITS_URL = 'https://www.empresas.bancochile.cl/CCOLSaldoMovimientosWEB/selectorCuentas.do?accion=initSelectorCuentas&cuenta=001642711701&moneda=CTD#page=page-1'
    COMPANY_CC_BALANCE_URL = 'https://www.empresas.bancochile.cl/CCOLDerivadorWEB/selectorCuentas.do?accion=initSelectorCuentas&opcion=saldos&moduloProducto=CC'

    def initialize(config = BankApi::Configuration.new)
      @bdc_company_rut = config.bdc_company_rut
      @bdc_user_rut = config.bdc_user_rut
      @bdc_password = config.bdc_password
      @bdc_account = config.bdc_account
      super
    end

    def bank_name
      :bancochile
    end

    private

    def validate_credentials
      raise BankApi::MissingCredentialsError if [
        @bdc_company_rut,
        @bdc_user_rut,
        @bdc_password
      ].any?(&:nil?)
    end

    def get_balance(options)
      login
      goto_balance
      select_account(options[:account_number])
      click_fetch_balance_button
      {
        account_number: options[:account_number],
        available_balance: money_to_i(read_balance(:available)),
        countable_balance: money_to_i(read_balance(:countable))
      }
    ensure
      browser.close
    end

    def goto_balance
      browser.goto COMPANY_CC_BALANCE_URL
    end

    def select_account(account_number)
      first_account = browser.search("select[name=cuenta] option").find do |account|
        account.value.include? account_number
      end.value
      browser.search("select[name=cuenta]").set by_value: first_account
    end

    def click_fetch_balance_button
      browser.search('#btnSeleccionarCuenta').click
    end

    def money_to_i(text)
      text.delete(".").delete("$").delete(" ").to_i
    end

    def read_balance(balance_kind)
      return '' unless [:available, :countable].include? balance_kind

      if balance_kind == :available
        return browser.search('table.detalleSaldosMov tr:nth-child(2) > td.aRight.bold').text
      end

      browser.search('table.detalleSaldosMov tr:first-child > td.aRight.bold').text
    end

    def get_deposits(options = {})
      login

      if options[:source] == :account_details
        return get_deposits_from_balance_section
      end

      get_deposits_from_transfers_section
    ensure
      browser.close
    end

    def get_withdrawals
      login

      get_withdrawals_from_transfers_section
    ensure
      browser.close
    end

    def get_deposits_from_balance_section
      goto_account_deposits
      account_deposits_from_txt
    end

    def get_deposits_from_transfers_section
      goto_deposits
      deposits_from_txt
    end

    def get_withdrawals_from_transfers_section
      goto_withdrawals
      withdrawals_from_txt
    end

    def login
      goto_login_url
      set_login_values
      click_login_button
    end

    def goto_login_url
      browser.goto COMPANY_LOGIN_URL
    end

    def set_login_values
      browser.search('#rutemp1').set without_verifier_digit_or_separators(@bdc_company_rut)
      browser.search('#dvemp1').set verifier_digit(@bdc_company_rut)
      browser.search('#rut1').set without_verifier_digit_or_separators(@bdc_user_rut)
      browser.search('#verificador1').set verifier_digit(@bdc_user_rut)
      browser.search('#pin1').set @bdc_password
    end

    def click_login_button
      browser.search('.btn_amarillodegrade').click
    end

    def goto_account_deposits
      browser.goto COMPANY_ACCOUNT_DEPOSITS_URL
    end

    def goto_deposits
      browser.goto COMPANY_DEPOSITS_URL
    end

    def goto_withdrawals
      browser.goto COMPANY_WITHDRAWALS_URL
    end

    def account_deposits_from_txt
      url = browser.search("#expoDato_child > a:nth-child(3)").attribute(:href)
      result = browser.download(url)
                      .content.encode("UTF-8", "iso-8859-3")
                      .delete("\r").split("\n").drop(2)
      format_account_transactions(result)
    end

    def validate_banchile_status!
      unless browser.search(".textoerror:contains('no podemos atenderle')").none?
        raise "Banchile is down"
      end
    end

    def deposits_from_txt
      prepare_deposits
      response = RestClient::Request.execute(
        url: COMPANY_DEPOSITS_TXT_URL, method: :post, headers: session_headers,
        payload: deposits_txt_payload(date_range[:start], date_range[:end]), verify_ssl: true
      )
      raise "Banchile is down" if response.body.include? "no podemos atenderle"
      transactions = split_deposit_transactions(response.body)
      format_deposit_transactions(transactions)
    rescue => e
      validate_banchile_status!
      raise e
    end

    def prepare_deposits
      RestClient::Request.execute(
        url: COMPANY_PREPARE_DEPOSITS_URL, method: :post, headers: session_headers,
        payload: prepare_deposits_payload(date_range[:start], date_range[:end]),
        verify_ssl: true
      )
    end

    def withdrawals_from_txt
      prepare_withdrawals
      response = RestClient::Request.execute(
        url: COMPANY_WITHDRAWALS_TXT_URL, method: :post, headers: session_headers,
        payload: withdrawals_txt_payload(date_range[:start], date_range[:end])
      )
      raise "Banchile is down" if response.body.include? "no podemos atenderle"
      transactions = split_withdrawal_transactions(response.body)
      format_withdrawal_transactions(transactions)
    rescue => e
      validate_banchile_status!
      raise e
    end

    def prepare_withdrawals
      RestClient::Request.execute(
        url: COMPANY_PREPARE_WITHDRAWALS_URL, method: :post, headers: session_headers,
        payload: prepare_withdrawals_payload(date_range[:start], date_range[:end])
      )
    end

    def split_deposit_transactions(transactions_str)
      transactions_str.delete("\r").split("\n").drop(1).map { |r| r.split(";") }.select do |t|
        t[7] == "Aprobada"
      end
    end

    def split_withdrawal_transactions(transactions_str)
      transactions_str.delete("\r").split("\n")
    end

    def format_deposit_transactions(transactions)
      transactions.map do |t|
        {
          client: format_client_name(t[3]),
          rut: t[4],
          date: Date.parse(t[0]),
          time: nil,
          amount: t[6].to_i
        }
      end
    end

    def format_withdrawal_transactions(transactions)
      transactions.map do |t|
        {
          rut: Utils::BancoDeChile.format_rut(t[25..34]),
          client: format_client_name(t[35..64].strip),
          account_number: t[65..82].strip,
          amount: t[93..103].to_i,
          email: t[166..216].strip
        }
      end
    end

    def format_account_transactions(transactions)
      transactions.inject([]) do |memo, t|
        parts = t.split(";")
        amount = parts[3].to_i
        next memo if amount.zero?

        memo << {
          client: format_client_name(parts[1]),
          rut: nil,
          date: Date.parse(parts[0]),
          time: nil,
          amount: amount
        }

        memo
      end
    end

    def format_client_name(name)
      name.to_s.split("DE:").last.to_s.strip
    end

    def padded_account
      "0" * (12 - @bdc_account.length) + @bdc_account
    end

    def prepare_deposits_payload(from_date, to_date)
      base_deposits_payload(from_date, to_date).merge('accion' => 'buscarOperaciones')
    end

    def deposits_txt_payload(from_date, to_date)
      base_deposits_payload(from_date, to_date).merge('accion' => 'exportarTxtOperaciones')
    end

    def prepare_withdrawals_payload(from_date, to_date)
      base_withdrawals_payload(from_date, to_date).merge('accion' => 'consulta')
    end

    def withdrawals_txt_payload(from_date, to_date)
      base_withdrawals_payload(from_date, to_date).merge('accion' => 'exportarTxt')
    end

    def base_deposits_payload(from_date, to_date)
      {
        'initDate' => from_date,
        'endDate' => to_date,
        'ctaCorriente' => padded_account,
        'nada' => 'nada'
      }
    end

    def base_withdrawals_payload(from_date, to_date)
      {
        "llavePre" => "",
        "llaveIns" => "",
        "rutIns" => "",
        "pag" => "",
        "campo" => "",
        'initDate' => from_date,
        'endDate' => to_date,
        "cuentaCargo" => padded_account,
        "destinatario" => "",
        "operacion" => "",
        "estado" => "12",
        'nada' => 'nada'
      }
    end

    def session_headers
      {
        "Pragma" => "no-cache",
        "Connection" => "keep-alive",
        "Cache-Control" => "no-cache",
        "Upgrade-Insecure-Requests" => 1,
        "Content-Type" => "application/x-www-form-urlencoded",
        "Origin" => "https://www.empresas.bancochile.cl",
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9," +
          "image/webp,image/apng,*/*;q=0.8",
        "Accept-Encoding" => "gzip, deflate, br",
        "Cookie" => cookies
      }
    end

    def cookies
      selenium_browser.manage.all_cookies.map do |cookie|
        "#{cookie[:name]}=#{cookie[:value]}"
      end.join("; ")
    end

    def cookie(name)
      selenium_browser.manage.cookie_named(name)[:value]
    end

    def date_range
      @date_range ||= begin
        timezone = Timezone['America/Santiago']
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check).strftime("%d/%m/%Y"), end: today.strftime("%d/%m/%Y") }
      end
    end
  end
end
