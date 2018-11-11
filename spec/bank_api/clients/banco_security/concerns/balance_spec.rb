require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Deposits do
  let(:browser) { double(config: { wait_timeout: 1.0, wait_interval: 0.1 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }
  let(:account_number) { "11" }

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

  def perform
    dummy.find_account_balance(account_number)
  end

  let(:dummy) { DummyClass.new }

  before { allow(dummy).to receive(:browser).and_return(browser) }

  context "with account number" do
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
      allow(browser).to receive(:search).and_return(div)
      allow(browser).to receive(:goto)
    end

    context "with present account_number" do
      it "returns expected balance" do
        expect(perform).to eq(
          account_number: account_number,
          available_balance: 1000,
          countable_balance: 2000
        )
      end
    end

    context "with another account_number" do
      let(:account_number) { "12" }

      it "returns expected balance" do
        expect(perform).to eq(
          account_number: account_number,
          available_balance: 4000,
          countable_balance: 6000
        )
      end
    end

    context "with invalid account_number" do
      let(:account_number) { "1" }

      it "returns expected balance" do
        expect { perform }.to raise_error(
          BankApi::Balance::InvalidAccountNumber,
          "Couldn't find balance of account 1"
        )
      end
    end
  end

  context "without account_number" do
    def mock_account_balance_extraction(td_pos, capital)
      xp = "//*[@id=\"body\"]/div[1]/section/div/div/div[3]/div[2]/table/tbody/tr[1]/td[#{td_pos}]"
      expect(browser).to receive(:search).with(xpath: xp).and_return(double(text: capital))
    end

    let(:account_number) { nil }

    context "with found balance" do
      before do
        mock_account_balance_extraction(1, "$ 194.024.778")
        mock_account_balance_extraction(2, "$ 174.024.666")
      end

      it { expect(perform).to eq(available_balance: 194024778, countable_balance: 174024666) }
    end

    context "with available_balance not found" do
      before do
        mock_account_balance_extraction(1, "")
        mock_account_balance_extraction(2, "$ 174.024.666")
      end

      it { expect { perform }.to raise_error(BankApi::Balance::MissingAccountBalance) }
    end

    context "with countable_balance not found" do
      before do
        mock_account_balance_extraction(1, "$ 194.024.778")
        mock_account_balance_extraction(2, nil)
      end

      it { expect { perform }.to raise_error(BankApi::Balance::MissingAccountBalance) }
    end
  end
end
