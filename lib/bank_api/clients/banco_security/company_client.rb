require 'timezone'

require 'bank_api/clients/base_client'

module BankApi::Clients::BancoSecurity
  class CompanyClient < BankApi::Clients::BaseClient
    BASE_URL = 'https://empresas.bancosecurity.cl/'

    DATE_COLUMN = 0
    RUT_COLUMN = 2
    AMOUNT_COLUMN = 5

    NUMBER_OF_COLUMNS = 7

    def initialize(config = BankApi::Configuration.new)
      @user_rut = config.banco_security.user_rut
      @password = config.banco_security.password
      @company_rut = config.banco_security.company_rut
      super
    end

    def get_deposits
      login
      goto_company_dashboard
      goto_deposits
      select_deposits_range
      deposits = extract_deposits_from_html
      browser.close
      deposits
    end

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

    def goto_login
      if session_expired?
        browser.search("button:contains('Ingresa nuevamente')").click
        browser.search("a:contains('Empresas')").click
      else
        browser.goto BASE_URL
        browser.search('#mrcBtnIngresa').click
      end
    end

    def session_expired?
      browser.search("button:contains('Ingresa nuevamente')").any?
    end

    def set_login_values
      browser.search('#lrut').set @user_rut
      browser.search('#lpass').set @password
    end

    def click_login_button
      browser.search('input[name="Entrar"]').click
    end

    def goto_company_dashboard
      goto_frame query: '#mainFrame'
      goto_frame(query: 'iframe[name="central"]', should_reset: false)
      selenium_browser.execute_script(
        "submitEntrar(true,1,#{without_verifier_digit_or_separators(@company_rut)}," +
          "'#{verifier_digit(@company_rut)}');"
      )
    end

    def goto_deposits
      goto_frame query: '#topFrame'
      selenium_browser.execute_script(
        "MM_goToURL('parent.frames[\\'topFrame\\']','../menu/MenuTopTransferencias.asp'," +
          "'parent.frames[\\'leftFrame\\']','../menu/MenuTransferencias.asp'," +
          "'parent.frames[\\'mainFrame\\']','../../../noticias/transferencias.asp');"
      )
      selenium_browser.execute_script(
        "MM_goToURL('parent.frames[\\'mainFrame\\']'," +
          "'/empresas/RedirectConvivencia.asp?urlRedirect=CartolasTEF/Home/Index')"
      )
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('a.k-link:contains("Recibidas")').click
    end

    def select_deposits_range
      browser.search('.BusquedaPorDefectoRecibida a:contains("búsqueda avanzada")').click
      browser.search('#RadioEntreFechasRecibido').click
      browser.search('#datePickerInicioRecibidas').set deposit_range[:start]
      browser.search('#datePickerFinRecibido').set deposit_range[:end]
      browser.search('.ContenedorSubmitRecibidas .btn_buscar').click
      wait_for_deposits_fetch
    end

    def wait_for_deposits_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').count.zero? }
    end

    def extract_deposits_from_html
      deposits = []

      return deposits unless any_deposits?

      deposits += deposits_from_page

      ((total_results - 1) / 50).times do
        goto_next_page
        deposits += deposits_from_page
      end

      deposits.sort_by { |d| d[:date] }
    end

    def deposits_from_page
      deposits = []
      deposit = {}
      browser.search('#gridPrincipalRecibidas tbody td').each_with_index do |div, index|
        if (index % NUMBER_OF_COLUMNS) == RUT_COLUMN
          deposit[:rut] = div.text
        elsif (index % NUMBER_OF_COLUMNS) == DATE_COLUMN
          deposit[:date] = Date.parse div.text
        elsif (index % NUMBER_OF_COLUMNS) == AMOUNT_COLUMN
          deposit[:amount] = div.text.gsub(/[\. $]/, '').to_i
        elsif ((index + 1) % NUMBER_OF_COLUMNS).zero?
          deposits << deposit
          deposit = {}
        end
      end
      deposits
    end

    def goto_next_page
      browser.search('#gridPrincipalRecibidas a.k-link[title="Go to the next page"]').click
    end

    def total_results
      browser.search('#gridPrincipalRecibidas .k-pager-info')
             .text.scan(/\d+/).last.to_i
    end

    def deposit_range
      @deposit_range ||= begin
        timezone = Timezone['America/Santiago']
        {
          start: (timezone.utc_to_local(Time.now).to_date - @days_to_check).strftime('%d/%m/%Y'),
          end: timezone.utc_to_local(Time.now).to_date.strftime('%d/%m/%Y')
        }
      end
    end

    def any_deposits?
      browser.search(
        ".k-label:contains('No se han encontrado transacciones para la búsqueda seleccionada.')"
      ).any?
    end

    def goto_frame(query: nil, should_reset: true)
      sleep 1
      browser.goto frame: :top if should_reset
      frame = wait(query) if query
      browser.goto(frame: frame)
      sleep 0.2
    end
  end
end
