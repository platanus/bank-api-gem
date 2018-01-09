require "bank_api/configuration"
require "bank_api/version"
require 'bank_api/clients/banco_de_chile_company_client'

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
end
