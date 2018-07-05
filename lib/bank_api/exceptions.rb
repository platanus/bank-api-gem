module BankApi
  class MissingCredentialsError < StandardError; end
  module Deposit
    class QuantityError < StandardError; end
    class PaginationError < StandardError; end
  end
  module Transfer
    class InvalidBank < StandardError; end
    class InvalidAmount < StandardError; end
    class InvalidAccountType < StandardError; end
    class InvalidAccountData < StandardError; end
    class InvalidTrxId < StandardError; end
    class MissingTransferData < StandardError; end
  end
end
