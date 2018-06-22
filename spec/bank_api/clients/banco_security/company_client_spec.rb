require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::CompanyClient do
  let(:txt_file) do
    double(
      content: "Fecha|Nombre emisor|RUT emisor|Cuenta origen|Banco origen|Monto|Asunto\n" +
        "01/01/2018 01:15|PEPE|123456789|0000000011111|Banco Falabella|1000|\n" +
        "01/01/2018 05:15|GARY|123456789|0000000011111|Banco Santander|2000|Hello\n" +
        "01/01/2018 07:15|PEPE|123456789|0000000011111|Banco Falabella|3000|\n" +
        "01/01/2018 08:00|PEPE|123456789|0000000011111|Banco Falabella|4000|\n"
    )
  end

  let(:txt_url) { "https://file.txt" }

  let(:div) { double(text: 'text') }

  let(:browser) do
    double(
      config: {
        wait_timeout: 5.0,
        wait_interval: 0.5
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

  before do
    allow(subject).to receive(:browser).and_return(browser)
    allow(subject).to receive(:selenium_browser).and_return(selenium_browser)
    allow(subject).to receive(:deposits_txt_url).and_return(txt_url)

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:download).with(txt_url).and_return(txt_file)

    allow(div).to receive(:click)
    allow(div).to receive(:set)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:count).and_return(1)

    allow(dynamic_card).to receive(:get_coordinate_value).and_return('11')

    allow(selenium_browser).to receive(:execute_script)

    mock_wait_for_deposits_fetch
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
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits)
  end

  def mock_wait_for_deposits_fetch
    allow(subject).to receive(:wait_for_deposits_fetch)
  end

  describe "get_recent_deposits" do
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
            date: Date.parse('01/01/2018'),
            amount: 4000
          }
        ]
      )

      subject.get_recent_deposits
    end

    context 'validate_credentials implementation' do
      before do
        mock_get_deposits
      end

      it "doesn't raise NotImplementedError" do
        expect { subject.get_recent_deposits }.not_to raise_error(NotImplementedError)
      end
    end

    context 'get_deposits implementation' do
      before do
        mock_validate_credentials
      end

      it "doesn't raise NotImplementedError" do
        expect { subject.get_recent_deposits }.not_to raise_error(NotImplementedError)
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

      fit 'returns empty array' do
        expect(subject.get_recent_deposits).to eq([])
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
          allow(subject).to receive(:last_deposit_in_current_page).and_return(50)
        end

        it "raises error" do
          expect { subject.get_recent_deposits }.to raise_error(
            BankApi::Deposit::QuantityError, "Expected 50 deposits," +
              " got 30."
          )
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
  end
end
