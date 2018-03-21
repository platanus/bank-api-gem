module BankApi::Values
  class DepositEntry
    attr_accessor :amount, :date, :rut, :signature, :bank

    def initialize(amount, date, rut, bank)
      @amount = amount
      @date = date
      @rut = rut
      @bank = bank
    end
  end
end
