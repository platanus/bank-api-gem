module BankApi::Values
  class DepositEntry
    attr_accessor :amount, :date, :rut, :signature

    def initialize(amount, date, rut)
      @amount = amount
      @date = date
      @rut = rut
    end
  end
end
