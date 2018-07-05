require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Transfers, client: true do
  let(:browser) { double(config: { wait_timeout: 5.0, wait_interval: 0.2 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Transfers

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
    end
  end

  let(:dummy) { DummyClass.new }
  let(:transfer_data) do
    {
      amount: 10000,
      name: 'John Doe',
      rut: '32.165.498-7',
      account_number: '11111111',
      bank: :banco_estado,
      account_type: :cuenta_corriente,
      email: 'doe@platan.us',
      comment: 'Comment'
    }
  end
  let(:dummy) { DummyClass.new }

  let(:transfers_data) { [transfer_data] }

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:browser).and_return(browser)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:goto)
    allow(div).to receive(:click)
    allow(div).to receive(:set)

    allow(dynamic_card).to receive(:get_coordinate_value).and_return('11')
  end

  it "implements submit_transfer_form" do
    expect { dummy.submit_transfer_form(transfer_data) }.not_to raise_error
  end

  it "implements fill_transfer_coordinates" do
    expect { dummy.fill_transfer_coordinates }.not_to raise_error
  end

  describe "validations" do
    context "with valid data" do
      it "doesn't raise error" do
        expect { dummy.validate_transfer_missing_data(transfer_data) }.not_to raise_error
        expect { dummy.validate_transfer_valid_data(transfer_data) }.not_to raise_error
      end
    end

    context "with invalid data" do
      context "with missing origin" do
        before { dummy.instance_variable_set(:@company_rut, nil) }
        after { dummy.instance_variable_set(:@company_rut, '98.765.432-1') }

        it "raises BankApi::Transfer::MissingTransferData" do
          expect { dummy.validate_transfer_missing_data(transfer_data) }.to raise_error(
            BankApi::Transfer::MissingTransferData
          )
        end
      end

      context "with missing transfer_data" do
        let(:transfer_data) { { amount: 10000 } }

        it "raises BankApi::Transfer::MissingTransferData" do
          expect { dummy.validate_transfer_missing_data(transfer_data) }.to raise_error(
            BankApi::Transfer::MissingTransferData
          )
        end
      end

      context "with invalid bank" do
        let(:transfer_data) { { bank: :invalid_bank } }

        it "raises BankApi::Transfer::InvalidBank" do
          expect { dummy.validate_transfer_valid_data(transfer_data) }.to raise_error(
            BankApi::Transfer::InvalidBank
          )
        end
      end

      context "with invalid account type" do
        let(:transfer_data) { { bank: :banco_estado, account_type: :invalid_account_type } }

        it "raises BankApi::Transfer::InvalidAccountType" do
          expect { dummy.validate_transfer_valid_data(transfer_data) }.to raise_error(
            BankApi::Transfer::InvalidAccountType
          )
        end
      end
    end
  end

  it 'fills the form with the transfer data' do
    expect_to_set(browser, query: ".active #destinatario-nombre", value: "John Doe")
    expect_to_set(browser, query: ".active #destinatario-rut", value: "32.165.498-7")
    expect_to_set(browser, query: ".active #destinatario-cuenta", value: "11111111")
    expect_to_set(browser, query: ".active #destinatario-banco", value: "Banco Estado")
    expect_to_set(browser, query: ".active #Monto", value: 10000)
    expect_to_set(browser, query: ".active #Email", value: "doe@platan.us")
    expect_to_set(browser, query: ".active #Comentario", value: "Comment")
    expect_to_set(
      browser,
      query: ".active [name=\"tipo-cuenta\"][data-nombre=\"Cuenta Corriente\"]"
    )

    dummy.submit_transfer_form(transfer_data)
  end

  it "fills coordinates" do
    expect(div).to receive(:set).with('11').exactly(3).times

    dummy.fill_transfer_coordinates
  end
end
