module BankApi::Values
  class WithdrawalEntry
    attr_accessor :amount, :date, :time, :rut, :client, :account_number, :account_bank, :trx_id,
      :bank

    def initialize(amount, date, time, rut, client, account_number, account_bank, trx_id, bank)
      @amount = amount
      @date = date
      @time = time
      @rut = rut
      @client = client
      @account_number = account_number
      @account_bank = account_bank
      @trx_id = trx_id
      @bank = bank
    end
  end
end
