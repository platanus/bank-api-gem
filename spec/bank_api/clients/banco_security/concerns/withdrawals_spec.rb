require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Withdrawals do
  let(:browser) { double(config: { wait_timeout: 0.5, wait_interval: 0.1 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Withdrawals

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
      @page_size = 30
    end
  end

  let(:dummy) { DummyClass.new }

  let(:json_response) do
    double(
      body: {
        "Items" => [
          {
            "NumeroTransaccion" => 123456789,
            "Fecha" => "/Date(1541948400000)/",
            "RutDestino" => "123456789",
            "BancoDestino" => "Banco Security",
            "CuentaDestino" => "12345",
            "MailDestino" => "oscar@fintual.com",
            "NombreDestino" => "Óscar Estay",
            "Monto" => 1_000
          }
        ]
      }.to_json
    )
  end

  let(:page_info) { double(text: "1 - 4 de 4", any?: true) }

  def mock_wait_for_withdrawals_fetch
    allow(dummy).to receive(:wait_for_withdrawals_fetch)
  end

  def mock_json_fetch
    allow(RestClient::Request).to receive(:execute).and_return(json_response)
    allow(dummy).to receive(:deposit_range).and_return({})
    allow(dummy).to receive(:session_headers)
    allow(dummy).to receive(:withdrawals_payload)
  end

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:browser).and_return(browser)
    allow(dummy).to receive(:any_withdrawals?).and_return(true)
    allow(dummy).to receive(:fill_withdrawal_date_inputs).and_return(true)
    allow(dummy).to receive(:setup_authentication).and_return(true)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('.k-pager-info').and_return(page_info)
    allow(browser).to receive(:goto)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:none?).and_return(true)
    allow(div).to receive(:count).and_return(1)
    allow(div).to receive(:click)
    allow(div).to receive(:set)

    mock_wait_for_withdrawals_fetch
    mock_json_fetch
  end

  it "implements select_withdrawals_range" do
    expect { dummy.select_withdrawals_range }.not_to raise_error
  end

  it "implements withdrawals_from_json" do
    expect { dummy.withdrawals_from_json }.not_to raise_error
  end

  context "with withdrawals" do
    it "returns withdrawals" do
      expect(dummy.withdrawals_from_json).to eq(
        [
          {
            client: "Óscar Estay",
            account_bank: "Banco Security",
            account_number: "12345",
            rut: "12.345.678-9",
            email: "oscar@fintual.com",
            date: Date.new(2018, 11, 11),
            time: Time.new(2018, 11, 11, 12),
            amount: 1_000,
            trx_id: 123456789
          }
        ]
      )
    end
  end
end
