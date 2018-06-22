module BankApi::Clients::Navigation
  module BancoSecurity
    module CompanyNavigation
      BASE_URL = 'https://empresas.bancosecurity.cl/'

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

      def goto_company_dashboard(company_rut = nil)
        goto_frame query: '#topFrame'
        if browser.search(".empresa a:contains(\"cambiar\")").any?
          selenium_browser.execute_script(
            "MM_goToURL('parent.frames[\\'mainFrame\\']'," +
              "'/empresas/RedirectConvivencia.asp?urlRedirect=Perfilamiento/Home/Index')"
          )
        end
        goto_frame query: '#mainFrame'
        goto_frame(query: 'iframe[name="central"]', should_reset: false)
        selenium_browser.execute_script(
          "submitEntrar(true,1," +
            "#{without_verifier_digit_or_separators(company_rut || @company_rut)}," +
            "'#{verifier_digit(company_rut || @company_rut)}');"
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

      def goto_balance
        goto_frame query: '#topFrame'
        selenium_browser.execute_script(
          "MM_goToURL('parent.frames[\\'topFrame\\']','../menu/MenuTopInicio.asp'," +
          "'parent.frames[\\'leftFrame\\']','../menu/MenuInicio.asp'," +
          "'parent.frames[\\'mainFrame\\']','../../../noticias/arriba_noticias.asp');" +
          "return document.MM_returnValue;"
        )
        selenium_browser.execute_script(
          "MM_goToURL('parent.frames[\\'mainFrame\\']'," +
          "'/empresas/RedirectConvivencia.asp?urlRedirect" +
          "=Cartola/Home/CartolaOrSaldoCuentaCorriente')"
        )
        goto_frame query: '#mainFrame'
        goto_frame query: 'iframe[name="central"]', should_reset: false
      end

      def goto_transfer_form
        goto_frame query: '#topFrame'
        selenium_browser.execute_script(
          "MM_goToURL('parent.frames[\\'topFrame\\']','../menu/MenuTopTransferencias.asp'," +
            "'parent.frames[\\'leftFrame\\']','../menu/MenuTransferencias.asp'," +
            "'parent.frames[\\'mainFrame\\']','../../../noticias/transferencias.asp');"
        )
        selenium_browser.execute_script(
          "MM_goToURL('parent.frames[\\'mainFrame\\']'," +
            "'/empresas/RedirectConvivencia.asp?urlRedirect=Transferencia/Tabs/Home')"
        )
        goto_frame query: '#mainFrame'
        goto_frame query: 'iframe[name="central"]', should_reset: false
      end
    end
  end
end
