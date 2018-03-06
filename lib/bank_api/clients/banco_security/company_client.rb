require 'timezone'

require 'bank_api/clients/base_client'
require 'bank_api/clients/banco_security/company_client_deposits'
require 'bank_api/clients/banco_security/company_client_transfers'
require 'bank_api/clients/navigation/banco_security/company_navigation'
require 'bank_api/utils/banco_security'

module BankApi::Clients::BancoSecurity
  class CompanyClient < BankApi::Clients::BaseClient
    include BankApi::Clients::Navigation::BancoSecurity::CompanyNavigation
    include BankApi::Clients::BancoSecurity::CompanyClientDeposits
    include BankApi::Clients::BancoSecurity::CompanyClientTransfers

    DATE_COLUMN = 0
    RUT_COLUMN = 2
    AMOUNT_COLUMN = 5

    NUMBER_OF_COLUMNS = 7

    def initialize(config = BankApi::Configuration.new)
      @user_rut = config.banco_security.user_rut
      @password = config.banco_security.password
      @company_rut = config.banco_security.company_rut
      @dynamic_card = config.banco_security.dynamic_card
      super
    end

    def get_deposits
      login
      goto_company_dashboard
      goto_deposits
      select_deposits_range
      deposits = any_deposits? ? extract_deposits_from_html : []
      browser.close
      deposits
    end

    def execute_transfer(transfer_data)
      login
      goto_company_dashboard(transfer_data[:origin])
      go_to_transfer_form
      submit_transfer_form(transfer_data)
      fill_coordinates
      binding.pry
    end

    def execute_batch_transfers(transfers_data)
      login
      goto_company_dashboard(transfer_data[:origin])
      transfers_data.each do |transfer_data|
        go_to_transfer_form
        submit_transfer_form(transfer_data)
      end
    end

    def validate_credentials
      raise BankApi::MissingCredentialsError if [
        @user_rut,
        @password,
        @company_rut
      ].any?(&:nil?)
    end

    def login
      goto_login
      set_login_values
      click_login_button
    end

    def set_login_values
      browser.search('#lrut').set @user_rut
      browser.search('#lpass').set @password
    end

    def click_login_button
      browser.search('input[name="Entrar"]').click
    end

    def goto_frame(query: nil, should_reset: true)
      sleep 1
      browser.goto frame: :top if should_reset
      frame = wait(query) if query
      browser.goto(frame: frame)
      sleep 0.2
    end
  end
end
