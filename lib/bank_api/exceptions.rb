module BankApi
  class MissingCredentialsError < StandardError; end
  module Balance
    class InvalidAccountNumber < StandardError; end
    class MissingAccountBalance < StandardError; end
  end
  module Deposit
    class QuantityError < StandardError; end
    class PaginationError < StandardError; end
  end
  module Transfer
    class InvalidBank < StandardError; end
    class InvalidAccountType < StandardError; end
    class MissingTransferData < StandardError; end
  end
end
