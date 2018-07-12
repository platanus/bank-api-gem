# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Statements
    DATE_CHARACTERS = (1..10)
    DESCRIPTION_CHARACTERS = (11..60)
    TRX_ID_CHARACTERS = (61..69)
    TRX_TYPE_CHARACTER = 70
    AMOUNT_CHARACTERS = (72..86)
    BALANCE_CHARACTERS = (87..101)

    DATE_COLUMN = 0
    DESCRIPTION_COLUMN = 1
    TRX_ID_COLUMN = 2
    CHARGE_COLUMN = 3
    DEPOSIT_COLUMN = 4
    BALANCE_COLUMN = 5

    def select_current_statement(account_number)
      formated_account_number = Utils::Account.format_account(account_number)
      if browser.search(".cuentas-corrientes").any?
        accounts = browser.search(".cuentas-corrientes").map do |row|
          row.search("td").first.search("a")
        end
        account = accounts.find { |a| a.text == formated_account_number }
        raise StandardError, "Statement of given account number is unavailable" if account.nil?
        account.click
        wait("#datos-cuenta")
      end
      if browser.search("#datos-cuenta").attribute("data-numero-cuenta") != formated_account_number
        raise StandardError, "Statement of given account number is unavailable"
      end
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
      raise StandardError, "Statement of given account number is unavailable"
    end

    def select_month(month, year)
      wait("select[name=\"fecha\"]").set by_value: "#{month.to_s.rjust(2, '0')}#{year}"
    rescue
      raise StandardError, "Statement of given month and year is unavailable"
    end

    def account_current_statement_from_txt
      dl = browser.search("a:contains('Descargar TXT')").download
      dl.content.delete("\r").split("\n")[3..-9].map do |row|
        parse_current_statement_movements(row.split(";"))
      end
    rescue
      raise StandardError, "Statement of given account number is unavailable"
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

    def parse_current_statement_movements(row)
      {
        date: Date.parse(row[DATE_COLUMN].split("/").reverse.join("/")),
        description: row[DESCRIPTION_COLUMN].strip.force_encoding("utf-8"),
        trx_id: row[TRX_ID_COLUMN].strip,
        trx_type: current_statement_trx_type(row),
        amount: [row[CHARGE_COLUMN].delete(",").to_i, row[DEPOSIT_COLUMN].delete(",").to_i].max,
        balance: row[BALANCE_COLUMN].delete(",").to_i
      }
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

    def current_statement_trx_type(row)
      return :deposit if row[DEPOSIT_COLUMN].to_i.positive?
      return :charge if row[CHARGE_COLUMN].to_i.positive?
      raise StandardError, "Trx with non positive deposit and charge"
    end

    def statement_trx_type(row)
      return :deposit if row[TRX_TYPE_CHARACTER] == "A"
      return :charge if row[TRX_TYPE_CHARACTER] == "C"
      raise StandardError, "Statement with trx of unknown type \"#{row[TRX_TYPE_CHARACTER]}\""
    end
  end
end
