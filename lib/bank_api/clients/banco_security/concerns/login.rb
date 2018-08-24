module BankApi::Clients::BancoSecurity
  module Login
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
      browser.search('.btn-ingreso').click
    end
  end
end
