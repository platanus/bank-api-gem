require "bank_api/configuration"
require "bank_api/configs/banco_security"
require "bank_api/version"
require 'bank_api/clients/banco_de_chile_company_client'
require 'bank_api/clients/banco_security/company_client'

module BankApi
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.get_bdc_recent_company_deposits(options = {})
    Clients::BancoDeChileCompanyClient.new(configuration).get_recent_deposits(options)
  end

  def self.get_bdc_account_balance(options = {})
    Clients::BancoDeChileCompanyClient.new(configuration).get_account_balance(options)
  end

  module BancoSecurity
    def self.get_account_balance(options = {})
      company_instance.get_balance(options)
    end

    def self.get_recent_company_deposits(options = {})
      company_instance.get_recent_deposits(options)
    end

    def self.get_recent_company_withdrawals
      company_instance.get_recent_withdrawals
    end

    def self.company_transfer(transfer_data)
      company_instance.transfer(transfer_data)
    end

    def self.company_batch_transfers(transfers_data)
      company_instance.batch_transfers(transfers_data)
    end

    def self.company_instance
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration)
    end
  end
end
