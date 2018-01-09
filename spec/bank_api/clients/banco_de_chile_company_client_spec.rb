require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BancoDeChileCompanyClient do
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
      '',
      '01/01/2018', '', '', '', '12.345.678-9', '', '1,000', 'Aprobada', '',
      '01/01/2018', '', '', '', '12.345.678-9', '', '2,000', 'Aprobada', '',
      '01/01/2018', '', '', '', '12.345.678-9', '', '3,000', 'Rechazada', '',
      '01/01/2018', '', '', '', '12.345.678-9', '', '4,000', 'Aprobada', ''
    ].map { |t| double(text: t) }
  end

  let(:div) { double }

  let(:browser) { double }

  let (:subject) do
    described_class.new(
      double(
        bdc_company_rut: '',
        bdc_user_rut: '',
        bdc_password: '',
        days_to_check: 6
      )
    )
  end

  before do
    allow(subject).to receive(:browser).and_return(browser)

    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:search).with('.linea1tabla').and_return(lines)
    allow(browser).to receive(:search).and_return(div)

    allow(div).to receive(:click)
    allow(div).to receive(:set)
  end

  def mock_validate_credentials
    allow(subject).to receive(:validate_credentials)
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits)
  end

  context "get_recent_deposits" do
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
end
