# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Session
    SESSION_VALIDATION = "https://www.bancosecurity.cl/empresas/SessionValidation.asp"

    def setup_authentication
      response = RestClient::Request.execute(
        url: SESSION_VALIDATION, method: :post, headers: session_headers
      )
      new_cookies = response.headers[:set_cookie].first.delete(" ").split(";").map do |a|
        a.split("=")
      end
      new_cookies.each do |key, value|
        selenium_browser.manage.add_cookie(name: key, value: value)
      end
    end

    def session_headers
      {
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 " +
          "(KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36",
        "Accept" => "*/*",
        "Cookie" => cookies
      }
    end

    def cookies
      selenium_browser.manage.all_cookies.map do |cookie|
        "#{cookie[:name]}=#{cookie[:value]}"
      end.join("; ")
    end
  end
end
