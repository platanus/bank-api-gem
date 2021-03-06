require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoDeChileCompanyClient do
  let(:deposit_txt_file_response) do
    double(
      body: "Fecha; Cta. Origen;Cta. Abono;Nombre Origen;" +
        "Rut Origen;Banco Origen;Monto;Estado\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;BBVA;1000;Aprobada\r\n" +
        "01/01/2018;0001111;00-01;GARY;12.345.678-9;BBVA;2000;Aprobada\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;BBVA;3000;Rechazada\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;Banco Falabella;4000;Aprobada\r\n"
    )
  end

  let(:withdrawal_txt_file_response) do
    double(
      body:
      "ABC01234567841234567891230123456789Oscar                         0000000123456789120" +
      "97053000200000001000 ABCDEFGHIJKLMNO               1ABCDEFGHIJKLMNO                " +
      "oscar@fintual.com                                 CTD\r\n" +
      "ABC01234567841234567891230987654321Boris                         0000000987654321980" +
      "97053000200000002000 ABCDEFGHIJKLMNO               1ABCDEFGHIJKLMNO                " +
      "boris@fintual.com                                 CTD\r\n"
    )
  end

  let(:session_headers) { double }

  let(:div) { double }
  let(:error_div) { double }

  let(:browser) { double }

  let (:subject) do
    described_class.new(
      double(
        bdc_company_rut: '',
        bdc_user_rut: '',
        bdc_password: '',
        bdc_account: '',
        days_to_check: 6
      )
    )
  end

  before do
    allow(subject).to receive(:browser).and_return(browser)
    allow(subject).to receive(:session_headers).and_return(session_headers)
    allow(subject).to receive(:deposit_range).and_return(start: "01/01/2018", end: "07/01/2018")

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search)
      .with(".textoerror:contains('no podemos atenderle')").and_return(error_div)
    allow(error_div).to receive(:none?).and_return(true)

    allow(RestClient::Request).to receive(:execute).and_return(deposit_txt_file_response)

    allow(div).to receive(:click)
    allow(div).to receive(:set)
  end

  def mock_validate_credentials
    allow(subject).to receive(:validate_credentials)
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits)
  end

  def mock_site_navigation
    allow(subject).to receive(:login)
    allow(subject).to receive(:goto_deposits)
    allow(subject).to receive(:goto_withdrawals)
    allow(subject).to receive(:select_deposits_range)
    allow(subject).to receive(:select_withdrawals_range)
  end

  def mock_get_balance_navigation
    allow(subject).to receive(:login)
    allow(subject).to receive(:goto_balance)
    allow(subject).to receive(:select_account).with(options[:account_number])
    allow(subject).to receive(:click_fetch_balance_button)
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
      expect(subject.send(:get_deposits)).to eq(
        [
          {
            client: "PEPE",
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            time: nil,
            amount: 1000
          },
          {
            client: "GARY",
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            time: nil,
            amount: 2000
          },
          {
            client: "PEPE",
            rut: '12.345.678-9',
            time: nil,
            date: Date.parse('01/01/2018'),
            amount: 4000
          }
        ]
      )

      perform
    end

    context "with navigation error" do
      before do
        allow(subject).to receive(:goto_deposits).and_raise StandardError, "timeout"
      end

      it "closes the browser" do
        expect(browser).to receive(:close)

        expect { perform }.to raise_error
      end
    end

    context 'with no deposits' do
      let(:deposit_txt_file_response) do
        double(
          body: "Fecha; Cta. Origen;Cta. Abono;Nombre Origen;" +
            "Rut Origen;Banco Origen;Monto;Estado\r\n"
        )
      end

      before do
        mock_validate_credentials
        mock_site_navigation
      end

      it 'returns empty array' do
        expect(perform).to eq([])
      end
    end

    context "with failed deposit fetch" do
      let(:deposit_txt_file_response) do
        double(body: "no podemos atenderle")
      end

      before do
        mock_validate_credentials
        mock_site_navigation
        allow(error_div).to receive(:none?).and_return(false)
      end

      it "raises 'Banchile is down'" do
        expect { perform }.to raise_error("Banchile is down")
      end
    end

    context 'with account_details source' do
      let(:options) do
        {
          source: :account_details
        }
      end

      context "with valid config" do
        before do
          expect(subject).to receive(:account_deposits_from_txt).and_return(
            [
              {
                client: "Leandro",
                rut: nil,
                date: Date.parse('01/01/2018'),
                amount: 1000,
                time: nil
              }
            ]
          )
        end

        it "returns valid entries" do
          deposit = perform.first[:deposit_entry]
          expect(deposit).to be_a(BankApi::Values::DepositEntry)
        end
      end
    end
  end

  describe "#get_recent_withdrawals" do
    let(:perform) { subject.get_recent_withdrawals }

    before do
      mock_validate_credentials
      mock_site_navigation
      allow(RestClient::Request).to receive(:execute).and_return(withdrawal_txt_file_response)
    end

    it 'validates and returns entries on get_recent_deposits' do
      expect(subject).to receive(:validate_credentials)
      expect(subject.send(:get_withdrawals)).to eq(
        [
          {
            client: "Oscar",
            rut: '12.345.678-9',
            account_number: "000000012345678912",
            amount: 1000,
            email: "oscar@fintual.com"
          },
          {
            client: "Boris",
            rut: '98.765.432-1',
            account_number: "000000098765432198",
            amount: 2000,
            email: "boris@fintual.com"
          }
        ]
      )

      perform
    end

    context "with navigation error" do
      before do
        allow(subject).to receive(:goto_withdrawals).and_raise StandardError, "timeout"
      end

      it "closes the browser" do
        expect(browser).to receive(:close)

        expect { perform }.to raise_error
      end
    end

    context 'with no deposits' do
      let(:withdrawal_txt_file_response) do
        double(
          body: ""
        )
      end

      before do
        mock_validate_credentials
        mock_site_navigation
      end

      it 'returns empty array' do
        expect(perform).to eq([])
      end
    end

    context "with failed deposit fetch" do
      let(:withdrawal_txt_file_response) do
        double(body: "no podemos atenderle")
      end

      before do
        mock_validate_credentials
        mock_site_navigation
        allow(error_div).to receive(:none?).and_return(false)
      end

      it "raises 'Banchile is down'" do
        expect { perform }.to raise_error("Banchile is down")
      end
    end
  end

  describe 'get_balance' do
    let(:search_countable) { double }
    let(:search_available) { double }
    let(:options) do
      {
        account_number: 123456789
      }
    end

    before do
      mock_validate_credentials
      mock_get_balance_navigation
      allow(browser).to receive(:search)
        .with('table.detalleSaldosMov tr:nth-child(2) > td.aRight.bold')
        .and_return(search_available)
      allow(browser).to receive(:search)
        .with('table.detalleSaldosMov tr:first-child > td.aRight.bold')
        .and_return(search_countable)
      allow(search_available).to receive(:text).and_return('$ 445.070')
      allow(search_countable).to receive(:text).and_return('$ 400.070')
    end

    it 'returns the balance hash' do
      expect(subject).to receive(:validate_credentials)
      res = subject.get_account_balance(options)
      expect(res.keys).to include(:account_number, :available_balance, :countable_balance)
      expect(res[:available_balance]).to eq(445070)
      expect(res[:countable_balance]).to eq(400070)
      expect(res[:account_number]).to eq(options[:account_number])
    end

    context "with navigation error" do
      before do
        allow(subject).to receive(:goto_deposits).and_raise StandardError, "timeout"
      end

      it "closes the browser" do
        expect(browser).to receive(:close)

        expect { subject.get_recent_deposits }.to raise_error
      end
    end
  end

  context 'validate_credentials implementation' do
    before do
      mock_get_deposits
    end

    it 'doesn\'t raise NotImplementedError' do
      expect { subject.get_recent_deposits }.not_to raise_error(NotImplementedError)
    end
  end

  context 'get_deposits implementation' do
    before do
      mock_validate_credentials
    end

    it 'doesn\'t raise NotImplementedError' do
      expect { subject.get_recent_deposits }.not_to raise_error(NotImplementedError)
    end
  end
end
