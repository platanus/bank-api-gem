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
    end
  end

  let(:dummy) { DummyClass.new }

  let(:lines) do
    [
      '01/01/2018', '', '12.345.678-9', '', '', '$ 1.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 2.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 3.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 4.000', ''
    ].map { |t| double(text: t) }
  end

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:browser).and_return(browser)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('#gridPrincipalRecibidas tbody td').and_return(lines)
    allow(browser).to receive(:goto)
    allow(div).to receive(:any?).and_return(true)
    allow(div).to receive(:count).and_return(1)
    allow(div).to receive(:click)
    allow(div).to receive(:set)
  end

  it "implements select_deposits_range" do
    expect { dummy.select_deposits_range }.not_to raise_error
  end

  it "implements extract_deposits_from_html" do
    expect { dummy.extract_deposits_from_html }.not_to raise_error
  end

  context "with deposits" do
    it "returns deposits" do
      expect(dummy.extract_deposits_from_html).to eq(
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
            date: Date.parse('01/01/2018'),
            amount: 4000
          }
        ]
      )
    end
  end

  context "without deposits" do
    before do
      allow(browser).to receive(:search).with('#gridPrincipalRecibidas tbody td').and_return([])
    end

    it "returns empty array" do
      expect(dummy.extract_deposits_from_html).to eq([])
    end
  end
end
