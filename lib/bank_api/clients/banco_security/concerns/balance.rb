# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Balance
    ACCOUNT_NUMBER_COLUMN = 0
    AVAILABLE_BALANCE_COLUMN = 1
    COUNTABLE_BALANCE_COLUMN = 2

    def find_account_balance(account_number)
      return get_balance_from_accounts_list(account_number) if account_number
      get_balance_from_account_summary
    end

    def get_balance_from_accounts_list(account_number)
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
      validate_account_balance(balance, account_number)
      balance
    end

    def get_balance_from_account_summary
      available_balance = extract_balance(1)
      countable_balance = extract_balance(2)
      validate_summary_balance(available_balance, countable_balance)

      {
        available_balance: available_balance,
        countable_balance: countable_balance
      }
    end

    def validate_account_balance(balance, account_number)
      if balance.nil?
        raise BankApi::Balance::InvalidAccountNumber, "Couldn't find balance of account " +
          account_number.to_s
      end
    end

    def validate_summary_balance(available_balance, countable_balance)
      if available_balance.zero? || countable_balance.zero?
        raise BankApi::Balance::MissingAccountBalance, "Couldn't find balance"
      end
    end

    def extract_balance(td_pos)
      xp = "//*[@id=\"body\"]/div[1]/section/div/div/div[3]/div[2]/table/tbody/tr[1]/td[#{td_pos}]"
      money_to_i(browser.search(xpath: xp).text)
    end

    def money_to_i(text)
      text.to_s.delete(".").delete("$").delete(" ").to_i
    end
  end
end
