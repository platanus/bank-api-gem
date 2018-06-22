# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Balance
    ACCOUNT_NUMBER_COLUMN = 0
    AVAILABLE_BALANCE_COLUMN = 1
    COUNTABLE_BALANCE_COLUMN = 2

    def find_account_balance(account_number)
      balance = browser.search(".cuentas-corrientes").search("tbody tr").map do |row|
        cells = row.search("td")
        {
          account_number: cells[ACCOUNT_NUMBER_COLUMN].text,
          available_balance: money_to_i(cells[AVAILABLE_BALANCE_COLUMN].text),
          countable_balance: money_to_i(cells[COUNTABLE_BALANCE_COLUMN].text)
        }
      end.find do |row|
        row[:account_number] == account_number
      end
      validate_balance(balance, account_number)
      balance
    end

    def money_to_i(text)
      text.delete(".").delete("$").delete(" ").to_i
    end

    def validate_balance(balance, account_number)
      if balance.nil?
        raise BankApi::Balance::InvalidAccountNumber, "Couldn't find balance of account " +
          account_number.to_s
      end
    end
  end
end
