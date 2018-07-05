require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::PendingTransfers, client: true do
  let(:browser) { double(config: { wait_timeout: 0.5, wait_interval: 0.1 }) }
  let(:selenium_browser) { double }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::PendingTransfers

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
    end
  end

  let(:dummy) { DummyClass.new }
  let(:transfer_data) { { rut: '32.165.498-7' } }

  def text(_text)
    double(text: _text)
  end

  def mock_table(table)
    table_div = double
    table_rows = table.map { |_x| double }
    allow(table_div).to receive(:search).with("tr").and_return(table_rows)
    allow(table_div).to receive(:search).with("td").and_return(table.flatten)
    table.zip(table_rows).each do |row, tr|
      allow(tr).to receive(:search).with("td").and_return(row)
    end
    table_div
  end

  def mock_pending_trasfers_table
    allow(pending_transfers_table_div).to receive(:search).with("tr")
                                                          .and_return(pending_transfers_table)
  end

  def mock_dynamic_card
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dynamic_card).to receive(:get_coordinate_value).and_return('11')
  end

  def mock_browser
    allow(dummy).to receive(:browser).and_return(browser)
    allow(dummy).to receive(:selenium_browser).and_return(selenium_browser)
    allow(selenium_browser).to receive(:execute_script)

    allow(browser).to receive_messages(goto: nil, search: div)
    allow(div).to receive_messages(click: nil, set: nil)
  end

  def mock_wait_for_transfer_details
    allow(dummy).to receive(:wait).with("span:contains('Monto a Transferir')")
  end

  before do
    mock_browser
    mock_dynamic_card
    mock_wait_for_transfer_details
  end

  describe "find_pending_transfer" do
    let(:trx_id) { "13131313" }
    let(:check) { double(text: "") }
    let(:pending_transfers_table_div) { double }
    let(:table_rows) { pending_transfers_table.map { |_x| double } }
    let(:pending_transfers_table) do
      [
        [text(""), text("trx_id"), text("date"), text("origin"), text("account"), text("amount")],
        [text(""), text("1"), text("01/01/2018 18:26"), text("1111"), text("2222"), text("10000")],
        [text(""), text("2"), text("01/01/2018 18:26"), text("1111"), text("2222"), text("20000")],
        [text(""), text("3"), text("01/01/2018 18:26"), text("1111"), text("2222"), text("30000")],
        [check, text(trx_id), text("01/01/2018 18:26"), text("3333"), text("2222"), text("1000")],
        [text(""), text("4"), text("01/01/2018 18:26"), text("1111"), text("2222"), text("40000")]
      ]
    end
    let(:expected_transfer) do
      {
        trx_id: "13131313", datetime: "01/01/2018 18:26", origin: "3333",
        account: "2222", amount: 1000, input: check
      }
    end

    before do
      allow(browser).to receive(:search)
        .with(".Marco table").and_return(
          ["No tiene operaciones pendientes", pending_transfers_table_div]
        )
      allow(pending_transfers_table_div).to receive(:search).with("tr").and_return(table_rows)
      pending_transfers_table.each do |row|
        allow(row[0]).to receive(:search).with("input").and_return(row[0])
      end
      pending_transfers_table.zip(table_rows).each do |row, tr|
        allow(tr).to receive(:search).with("td").and_return(row)
      end
      pending_transfers_table.each do |row|
        allow(row[0]).to receive(:search).with("input").and_return(row[0])
      end
    end

    it "returns the expected transfer" do
      expect(dummy.find_pending_transfer(trx_id)).to eq(expected_transfer)
    end

    context "without transaction" do
      it "returns the expected transfer" do
        expect(dummy.find_pending_transfer("141414")).to be nil
      end
    end
  end

  describe "validate_pending_transfer_data" do
    let(:check) { double }
    let(:transfer_data) do
      { rut: "12345678-9", account: "131313", origin: "1234567", amount: 1000 }
    end
    let(:origin_table) do
      [
        [text("1234567")],
        [text("$ 1.000")],
        [text("$ 0")],
        [text("$ 1.000")],
        [text("$ 999.999.999")]
      ]
    end
    let(:transfer_details_table) do
      [
        [text("131313")],
        [text("Banco Falabella")],
        [text("Cuenta Corriente")],
        [text("Dres")],
        [text("12.345.678-9")],
        [text("r2d2@fintual.cl")],
        [text("Coment")],
        [text("$ 1000")]
      ]
    end

    before do
      allow(browser).to receive(:search)
        .with(".Marco table").and_return(
          [mock_table(origin_table), mock_table(transfer_details_table)]
        )
    end

    it { expect { dummy.validate_pending_transfer_data(transfer_data) }.not_to raise_error }

    context "with different rut" do
      let(:transfer_data) { { rut: "12345678-0" } }

      it "raises error" do
        expect { dummy.validate_pending_transfer_data(transfer_data) }.to raise_error(
          BankApi::Transfer::InvalidAccountData,
          "12345678-0 doesn't match transfer's rut 12.345.678-9"
        )
      end
    end

    context "with different account" do
      let(:transfer_data) { { account: "141414" } }

      it "raises error" do
        expect { dummy.validate_pending_transfer_data(transfer_data) }.to raise_error(
          BankApi::Transfer::InvalidAccountData,
          "141414 doesn't match transfer's account 131313"
        )
      end
    end

    context "with different origin" do
      let(:transfer_data) { { origin: "7654321" } }

      it "raises error" do
        expect { dummy.validate_pending_transfer_data(transfer_data) }.to raise_error(
          BankApi::Transfer::InvalidAccountData,
          "7654321 doesn't match transfer's origin 1234567"
        )
      end
    end

    context "with different amount" do
      let(:transfer_data) { { amount: 2000 } }

      it "raises error" do
        expect { dummy.validate_pending_transfer_data(transfer_data) }.to raise_error(
          BankApi::Transfer::InvalidAmount,
          "2000 doesn't match transfer's amount 1000"
        )
      end
    end
  end

  describe "fill_pending_transfer_coordinates" do
    let(:coordinates_table) { double }
    let(:coordinates_texts) { ["A1", "B2", "C3"].map { |x| text(x) } }
    let(:coordinates_inputs) { coordinates_texts.map { double } }

    before do
      allow(browser).to receive(:search).with(".Marco table").and_return(
        ["Origin details", "Tranfer details", coordinates_table]
      )
      allow(coordinates_table).to receive(:search).with("td span").and_return(coordinates_texts)
      allow(coordinates_table).to receive(:search).with("td input").and_return(coordinates_inputs)
    end

    it "fills coordinates inputs" do
      coordinates_inputs.each { |i| expect(i).to receive(:set).with("11") }
      dummy.fill_pending_transfer_coordinates
    end
  end
end
