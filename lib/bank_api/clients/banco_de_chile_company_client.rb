require 'timezone'

require 'bank_api/clients/base_client'

module BankApi::Clients
  class BancoDeChileCompanyClient < BaseClient
    COMPANY_LOGIN_URL = 'https://www.empresas.bancochile.cl/cgi-bin/navega?pagina=enlinea/login_fus'
    COMPANY_DEPOSITS_URL = 'https://www.empresas.bancochile.cl/GlosaInternetEmpresaRecibida/ConsultaRecibidaAction.do'

    TABLE_OFFSET = 1

    DATE_COLUMN = 0
    RUT_COLUMN = 4
    AMOUNT_COLUMN = 6
    STATE_COLUMN = 7

    NUMBER_OF_COLUMNS = 9

    def initialize(config = BankApi::Configuration.new)
      @bdc_company_rut = config.bdc_company_rut
      @bdc_user_rut = config.bdc_user_rut
      @bdc_password = config.bdc_password
      super
    end

    private

    def validate_credentials
      raise BankApi::MissingCredentialsError if [
        @bdc_company_rut,
        @bdc_user_rut,
        @bdc_password
      ].any?(&:nil?)
    end

    def get_deposits
      login
      goto_deposits
      select_deposits_range
      submit_deposits_form
      deposits = extract_deposits_from_html
      browser.close
      deposits
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
      timezone = Timezone['America/Santiago']
      range_start = (
        timezone.utc_to_local(Time.now).to_date - @days_to_check
      ).strftime("%d/%m/%Y")
      browser.search('input[name=initDate]').set(range_start)
    end

    def submit_deposits_form
      browser.search('#consultar').click
    end

    def extract_deposits_from_html
      deposits = []
      deposit = {}
      browser.search('.linea1tabla').each_with_index do |div, index|
        if ((index - TABLE_OFFSET) % NUMBER_OF_COLUMNS) == RUT_COLUMN
          deposit[:rut] = div.text
        elsif ((index - TABLE_OFFSET) % NUMBER_OF_COLUMNS) == DATE_COLUMN
          deposit[:date] = Date.parse div.text
        elsif ((index - TABLE_OFFSET) % NUMBER_OF_COLUMNS) == AMOUNT_COLUMN
          deposit[:amount] = div.text.delete(',')
        elsif ((index - TABLE_OFFSET) % NUMBER_OF_COLUMNS) == STATE_COLUMN
          deposits << deposit if div.text == 'Aprobada'
          deposit = {}
        end
      end
      deposits
    end
  end
end
