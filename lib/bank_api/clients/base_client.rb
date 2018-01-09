require 'pincers'

require 'bank_api/exceptions'
require 'bank_api/sign_deposits'
require 'bank_api/values/deposit_entry'

module BankApi::Clients
  class BaseClient
    def initialize(config = BankApi::Configuration.new)
      @days_to_check = config.days_to_check
    end

    def get_recent_deposits
      validate_credentials
      parse_entries(get_deposits)
    end

    private

    def validate_credentials
      raise NotImplementedError
    end

    def get_deposits
      raise NotImplementedError
    end

    def without_verifier_digit_or_separators(rut)
      rut.split("-")[0].delete('.')
    end

    def verifier_digit(rut)
      rut.split("-")[1]
    end

    def browser
      @browser ||= Pincers.for_webdriver :chrome
    end

    def parse_entries(entries)
      deposit_entries = entries.map do |entry|
        BankApi::Values::DepositEntry.new(
          entry[:amount],
          entry[:date],
          entry[:rut]
        )
      end
      BankApi::SignDeposits.sign(deposit_entries)
    end
  end
end
