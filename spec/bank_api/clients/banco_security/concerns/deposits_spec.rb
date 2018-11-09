require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Deposits do
  let(:browser) { double(config: { wait_timeout: 5.0, wait_interval: 0.2 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }
  let(:selenium_browser) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Deposits

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
      @page_size = 30
    end
  end

  let(:dummy) { DummyClass.new }

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

  let(:page_info) { double(text: "1 - 4 de 4", any?: true) }

  def mock_set_page_size
    allow(dummy).to receive(:set_page_size)
  end

  def mock_wait_for_deposits_fetch
    allow(dummy).to receive(:wait_for_deposits_fetch)
  end

  def mock_wait_for_next_page
    allow(dummy).to receive(:wait_for_next_page)
  end

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:browser).and_return(browser)
    allow(dummy).to receive(:deposits_txt_url).and_return(txt_url)
    allow(dummy).to receive(:deposits_account_details_url).and_return(txt_url)
    allow(dummy).to receive(:any_deposits?).and_return(true)
    allow(dummy).to receive(:setup_authentication)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('.k-pager-info').and_return(page_info)
    allow(browser).to receive(:goto)
    allow(browser).to receive(:download).with(txt_url).and_return(txt_file)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:none?).and_return(true)
    allow(div).to receive(:count).and_return(1)
    allow(div).to receive(:click)
    allow(div).to receive(:set)

    mock_set_page_size
    mock_wait_for_deposits_fetch
    mock_wait_for_next_page
  end

  it "implements deposits_from_txt" do
    expect { dummy.deposits_from_txt }.not_to raise_error
  end

  context "with deposits" do
    it "returns deposits" do
      expect(dummy.deposits_from_txt).to eq(
        [
          {
            client: "PEPE",
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            time: Time.parse('01/01/2018 4:15 UTC'),
            amount: 1000
          },
          {
            client: "GARY",
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            time: Time.parse('01/01/2018 8:15 UTC'),
            amount: 2000
          },
          {
            client: "PEPE",
            rut: '12.345.678-9',
            date: Date.parse('01/01/2018'),
            time: Time.parse('01/01/2018 10:15 UTC'),
            amount: 3000
          },
          {
            client: "PEPE",
            rut: '12.345.678-9',
            date: Date.parse('02/01/2018'),
            time: Time.parse('02/01/2018 00:00 UTC'),
            amount: 4000
          }
        ]
      )
    end
  end

  context "without deposits" do
    before { allow(dummy).to receive(:any_deposits?).and_return(false) }

    it "raises error" do
      expect { dummy.deposits_from_txt }.to raise_error(
        BankApi::Deposit::FetchError, "Couldn't fetch deposits"
      )
    end
  end

  context "with deposits from account details" do
    let(:txt_file) do
      content = <<~DOC
        Nombre;Direcci\xF3n;Comuna;Ciudad;Cuenta;Moneda;Cartola;Desde;Hasta;Fecha cartola anterior;Saldo final cartola anterior;Ejecutivo;Oficina;Tel\xE9fono;L\xEDnea de Cr\xE9dito Monto utilizado;L\xEDnea de Cr\xE9dito Monto Disponible;Vencimiento\r\LEANS ADMINISTRADORA GENERAL DE FONDOS S A;LOS CONQUISTADORES 111, PROVIDENCIA, SANTIAGO;PROVIDENCIA;SANTIAGO;666698607;CLP;Provisoria;666666;7777777;Fecha cartola anterior en duro;;LEAN SEGOVIA;EL GOLF;2342342234;0;0.0;4334334\r\nFecha;Descripci\xF3n;N de documento;Cargos;Abonos;Saldo\r\n12/09;TRANSFERENCIA DESDE Banco Santander De ALICIA FORTUNATO ; 00056290667;0.00;180,000.00;47,300,662.00\r\n12/09;TRANSFERENCIA DESDE Banco Santander De SANDRA VILLANUEVA; 00056290549;0.00;2,230,000.00;47,120,662.00\r\n12/09;TRANSFERENCIA DESDE BANCO SECURITY DE LEANDRO SEGOVIA ; 00056290121;0.00;300,000.00;44,890,662.00\r\n24/10;TRANSFERENCIA
        DESDE Banco Santander De CAMILO DE LOS REYES; 00056290549;0.00;2,450,000.00;47,120,662.00\r\n12/09;TRANSFERENCIA A Banco Santander PARA Mario Ruiz Tagle; 00056288530;199,073.00;0.00;44,590,662.00\r\n12/09;TRANSFERENCIA A BCI PARA Juan Bustos Cavada ; 00056288222;4,150,374.00;0.00;44,789,735.00\r\n12/09;TRANSFERENCIA A Banco Chile-Edwards-Citi PARA Javier Andr s Soto  ; 00056288091;92,000.00;0.00;48,940,109.00\r\n12/09;TRANSFERENCIA A
        Banco Santander PARA Sebastian Ortega; 00056287857;2,231,196.00;0.00;49,032,109.00\r\n03/09;TRANSFERENCIA DESDE BBVA De SILVA DAURO ; 00054935695;0.00;50,000.00;93,342,708.00\r\n03/09;SALDO INICIAL;;0.00;0.00;93,292,708.00\r\nResumen del per\xEDodo\r\nSaldo inicial;Total cargos;Total abonos;Saldo final\r\n93,292,708.00;696,761,603.00;650,769,557.00;93,292,708.00\r\nCheques pagados\r\n;;;;;\r\nCheques devueltos\r\n;;;;;\r\n
      DOC

      double(content: content)
    end

    it "returns deposits" do
      expect(dummy.deposits_from_account_details).to eq(
        [
          {
            client: "SILVA DAURO",
            rut: nil,
            date: Date.parse('03/09/2018'),
            time: nil,
            amount: 50000
          },
          {
            client: "CAMILO DE LOS REYES",
            rut: nil,
            date: Date.parse('24/10/2018'),
            time: nil,
            amount: 2450000
          },
          {
            client: "LEANDRO SEGOVIA",
            rut: nil,
            date: Date.parse('12/09/2018'),
            time: nil,
            amount: 300000
          },
          {
            client: "SANDRA VILLANUEVA",
            rut: nil,
            date: Date.parse('12/09/2018'),
            time: nil,
            amount: 2230000
          }
        ]
      )
    end
  end
end
