require "bank_api/configuration"
require "bank_api/configs/banco_security"
require "bank_api/version"
require 'bank_api/clients/banco_de_chile_company_client'
require 'bank_api/clients/banco_security/company_client'
require 'bank_api/utils/rut'
require 'bank_api/utils/account'

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
    def self.get_recent_company_deposits
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration).get_recent_deposits
    end

    def self.get_company_current_statement(account_number:, company_rut: nil)
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration)
                                           .get_current_statement(
                                             account_number,
                                             company_rut
                                           )
    end

    def self.get_company_statement(account_number:, month:, year:, company_rut: nil)
      Clients::BancoSecurity::CompanyClient.new(BankApi.configuration)
                                           .get_statement(
                                             account_number: account_number,
                                             month: month,
                                             year: year,
                                             company_rut: company_rut
                                           )
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
