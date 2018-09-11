module BankApi
  class Configuration
    attr_accessor :bdc_user_rut, :bdc_password, :bdc_company_rut, :bdc_account, :days_to_check

    def initialize
      @bdc_user_rut = nil
      @bdc_password = nil
      @bdc_company_rut = nil
      @bdc_account = nil

      @days_to_check = 6
    end

    def banco_security
      @banco_security ||= BankApi::Configs::BancoSecurity.new
    end
  end
end
