require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Deposits do
  let(:browser) { double(config: { wait_timeout: 1.0, wait_interval: 0.1 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Balance

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
      @page_size = 30
    end
  end

  let(:dummy) { DummyClass.new }

  let(:first_row) { double }
  let(:second_row) { double }
  let(:table) { [first_row, second_row] }

  def mock_table
    allow(div).to receive(:search).with('tbody tr').and_return(table)
    allow(first_row).to receive(:search).with("td").and_return(
      [double(text: "11"), double(text: "$ 1.000"), double(text: "$ 2.000")]
    )
    allow(second_row).to receive(:search).with("td").and_return(
      [double(text: "12"), double(text: "$ 4.000"), double(text: "$ 6.000")]
    )
  end

  before do
    mock_table
    allow(dummy).to receive(:browser).and_return(browser)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:goto)
  end

  context "with present account_number" do
    it "returns expected balance" do
      expect(dummy.find_account_balance("11")).to eq(
        account_number: "11",
        available_balance: 1000,
        countable_balance: 2000
      )

      expect(dummy.find_account_balance("12")).to eq(
        account_number: "12",
        available_balance: 4000,
        countable_balance: 6000
      )
    end
  end

  context "without present account_number" do
    it "returns expected balance" do
      expect { dummy.find_account_balance("1") }.to raise_error(
        BankApi::Balance::InvalidAccountNumber,
        "Couldn't find balance of account 1"
      )
    end
  end
end
