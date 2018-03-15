require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoSecurity::CompanyClient do
  let(:deposits) do
    [
      {
        amount: 1000,
        date: Date.parse('01/01/2017'),
        rut: '12.345.678-9'
      },
      {
        amount: 2000,
        date: Date.parse('01/01/2017'),
        rut: '12.345.678-9'
      }
    ]
  end

  let(:lines) do
    [
      '01/01/2018', '', '12.345.678-9', '', '', '$ 1.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 2.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 3.000', '',
      '01/01/2018', '', '12.345.678-9', '', '', '$ 4.000', ''
    ].map { |t| double(text: t) }
  end

  let(:div) { double }

  let(:browser) do
    double(
      config: {
        wait_timeout: 5.0,
        wait_interval: 0.5
      }
    )
  end

  let (:subject) do
    described_class.new(
      double(
        banco_security: double(user_rut: '', 'password': '', company_rut: ''),
        days_to_check: 6
      )
    )
  end

  before do
    allow(subject).to receive(:browser).and_return(browser)

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('#gridPrincipalRecibidas tbody td').and_return(lines)

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
    allow(subject).to receive(:goto_company_dashboard)
    allow(subject).to receive(:goto_deposits)
    allow(subject).to receive(:select_deposits_range)
  end

  describe "get_recent_deposits" do
    before do
      mock_validate_credentials
    end

    it 'validates and returns entries on get_recent_deposits' do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:get_deposits).and_return(
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
            amount: 4000
          }
        ]
      )

      subject.get_recent_deposits
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

  context 'with no deposits' do
    before do
      mock_validate_credentials
      mock_site_navigation
      allow(subject).to receive(:any_deposits?).and_return(false)
    end

    it 'returns empty array' do
      expect(subject.get_recent_deposits).to eq([])
    end
  end

  context "with pagination" do
    before do
      mock_validate_credentials
      mock_site_navigation
      expect(subject).to receive(:any_deposits?).and_return(true)
      expect(subject).to receive(:total_results).and_return(150)
    end

    it "goes through every page" do
      expect(subject).to receive(:goto_next_page).exactly(2).times

      subject.get_recent_deposits
    end
  end
end
