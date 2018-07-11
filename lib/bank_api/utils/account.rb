module Utils
  module Account
    extend self

    def format_account(number)
      number.match(/0*([0-9]*)/)[1]
    end
  end
end
