# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Statements
    DATE_CHARACTERS = (1..10)
    DESCRIPTION_CHARACTERS = (11..60)
    TRX_ID_CHARACTERS = (61..69)
    TRX_TYPE_CHARACTER = 70
    AMOUNT_CHARACTERS = (72..86)
    BALANCE_CHARACTERS = (87..101)

    def goto_account_statements
      goto_frame query: '#leftFrame'
      selenium_browser.execute_script(
        "MM_goToURL(" +
        "'parent.frames[\\'mainFrame\\']'," +
        "'/empresas/cashmngfinal/cuenta_corriente/cuenta_historica_sel.asp?COD_SRV=1311'" +
        ");"
      )
      goto_frame query: '#mainFrame'
      wait(".Tit1:contains('cartola histórica')")
    end

    def select_statement(account_number, month, year)
      select_account(account_number)
      select_month(month, year)
      browser.search("a > img[alt=\"Consultar\"]").click
    end

    def select_account(account_number)
      formated_account_number = Utils::Account.format_account(account_number)
      wait("select[name=\"Keyword\"]").set formated_account_number
    rescue
      raise StandardError, "Statement of given account doesn't exist"
    end

    def select_month(month, year)
      wait("select[name=\"fecha\"]").set by_value: "#{month.to_s.rjust(2, '0')}#{year}"
    rescue
      raise StandardError, "Statement of given month and year doesn't exist"
    end

    def account_statement_from_txt
      wait("div:contains('Cartolas disponibles')")
      unless statement_available?
        raise StandardError, "Statement of given month and account number is unavailable"
      end
      dl = browser.search("a")[1].download
      dl.content.delete("\r").split("\n")[1..-2].map do |row|
        parse_statement_movements(row.force_encoding("utf-8"))
      end
    end

    def statement_available?
      browser.search("b:contains('No existen movimientos para el periodo seleccionado')").none?
    end

    def parse_statement_movements(row)
      {
        date: Date.parse(row[DATE_CHARACTERS]),
        description: row[DESCRIPTION_CHARACTERS].strip,
        trx_id: row[TRX_ID_CHARACTERS].strip,
        trx_type: statement_trx_type(row),
        amount: row[AMOUNT_CHARACTERS].to_i,
        balance: row[BALANCE_CHARACTERS].to_i
      }
    end

    def statement_trx_type(row)
      return :deposit if row[TRX_TYPE_CHARACTER] == "A"
      return :charge if row[TRX_TYPE_CHARACTER] == "C"
      raise StandardError, "Statement with trx of unknown type \"#{row[TRX_TYPE_CHARACTER]}\""
    end
  end
end
