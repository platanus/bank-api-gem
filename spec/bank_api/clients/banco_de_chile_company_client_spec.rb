require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoDeChileCompanyClient do
  let(:txt_file_response) do
    double(
      body: "Fecha; Cta. Origen;Cta. Abono;Nombre Origen;" +
        "Rut Origen;Banco Origen;Monto;Estado\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;BBVA;1000;Aprobada\r\n" +
        "01/01/2018;0001111;00-01;GARY;12.345.678-9;BBVA;2000;Aprobada\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;BBVA;3000;Rechazada\r\n" +
        "01/01/2018;0001111;00-01;PEPE;12.345.678-9;Banco Falabella;4000;Aprobada\r\n"
    )
  end

  let(:params) { double }
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
    allow(subject).to receive(:deposits_params).with("01/01/2018", "07/01/2018").and_return(params)
    allow(subject).to receive(:session_headers).and_return(session_headers)
    allow(subject).to receive(:deposit_range).and_return(start: "01/01/2018", end: "07/01/2018")

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('table#sin_datos').and_return([])
    allow(browser).to receive(:search)
      .with(".textoerror:contains('no podemos atenderle')").and_return(error_div)
    allow(error_div).to receive(:none?).and_return(true)

    allow(RestClient::Request).to receive(:execute).with(
      url: described_class::COMPANY_DEPOSITS_TXT_URL, method: :post, headers: session_headers,
      payload: params, verify_ssl: false
    ).and_return(txt_file_response)

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
    allow(subject).to receive(:select_deposits_range)
    allow(subject).to receive(:submit_deposits_form)
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

    context 'validate_credentials implementation' do
      before do
        mock_get_deposits
      end

      it 'doesn\'t raise NotImplementedError' do
        expect { perform }.not_to raise_error(NotImplementedError)
      end
    end

    context 'get_deposits implementation' do
      before do
        mock_validate_credentials
      end

      it 'doesn\'t raise NotImplementedError' do
        expect { perform }.not_to raise_error(NotImplementedError)
      end
    end

    context 'with no deposits' do
      before do
        mock_validate_credentials
        mock_site_navigation
        allow(browser).to receive(:search).with('table#sin_datos').and_return(['div'])
      end

      it 'returns empty array' do
        expect(perform).to eq([])
      end
    end

    context "with banchile not working" do
      before do
        mock_validate_credentials
        mock_site_navigation
        allow(error_div).to receive(:none?).and_return(false)
      end

      it "raises 'Banchile is down'" do
        expect { perform }.to raise_error("Banchile is down")
      end
    end

    context "with failed deposit fetch" do
      let(:txt_file_response) do
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
          expect(subject).to receive(:download_account_deposits_txt).and_return(
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
end
