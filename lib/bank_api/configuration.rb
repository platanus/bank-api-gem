module BankApi
  class Configuration
    attr_accessor :bdc_user_rut, :bdc_password, :bdc_company_rut, :days_to_check

    def initialize
      @bdc_user_rut = nil
      @bdc_password = nil
      @bdc_company_rut = nil

      @days_to_check = 6
    end
  end
end
