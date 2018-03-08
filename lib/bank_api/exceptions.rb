module BankApi
  class MissingCredentialsError < StandardError; end
  module Transfer
    class InvalidBank < StandardError; end
    class InvalidAccountType < StandardError; end
    class MissingTransferData < StandardError; end
  end
end
