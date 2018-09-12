require 'pincers'
require 'selenium-webdriver'

require 'bank_api/exceptions'
require 'bank_api/sign_deposits'
require 'bank_api/values/deposit_entry'

module BankApi::Clients
  class BaseClient
    def initialize(config = BankApi::Configuration.new)
      @days_to_check = config.days_to_check
    end

    def get_recent_deposits(options = {})
      validate_credentials
      parse_entries(get_deposits(options))
    end

    def transfer(transfer_data)
      validate_credentials
      validate_transfer_missing_data(transfer_data)
      validate_transfer_valid_data(transfer_data)
      execute_transfer(transfer_data)
    end

    def batch_transfers(transfers_data)
      validate_credentials
      transfers_data.each do |transfer_data|
        validate_transfer_missing_data(transfer_data)
        validate_transfer_valid_data(transfer_data)
      end
      execute_batch_transfers(transfers_data)
    end

    private

    def bank_name
      raise NotImplementedError
    end

    def validate_credentials
      raise NotImplementedError
    end

    def get_deposits(_options = {})
      raise NotImplementedError
    end

    def validate_transfer_missing_data(_transfer_data)
      raise NotImplementedError
    end

    def validate_transfer_valid_data(_transfer_data)
      raise NotImplementedError
    end

    def execute_transfer(_transfer_data)
      raise NotImplementedError
    end

    def execute_batch_transfers(_transfers_data)
      raise NotImplementedError
    end

    def without_verifier_digit_or_separators(rut)
      rut.split("-")[0].delete('.')
    end

    def verifier_digit(rut)
      rut.split("-")[1]
    end

    def browser
      @browser ||= Pincers.for_webdriver(driver, wait_timeout: 35.0)
    end

    def selenium_browser
      @browser.document
    end

    def driver(width = 1024, heigth = 768)
      chrome_path = ENV.fetch('GOOGLE_CHROME_BIN_PATH', nil)
      return :chrome unless chrome_path

      chrome_opts = {
        "chromeOptions" => {
          "binary" => chrome_path
        }
      }

      opts = {
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts),
        args: ['--no-sandbox', '--browsertime.xvfb']
      }

      d = Selenium::WebDriver.for(:chrome, opts)
      d.manage.window.size = Selenium::WebDriver::Dimension.new(width, heigth)
      d
    end

    def wait(query)
      count = 0
      timeout = browser.config[:wait_timeout]
      interval = browser.config[:wait_interval]
      fulfilled = false
      while !fulfilled && count < timeout
        fulfilled = block_given? ? yield : browser.search(query).any?
        sleep interval
        count += interval
      end
      browser.search(query)
    end

    def goto_frame(query: nil, should_reset: true)
      browser.goto frame: :top if should_reset
      frame = wait(query) if query
      browser.goto(frame: frame)
    end

    def parse_entries(entries)
      deposit_entries = entries.map do |entry|
        BankApi::Values::DepositEntry.new(
          entry[:amount],
          entry[:date],
          entry[:time],
          entry[:rut],
          bank_name,
          entry[:client]
        )
      end
      BankApi::SignDeposits.sign(deposit_entries)
    end
  end
end
