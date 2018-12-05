require 'cgi'
require 'timezone'

require 'bank_api/clients/base_client'
require 'bank_api/clients/banco_security/concerns/balance'
require 'bank_api/clients/banco_security/concerns/deposits'
require 'bank_api/clients/banco_security/concerns/login'
require 'bank_api/clients/banco_security/concerns/session'
require 'bank_api/clients/banco_security/concerns/transfers'
require 'bank_api/clients/banco_security/concerns/withdrawals'
require 'bank_api/clients/navigation/banco_security/company_navigation'
require 'bank_api/utils/banco_security'

module BankApi::Clients::BancoSecurity
  class CompanyClient < BankApi::Clients::BaseClient
    include BankApi::Clients::Navigation::BancoSecurity::CompanyNavigation
    include BankApi::Clients::BancoSecurity::Balance
    include BankApi::Clients::BancoSecurity::Deposits
    include BankApi::Clients::BancoSecurity::Withdrawals
    include BankApi::Clients::BancoSecurity::Transfers
    include BankApi::Clients::BancoSecurity::Login
    include BankApi::Clients::BancoSecurity::Session

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

    def get_balance(options)
      login
      goto_company_dashboard(options[:rut] || @company_rut)
      goto_balance
      find_account_balance(options[:account_number])
    ensure
      browser.close
    end

    def get_deposits(options = {})
      login
      goto_company_dashboard

      if options[:source] == :account_details
        return get_deposits_from_balance_section(options[:account_number])
      end

      get_deposits_from_transfers_section
    ensure
      browser.close
    end

    def get_withdrawals
      login
      goto_company_dashboard
      goto_withdrawals
      select_withdrawals_range
      withdrawals = withdrawals_from_json
      validate_withdrawals(withdrawals) unless withdrawals.empty?
      withdrawals
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

    def get_deposits_from_transfers_section
      goto_deposits
      select_deposits_range
      deposits_from_txt
    end

    def get_deposits_from_balance_section(account_number)
      fail "missing :account_number option" unless account_number
      goto_balance
      goto_account_details(account_number.to_s)
      deposits_from_account_details
    end

    def goto_frame(query: nil, should_reset: true)
      sleep 1
      super
      sleep 0.2
    end
  end
end
