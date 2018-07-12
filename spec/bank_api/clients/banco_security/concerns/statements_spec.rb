require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Statements do
  let(:browser) { double(config: { wait_timeout: 0.5, wait_interval: 0.1 }) }
  let(:selenium_browser) { double }
  let(:div) { double(text: 'text', none?: true) }
  let(:input) { double }
  let(:dynamic_card) { double }
  let(:account_number) { "000012345678" }
  let(:month) { 1 }
  let(:year) { 2018 }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Statements
    include BankApi::Clients::Navigation

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
      @page_size = 30
    end
  end

  let(:dummy) { DummyClass.new }

  let(:download_link) { double }

  def mock_browser
    allow(dummy).to receive(:browser).and_return(browser)
    allow(dummy).to receive(:goto)
    allow(dummy).to receive(:goto_frame)
    allow(browser).to receive(:search).and_return(div)
  end

  def mock_div
    allow(download_link).to receive(:download).and_return(txt_file)
    allow(input).to receive(:set)
    allow(div).to receive(:none?).and_return(true)
    allow(div).to receive(:click)
    allow(div).to receive(:set)
  end

  def mock_selenium_browser
    allow(dummy).to receive(:selenium_browser).and_return(selenium_browser)
    allow(selenium_browser).to receive(:execute_script)
  end

  def mock_wait
    allow(dummy).to receive(:wait).and_return(div)
  end

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:statement_available?).and_return(true)
    mock_browser
    mock_selenium_browser
    mock_div
    mock_wait
  end

  describe "current_statement" do
    let(:txt_file) do
      double(
        content: "" +
          "Nombre;Dirección;Comuna;...\r\n" +
          "FINTUAL ADMINISTRADORA GENERAL DE FONDOS S A...\r\n" +
          "Fecha;Descripción;N de documento;Cargos;Abonos;Saldo\r\n" +
          "01/01;Transferencia  ; 0000000001;0.00;500,000.00;10,000,000.00\r\n" +
          "02/01;Transferencia  ; 0000000002;500,000.00;0.00;9,500,000.00\r\n" +
          "01/01;SALDO INICIAL;;0.00;0.00;10,000,000.00\r\n" +
          "Resumen del período\r\n" +
          "Saldo inicial;Total cargos;Total abonos;Saldo final\r\n" +
          "10,000,000.00;10,000,000.00;10,000,000.00;10,000,000.00\r\n" +
          "Cheques pagados\r\n" +
          " \r\n" +
          "Cheques devueltos\r\n" +
          " \r\n"
      )
    end

    before do
      allow(browser).to receive(:search)
        .with("a:contains('Descargar TXT')").and_return(download_link)
    end

    describe "#select_current_statement" do
      let(:accounts_table) { double(any?: false) }

      before do
        allow(browser).to receive(:search)
          .with(".cuentas-corrientes").and_return(accounts_table)
        allow(div).to receive(:attribute).with("data-numero-cuenta").and_return("12345678")
      end

      it "doesn't raise error" do
        expect { dummy.select_current_statement(account_number) }.not_to raise_error
      end

      context "with wrong account" do
        before do
          allow(div).to receive(:attribute).with("data-numero-cuenta").and_return("wrong_number")
        end

        it "raises error" do
          expect { dummy.select_current_statement(account_number) }.to raise_error(
            StandardError, "Statement of given account number is unavailable"
          )
        end
      end

      context "with multiple accounts" do
        let(:accounts_table) { double(any?: true) }
        let(:links) do
          [
            double(text: "wrong_account"),
            double(text: "12345678"),
            double(text: "wrong_account")
          ]
        end

        before do
          allow(links[1]).to receive(:click)
          allow(accounts_table).to receive(:map).and_return(links)
        end

        it "doesn't raise error" do
          expect { dummy.select_current_statement(account_number) }.not_to raise_error
        end

        context "with account missing in table" do
          let(:links) do
            [
              double(text: "wrong_account"),
              double(text: "wrong_account"),
              double(text: "wrong_account")
            ]
          end

          it "raises error" do
            expect { dummy.select_current_statement(account_number) }.to raise_error(
              StandardError, "Statement of given account number is unavailable"
            )
          end
        end
      end
    end

    describe "#account_current_statement_from_txt" do
      it "doesn't raise error" do
        expect { dummy.account_current_statement_from_txt }.not_to raise_error
      end

      it "returns expected statement" do
        expect(dummy.account_current_statement_from_txt).to eq(
          [
            {
              date: Date.new(2018, 1, 1),
              description: "Transferencia",
              trx_id: "0000000001",
              trx_type: :deposit,
              amount: 500_000,
              balance: 10_000_000
            }, {
              date: Date.new(2018, 1, 2),
              description: "Transferencia",
              trx_id: "0000000002",
              trx_type: :charge,
              amount: 500_000,
              balance: 9_500_000
            }
          ]
        )
      end

      context "with timeout when searching for download link" do
        before do
          allow(browser).to receive(:search).with("a:contains('Descargar TXT')").and_raise(
            StandardError, "Timeout"
          )
        end

        it "raises error" do
          expect { dummy.account_current_statement_from_txt }.to raise_error(
            StandardError, "Statement of given account number is unavailable"
          )
        end
      end
    end
  end

  describe "statements" do
    let(:txt_file) do
      double(
        content: "" +
          "1234567891234                 PESOS0000401/01/201801/01/201801/01/2018      1000000,00" +
          "                          JUAN PEREZ PEREZ+            0,00             0,00      \r\n" +
          "202/01/2018TRANSFERENCIA DESDE BANCO SECURITY DE JUANA PEREZ 000000001A+        1000" +
          ",00     1001000,00                                                                \r\n" +
          "203/01/2018TRANSFERENCIA DESDE BANCO FALABELLA DE JUAN PEREZ 000000002C+        2000" +
          ",00      999000,00                                                                \r\n" +
          "9+      1000000,00     1234567,00     1234567,00       123456,00                        "
      )
    end

    before do
      allow(dummy).to receive(:wait).with("select[name=\"Keyword\"]").and_return(input)
      allow(dummy).to receive(:wait).with("select[name=\"fecha\"]").and_return(input)
      allow(browser).to receive(:search).with('a').and_return([double, download_link, double])
    end

    describe "#select_account" do
      it "sets the account number" do
        expect(input).to receive(:set).with("12345678")
        dummy.select_account(account_number)
      end

      context "without account" do
        before do
          allow(input).to receive(:set).with("12345678").and_raise(
            StandardError, "Timeout"
          )
        end

        it "raises error" do
          expect { dummy.select_account(account_number) }.to raise_error(
            StandardError, "Statement of given account number is unavailable"
          )
        end
      end
    end

    describe "#select_month" do
      it "sets the month" do
        expect(input).to receive(:set).with(by_value: "012018")
        dummy.select_month(month, year)
      end

      context "without month statement" do
        before do
          allow(input).to receive(:set).with(by_value: "012018").and_raise(
            StandardError, "Timeout"
          )
        end

        it "raises error" do
          expect { dummy.select_month(month, year) }.to raise_error(
            StandardError, "Statement of given month and year is unavailable"
          )
        end
      end
    end

    describe "#select_statement" do
      it "doesn't raise_error" do
        expect { dummy.select_statement(account_number, month, year) }.not_to raise_error
      end

      it "sets the account number and month" do
        expect(input).to receive(:set).with("12345678")
        expect(input).to receive(:set).with(by_value: "012018")
        dummy.select_statement(account_number, month, year)
      end
    end

    describe "#account_statement_from_txt" do
      it "doesn't raise_error" do
        expect { dummy.account_statement_from_txt }.not_to raise_error
      end

      it "returns expected statement" do
        expect(dummy.account_statement_from_txt).to eq(
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
        )
      end

      context "without statement" do
        before do
          allow(dummy).to receive(:statement_available?).and_return(false)
        end

        it "raises error" do
          expect { dummy.account_statement_from_txt }.to raise_error(
            StandardError, "Statement of given month and account number is unavailable"
          )
        end
      end

      context "with unknown trx_type" do
        let(:txt_file) do
          double(
            content: "" +
            "1234567891234                 PESOS0000401/01/201801/01/201801/01/2018      1000000" +
            ",00                            JUAN PEREZ PEREZ+            0,00             0,00\n" +
            "202/01/2018TRANSFERENCIA DESDE BANCO SECURITY DE JUANA PEREZ 000000001X+        1000" +
            ",00     1001000,00                                                              \r\n" +
            "9+      1000000,00     1234567,00     1234567,00       123456,00                      "
          )
        end

        it "raises error" do
          expect { dummy.account_statement_from_txt }.to raise_error(
            StandardError, "Statement with trx of unknown type \"X\""
          )
        end
      end
    end
  end
end
