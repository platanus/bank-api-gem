require 'cgi'
require 'timezone'

require 'bank_api/clients/base_client'
require 'bank_api/clients/banco_security/concerns/statements'
require 'bank_api/clients/banco_security/concerns/deposits'
require 'bank_api/clients/banco_security/concerns/login'
require 'bank_api/clients/banco_security/concerns/transfers'
require 'bank_api/clients/navigation/banco_security/company_navigation'
require 'bank_api/utils/banco_security'

module BankApi::Clients::BancoSecurity
  class CompanyClient < BankApi::Clients::BaseClient
    include BankApi::Clients::Navigation::BancoSecurity::CompanyNavigation
    include BankApi::Clients::BancoSecurity::Statements
    include BankApi::Clients::BancoSecurity::Deposits
    include BankApi::Clients::BancoSecurity::Transfers
    include BankApi::Clients::BancoSecurity::Login

    def initialize(config = BankApi::Configuration.new)
      @user_rut = config.banco_security.user_rut
      @password = config.banco_security.password
      @company_rut = config.banco_security.company_rut
      @dynamic_card = config.banco_security.dynamic_card
      @page_size = config.banco_security.page_size
      super
    end

    def bank_name
      :security
    end

    def get_deposits
      login
      goto_company_dashboard
      goto_deposits
      select_deposits_range
      deposits = deposits_from_txt
      validate_deposits(deposits) unless deposits.empty?
      deposits
    ensure
      browser.close
    end

    def get_current_statement(account_number, company_rut)
      login
      goto_company_dashboard(company_rut || @company_rut)
      goto_current_statement
      select_current_statement(account_number)
      account_current_statement_from_txt
    ensure
      browser.close
    end

    def get_statement_of_month(account_number, month, year, company_rut)
      login
      goto_company_dashboard(company_rut || @company_rut)
      goto_account_statements
      select_statement(account_number, month, year)
      account_statement_from_txt
    ensure
      browser.close
    end

    def execute_transfer(transfer_data)
      login
      goto_company_dashboard(transfer_data[:origin] || @company_rut)
      goto_transfer_form
      submit_transfer_form(transfer_data)
      fill_coordinates
    ensure
      browser.close
    end

    def execute_batch_transfers(transfers_data)
      login
      transfers_data.each do |transfer_data|
        goto_company_dashboard(transfer_data[:origin] || @company_rut)
        goto_transfer_form
        submit_transfer_form(transfer_data)
        fill_coordinates
      end
    ensure
      browser.close
    end

    def get_company_statement(account_number:, month:, year:, company_rut: nil)
      get_statement(
        account_number: account_number, month: month, year: year, company_rut: company_rut
      )
    end

    def goto_frame(query: nil, should_reset: true)
      sleep 1
      super
      sleep 0.2
    end
  end
end
