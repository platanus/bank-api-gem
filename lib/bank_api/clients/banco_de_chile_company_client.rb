require 'rest-client'
require 'timezone'

require 'bank_api/clients/base_client'

module BankApi::Clients
  class BancoDeChileCompanyClient < BaseClient
    COMPANY_LOGIN_URL = 'https://www.empresas.bancochile.cl/cgi-bin/navega?pagina=enlinea/login_fus'
    COMPANY_DEPOSITS_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/ConsultaRecibidaAction.do'
    COMPANY_DEPOSITS_TXT_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/RespuestaConsultaRecibidaAction.do'
    COMPANY_CC_BALANCE_URL = 'https://www.empresas.bancochile.cl/CCOLDerivadorWEB/selectorCuentas.do?accion=initSelectorCuentas&opcion=saldos&moduloProducto=CC'

    DATE_COLUMN = 0
    RUT_COLUMN = 4
    AMOUNT_COLUMN = 6
    STATE_COLUMN = 7

    NUMBER_OF_COLUMNS = 9

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

    def get_balance
      login
      goto_balance
      select_account
      click_fetch_balance_button
      read_balance
    end

    def goto_balance
      browser.goto COMPANY_CC_BALANCE_URL
    end

    def select_account
      first_account = browser.search("select[name=cuenta] option").find do |account|
        account.value.include? @bdc_account
      end.value
      browser.search("select[name=cuenta]").set by_value: first_account
    end

    def click_fetch_balance_button
      browser.search('#btnSeleccionarCuenta').click
    end

    def read_balance
      browser.search('table.detalleSaldosMov tr:nth-child(2) > td.aRight.bold').text
    end

    def get_deposits(_options = {})
      login
      goto_deposits
      select_deposits_range
      deposits = deposits_from_txt
      deposits
    ensure
      browser.close
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

    def goto_deposits
      browser.goto COMPANY_DEPOSITS_URL
    end

    def select_deposits_range
      browser.search('input[name=initDate]').set(deposit_range[:start])
      first_account = browser.search("select[name=ctaCorriente] option").find do |account|
        account.value.include? @bdc_account
      end.value
      browser.search("select[name=ctaCorriente]").set by_value: first_account
      browser.search('#consultar').click
    end

    def validate_banchile_status!
      unless browser.search(".textoerror:contains('no podemos atenderle')").none?
        raise "Banchile is down"
      end
    end

    def any_deposits?
      browser.search('table#sin_datos').none?
    end

    def total_results
      browser.search("#pager .encabezadotabla:contains(\"Operaciones encontradas\")")
             .text[/\d+/].to_i
    end

    def deposits_from_txt
      validate_banchile_status!
      return [] unless any_deposits?
      response = RestClient::Request.execute(
        url: COMPANY_DEPOSITS_TXT_URL, method: :post, headers: session_headers,
        payload: deposits_params(deposit_range[:start], deposit_range[:end]), verify_ssl: false
      )
      raise "Banchile is down" if response.body.include? "no podemos atenderle"

      transactions = split_transactions(response.body)
      format_transactions(transactions)
    rescue => e
      validate_banchile_status!
      raise e
    end

    def split_transactions(transactions_str)
      transactions_str.delete("\r").split("\n").drop(1).map { |r| r.split(";") }.select do |t|
        t[STATE_COLUMN] == "Aprobada"
      end
    end

    def format_transactions(transactions)
      transactions.map do |t|
        {
          rut: t[RUT_COLUMN],
          date: Date.parse(t[DATE_COLUMN]),
          amount: t[AMOUNT_COLUMN].to_i
        }
      end
    end

    def deposits_params(from_date, to_date)
      {
        'accion' => 'exportarTxtOperaciones',
        'initDate' => from_date,
        'endDate' => to_date,
        'ctaCorriente' => 'TODAS',
        'nada' => 'nada'
      }
    end

    def session_headers
      {
        "Cookie" => "JSESSIONID=#{cookie('JSESSIONID')}; token=#{cookie('token')}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/" +
          "apng,*/*;q=0.8",
        "Accept-Encoding" => "gzip, deflate, br",
        "Referer" => "https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/" +
          "RespuestaConsultaRecibidaAction.do"
      }
    end

    def cookie(name)
      selenium_browser.manage.cookie_named(name)[:value]
    end

    def deposit_range
      @deposit_range ||= begin
        timezone = Timezone['America/Santiago']
        today = timezone.utc_to_local(Time.now).to_date
        { start: (today - @days_to_check).strftime("%d/%m/%Y"), end: today.strftime("%d/%m/%Y") }
      end
    end
  end
end
