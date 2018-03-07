module BankApi::Configs
  class BancoSecurity
    attr_accessor :user_rut, :password, :company_rut

    def initialize
      @user_rut = nil
      @password = nil
      @company_rut = nil
    end
  end
end
