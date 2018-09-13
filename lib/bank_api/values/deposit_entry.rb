module BankApi::Values
  class DepositEntry
    attr_accessor :client, :amount, :date, :time, :rut, :signature, :bank

    def initialize(amount, date, time, rut, bank, client)
      @amount = amount
      @date = date
      @time = time
      @rut = rut
      @bank = bank
      @client = client
    end
  end
end
