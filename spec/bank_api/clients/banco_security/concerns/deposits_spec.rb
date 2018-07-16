require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Deposits do
  let(:browser) { double(config: { wait_timeout: 5.0, wait_interval: 0.2 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

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
    allow(dummy).to receive(:any_deposits?).and_return(true)

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

  it "implements select_deposits_range" do
    expect { dummy.select_deposits_range }.not_to raise_error
  end

  it "implements deposits_from_txt" do
    expect { dummy.deposits_from_txt }.not_to raise_error
  end

  context "with deposits" do
    it "returns deposits" do
      expect(dummy.deposits_from_txt).to eq(
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
            amount: 3000
          },
          {
            rut: '12.345.678-9',
            date: Date.parse('02/01/2018'),
            amount: 4000
          }
        ]
      )
    end
  end
end
