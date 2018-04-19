require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::Login, client: true do
  let(:browser) { double(config: { wait_timeout: 5.0, wait_interval: 0.2 }) }
  let(:div) { double(text: 'text') }
  let(:dynamic_card) { double }

  class DummyClass < BankApi::Clients::BaseClient
    include BankApi::Clients::BancoSecurity::Login

    def initialize
      @user_rut = '12.345.678-9'
      @password = 'password'
      @company_rut = '98.765.432-1'
      @days_to_check = 6
      @page_size = 30
    end
  end

  let(:dummy) { DummyClass.new }

  before do
    dummy.instance_variable_set(:@dynamic_card, dynamic_card)
    allow(dummy).to receive(:browser).and_return(browser)
    allow(dummy).to receive(:goto_login)

    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:goto)
    allow(div).to receive(:click)
    allow(div).to receive(:set)
  end

  it "implements login" do
    expect { dummy.login }.not_to raise_error
  end

  it "implements set_login_values" do
    expect { dummy.set_login_values }.not_to raise_error
  end

  it "implements click_login_button" do
    expect { dummy.click_login_button }.not_to raise_error
  end

  fit "logins with correct values" do
    expect_to_set(browser, query: "#lrut", value: '12.345.678-9')
    expect_to_set(browser, query: "#lpass", value: 'password')

    dummy.set_login_values
  end
end
