require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::CompanyClient do
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
          user_rut: '1.234.567-8',
          password: '',
          company_rut: '8.765.432-1',
          page_size: 50,
          dynamic_card:  dynamic_card
        ),
        days_to_check: 6
      )
    )
  end

  def mock_browser
    allow(subject).to receive(:browser).and_return(browser)
    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
  end

  def mock_selenium_browser
    allow(subject).to receive(:selenium_browser).and_return(selenium_browser)
    allow(selenium_browser).to receive(:execute_script)
  end

  def mock_div
    allow(div).to receive(:click)
    allow(div).to receive(:set)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:count).and_return(1)
  end

  def mock_wait
    allow(subject).to receive(:wait).and_return(div)
  end

  def mock_dynamic_card
    allow(dynamic_card).to receive(:get_coordinate_value).and_return('11')
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

  def mock_site_navigation
    allow(subject).to receive(:login)
    allow(subject).to receive(:goto_company_dashboard)
    allow(subject).to receive(:goto_account_statements)
    allow(subject).to receive(:goto_transfer_form)
    allow(subject).to receive(:submit_transfer_form)
  end

  before do
    mock_browser
    mock_selenium_browser
    mock_div
    mock_wait
    mock_dynamic_card
    allow(subject).to receive(:sleep)
  end

  describe "get_recent_deposits" do
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

    before do
      mock_validate_credentials
      mock_site_navigation
      allow(subject).to receive(:deposits_txt_url).and_return(txt_url)
      allow(browser).to receive(:download).with(txt_url).and_return(txt_file)
      allow(subject).to receive(:wait_for_deposits_fetch)
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
        allow(subject).to receive(:get_deposits)
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

      it 'returns empty array' do
        expect(subject.get_recent_deposits).to eq([])
      end
    end

    describe "#validate_deposits" do
      before do
        mock_validate_credentials
        mock_site_navigation
        allow(subject).to receive(:wait_for_deposits_fetch)
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

    describe "ensure browser.close" do
      before do
        mock_validate_credentials
        mock_site_navigation
        allow(subject).to receive(:any_deposits?).and_return(false)
        expect(browser).to receive(:close)
      end

      context "without error" do
        it "calls browser.close" do
          subject.get_recent_deposits
        end
      end

      context "with error" do
        before do
          allow(subject).to receive(:deposits_from_txt).and_raise(StandardError)
        end

        it "calls browser.close" do
          expect { subject.get_recent_deposits }.to raise_error(StandardError)
        end
      end
    end
  end

  describe "get_statement" do
    let(:account_number) { "000012345678" }
    let(:month) { 1 }
    let(:year) { 2018 }

    before do
      mock_validate_credentials
    end

    describe "credentials validation" do
      before { allow(subject).to receive(:get_statement_of_month).and_return([]) }

      it "validates and returns statement" do
        expect(subject).to receive(:validate_credentials)
        expect(
          subject.get_statement(account_number: account_number, month: month, year: year)
        ).to eq([])
      end

      it "calls get_statement_of_month" do
        expect(subject).to receive(:get_statement_of_month).with(account_number, month, year, nil)

        subject.get_statement(account_number: account_number, month: month, year: year)
      end
    end
  end

  describe "get_statement_of_month" do
    let(:account_number) { "000012345678" }
    let(:company_rut) { "12.345.678-9" }
    let(:month) { 1 }
    let(:year) { 2018 }
    let(:statement) do
      [
        {
          date: Date.new(2018, 1, 2),
          description: "TRANSFERENCIA DESDE BANCO SECURITY DE JUANA PEREZ",
          trx_id: "000000001",
          trx_type: :deposit,
          amount: 1000,
          balance: 1001000
        }, {
          date: Date.new(2018, 1, 3),
          description: "TRANSFERENCIA DESDE BANCO FALABELLA DE JUAN PEREZ",
          trx_id: "000000002",
          trx_type: :charge,
          amount: 2000,
          balance: 999000
        }
      ]
    end

    before do
      mock_validate_credentials
      mock_site_navigation
      allow(subject).to receive(:account_statement_from_txt).and_return(statement)
    end

    it "navigates to statement" do
      expect(subject).to receive(:login)
      expect(subject).to receive(:goto_company_dashboard).with('8.765.432-1')
      expect(subject).to receive(:goto_account_statements)
      subject.get_statement_of_month(account_number, month, year, nil)
    end

    context "with given company_rut" do
      it "navigates to expected company dashboard" do
        expect(subject).to receive(:goto_company_dashboard).with(company_rut)
        subject.get_statement_of_month(account_number, month, year, company_rut)
      end
    end

    describe "ensure browser.close" do
      before do
        expect(browser).to receive(:close)
      end

      context "without error" do
        it "calls browser.close" do
          subject.get_statement_of_month(account_number, month, year, nil)
        end
      end

      context "with error" do
        before do
          allow(subject).to receive(:account_statement_from_txt).and_raise(StandardError)
        end

        it "calls browser.close" do
          expect do
            subject.get_statement_of_month(account_number, month, year, nil)
          end.to raise_error(StandardError)
        end
      end
    end
  end

  describe "get_company_statement" do
    let(:account_number) { "000012345678" }
    let(:company_rut) { "12.345.678-9" }
    let(:month) { 1 }
    let(:year) { 2018 }

    it "calls get_statement" do
      expect(subject).to receive(:get_statement).with(
        account_number: account_number, month: month, year: year, company_rut: company_rut
      )

      subject.get_company_statement(
        account_number: account_number, month: month, year: year, company_rut: company_rut
      )
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
        expect(subject).to receive(:goto_company_dashboard).with('8.765.432-1')

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
        expect(subject).to receive(:goto_company_dashboard).with('8.765.432-1').exactly(2).times

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
end
