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

  def self.get_bdc_recent_company_deposits
    Clients::BancoDeChileCompanyClient.new(configuration).get_recent_deposits
  end

  module BancoSecurity
    def self.get_account_balance(account_number)
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration).get_balance(account_number)
    end

    def self.get_recent_company_deposits
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration).get_recent_deposits
    end

    def self.company_transfer(transfer_data)
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration).transfer(transfer_data)
    end

    def self.company_batch_transfers(transfers_data)
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration)
                                           .batch_transfers(transfers_data)
    end
  end
end
