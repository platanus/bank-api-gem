require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::CompanyClient do
  let(:txt_file) do
    double(
      content: "Fecha|Nombre emisor|RUT emisor|Cuenta origen|Banco origen|Monto|Asunto\n" +
        "01/01/2018 01:15|PEPE|123456789|0000000011111|Banco Falabella|1000|\n" +
        "01/01/2018 05:15|GARY|123456789|0000000011111|Banco Santander|2000|Hello\n" +
        "01/01/2018 07:15|PEPE|123456789|0000000011111|Banco Falabella|3000|\n" +
        "01/01/2018 21:00|PEPE|123456789|0000000011111|Banco Falabella|4000|\n"
    )
  end

  let(:txt_url) { "https://file.txt" }

  let(:div) { double(text: 'text') }
  let(:element) { double }

  let(:browser) do
    double(
      config: {
        wait_timeout: 1.0,
        wait_interval: 0.1
      }
    )
  end

  let(:selenium_browser) { double }

  let(:dynamic_card) { double }

  let (:subject) do
    described_class.new(
      double(
        banco_security: double(
          user_rut: '',
          password: '',
          company_rut: '',
          page_size: 50,
          dynamic_card:  dynamic_card
        ),
        days_to_check: 6
      )
    )
  end

  let(:first_row) { double }
  let(:second_row) { double }
  let(:table) { [first_row, second_row] }
  let(:deposits) { [] }

  before do
    allow(subject).to receive(:browser).and_return(browser)
    allow(subject).to receive(:selenium_browser).and_return(selenium_browser)
    allow(subject).to receive(:deposits_txt_url).and_return(txt_url)

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
    allow(div).to receive(:elements).and_return([element])
    allow(element).to receive(:send_key)
    allow(browser).to receive(:download).with(txt_url).and_return(txt_file)

    allow(div).to receive(:click)
    allow(div).to receive(:set)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:count).and_return(1)

    allow(dynamic_card).to receive(:get_coordinate_value).and_return('11')

    allow(selenium_browser).to receive(:execute_script)

    mock_wait_for_deposits_fetch
    mock_table
  end

  def mock_table
    allow(div).to receive(:search).with('tbody tr').and_return(table)
    allow(first_row).to receive(:search).with("td").and_return(
      [double(text: "11"), double(text: "$ 1.000"), double(text: "$ 2.000")]
    )
    allow(second_row).to receive(:search).with("td").and_return(
      [double(text: "12"), double(text: "$ 4.000"), double(text: "$ 6.000")]
    )
  end

  def mock_validate_credentials
    allow(subject).to receive(:validate_credentials)
  end

  def mock_validate_transfer_missing_data
    allow(subject).to receive(:validate_transfer_missing_data)
  end

  def mock_validate_transfer_valid_data
    allow(subject).to receive(:validate_transfer_valid_data)
  end

  def mock_validate_deposits
    allow(subject).to receive(:validate_deposits)
  end

  def mock_execute_transfer
    allow(subject).to receive(:execute_transfer)
  end

  def mock_site_navigation
    allow(subject).to receive(:login)
    allow(subject).to receive(:goto_company_dashboard)
    allow(subject).to receive(:goto_transfer_form)
    allow(subject).to receive(:submit_transfer_form)
    allow(subject).to receive(:goto_balance)
    allow(subject).to receive(:goto_account_details)
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits)
  end

  def mock_wait_for_deposits_fetch
    allow(subject).to receive(:wait_for_deposits_fetch)
  end

  describe "get_recent_deposits" do
    let(:options) { {} }
    let(:perform) { subject.get_recent_deposits(options) }

    before do
      mock_validate_credentials
      mock_site_navigation
    end

    it 'validates and returns entries on get_recent_deposits' do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:get_deposits).and_return(
        [
          {
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            amount: 1000
          },
          {
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            amount: 2000
          },
          {
            rut: '12.345.678-9',
            date: Date.parse('02/01/2018'),
            amount: 4000
          }
        ]
      )

      perform
    end

    context 'with account_details source' do
      let(:account_number) { "666" }
      let(:options) do
        {
          source: :account_details,
          account_number: account_number
        }
      end

      context "with valid config" do
        before do
          expect(subject).to receive(:deposits_from_account_details).and_return(
            [
              {
                client: "Leandro",
                rut: nil,
                date: Date.parse('01/01/2018'),
                amount: 1000
              }
            ]
          )
        end

        it "returns valid entries" do
          deposit = perform.first[:deposit_entry]
          expect(deposit).to be_a(BankApi::Values::DepositEntry)
        end
      end

      context "with missing account number" do
        let(:account_number) { nil }

        it { expect { perform }.to raise_error("missing :account_number option") }
      end
    end

    context 'validate_credentials implementation' do
      before do
        mock_get_deposits
      end

      it "doesn't raise NotImplementedError" do
        expect { perform }.not_to raise_error(NotImplementedError)
      end
    end

    context 'get_deposits implementation' do
      before do
        mock_validate_credentials
      end

      it "doesn't raise NotImplementedError" do
        expect { perform }.not_to raise_error(NotImplementedError)
      end
    end

    context 'with no deposits' do
      let(:txt_file) do
        double(
          content: "Fecha|Nombre emisor|RUT emisor|Cuenta origen|Banco origen|Monto|Asunto"
        )
      end

      before do
        mock_validate_credentials
        mock_site_navigation
        allow(subject).to receive(:any_deposits?).and_return(false)
      end

      it 'returns empty array' do
        expect { perform }.to raise_error(
          BankApi::Deposit::FetchError, "Couldn't fetch deposits"
        )
      end
    end

    describe "#validate_deposits" do
      before do
        mock_validate_credentials
        mock_site_navigation
        mock_wait_for_deposits_fetch
        allow(subject).to receive(:any_deposits?).and_return(true)
      end

      context "with less deposits" do
        let(:deposits) { [{}] * 30 }

        before do
          allow(subject).to receive(:deposits_from_txt).and_return(deposits)
          allow(subject).to receive(:total_deposits).and_return(50)
        end

        it "raises error" do
          expect { perform }.to raise_error(
            BankApi::Deposit::QuantityError, "Expected 50 deposits," +
              " got 30."
          )
        end
      end
    end

    describe "ensure browser.close" do
      before do
        mock_validate_credentials
        mock_site_navigation
        allow(subject).to receive(:deposits_from_txt).and_return(deposits)
        allow(subject).to receive(:total_deposits).and_return(50)
        allow(subject).to receive(:any_deposits?).and_return(true)
        expect(browser).to receive(:close)
      end

      context "without error" do
        it "calls browser.close" do
          perform
        end
      end

      context "with error" do
        before do
          allow(subject).to receive(:deposits_from_txt).and_raise(StandardError)
        end

        it "calls browser.close" do
          expect { perform }.to raise_error(StandardError)
        end
      end
    end
  end

  describe "#transfer" do
    let(:transfer_data) do
      {
        amount: 10000,
        name: "John Doe",
        rut: "32.165.498-7",
        account_number: "11111111",
        bank: :banco_estado,
        account_type: :cuenta_corriente,
        email: "doe@platan.us",
        comment: "Comment"
      }
    end

    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
      mock_site_navigation
    end

    it "validates and returns calls executer_transfer" do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:validate_transfer_missing_data).with(transfer_data)
      expect(subject).to receive(:validate_transfer_valid_data).with(transfer_data)
      expect(subject).to receive(:execute_transfer).with(transfer_data)

      subject.transfer(transfer_data)
    end

    context "with origin in transfer_data" do
      it "prioritizes transfer's origin over @company_rut" do
        expect(subject).to receive(:goto_company_dashboard).with('54.987.123-6')

        subject.transfer(transfer_data.merge(origin: '54.987.123-6'))
      end
    end

    context "without origin in transfer_data" do
      it "goes to @company_rut's dashboard" do
        expect(subject).to receive(:goto_company_dashboard).with('')

        subject.transfer(transfer_data)
      end
    end

    it "calls submit_transfer_form with transfer_data" do
      expect(subject).to receive(:submit_transfer_form).with(transfer_data)

      subject.transfer(transfer_data)
    end

    it "calls fill_coordinates" do
      expect(subject).to receive(:fill_coordinates)

      subject.transfer(transfer_data)
    end

    describe "ensure browser.close" do
      before do
        expect(browser).to receive(:close)
      end

      context "without error" do
        before do
          expect(subject).to receive(:fill_coordinates)
        end

        it "calls browser.close" do
          subject.transfer(transfer_data)
        end
      end

      context "with error" do
        before do
          allow(subject).to receive(:submit_transfer_form).and_raise(StandardError)
        end

        it "calls browser.close" do
          expect { subject.transfer(transfer_data) }.to raise_error(StandardError)
        end
      end
    end
  end

  describe "#batch_transfers" do
    let(:transfers_data) do
      [
        {
          amount: 10000,
          name: "John Doe",
          rut: "32.165.498-7",
          account_number: "11111111",
          bank: :banco_estado,
          account_type: :cuenta_corriente,
          email: "doe@platan.us",
          comment: "Comment"
        },
        {
          amount: 20000,
          name: "John Does",
          rut: "54.123.789-6",
          account_number: "11111111",
          bank: :banco_estado,
          account_type: :cuenta_vista,
          email: "does@platan.us",
          comment: "Comment"
        }
      ]
    end

    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
      mock_site_navigation
    end

    it "validates and returns calls executer_transfer" do
      expect(subject).to receive(:validate_credentials)
      transfers_data.each do |transfer_data|
        expect(subject).to receive(:validate_transfer_missing_data).with(transfer_data)
        expect(subject).to receive(:validate_transfer_valid_data).with(transfer_data)
      end
      expect(subject).to receive(:execute_batch_transfers).with(transfers_data)

      subject.batch_transfers(transfers_data)
    end

    context "with origin in transfer_data" do
      it "prioritizes transfer's origin over @company_rut" do
        expect(subject).to receive(:goto_company_dashboard).with('54.987.123-6').exactly(2).times

        subject.batch_transfers(
          transfers_data.map { |transfer_data| transfer_data.merge(origin: '54.987.123-6') }
        )
      end
    end

    context "without origin in transfer_data" do
      it "goes to @company_rut's dashboard" do
        expect(subject).to receive(:goto_company_dashboard).with('').exactly(2).times

        subject.batch_transfers(transfers_data)
      end
    end

    it "calls submit_transfer_form with transfer_data" do
      transfers_data.each do |transfer_data|
        expect(subject).to receive(:submit_transfer_form).with(transfer_data)
      end

      subject.batch_transfers(transfers_data)
    end

    it "calls fill_coordinates" do
      expect(subject).to receive(:fill_coordinates).exactly(2).times

      subject.batch_transfers(transfers_data)
    end

    describe "ensure browser.close" do
      before do
        expect(browser).to receive(:close)
      end

      context "without error" do
        before do
          expect(subject).to receive(:fill_coordinates).exactly(2).times
        end

        it "calls browser.close" do
          subject.batch_transfers(transfers_data)
        end
      end

      context "with error" do
        before do
          allow(subject).to receive(:submit_transfer_form).and_raise(StandardError)
        end

        it "calls browser.close" do
          expect { subject.batch_transfers(transfers_data) }.to raise_error(StandardError)
        end
      end
    end
  end

  describe "account_balance" do
    context "with present account_number" do
      it "returns expected balance" do
        expect(subject.find_account_balance("11")).to eq(
          account_number: "11",
          available_balance: 1000,
          countable_balance: 2000
        )

        expect(subject.find_account_balance("12")).to eq(
          account_number: "12",
          available_balance: 4000,
          countable_balance: 6000
        )
      end
    end

    context "without present account_number" do
      it "returns expected balance" do
        expect { subject.find_account_balance("1") }.to raise_error(
          BankApi::Balance::InvalidAccountNumber,
          "Couldn't find balance of account 1"
        )
      end
    end
  end
end
