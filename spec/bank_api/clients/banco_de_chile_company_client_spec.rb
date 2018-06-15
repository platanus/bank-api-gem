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
    allow(browser).to receive(:search).and_return(div)
    allow(browser).to receive(:search).with('.linea1tabla').and_return(lines)

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
    allow(subject).to receive(:goto_deposits)
    allow(subject).to receive(:select_deposits_range)
    allow(subject).to receive(:submit_deposits_form)
  end

  describe "get_recent_deposits" do
    before do
      mock_validate_credentials
      mock_site_navigation
    end

    it 'validates and returns entries on get_recent_deposits' do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:get_deposits_try).and_return(
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
      ).exactly(2).times

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
      allow(browser).to receive(:search).with('table#sin_datos').and_return(['div'])
    end

    it 'returns empty array' do
      expect(subject.get_recent_deposits).to eq([])
    end
  end

  context "with pagination" do
    before do
      mock_validate_credentials
      mock_site_navigation
      expect(subject).to receive(:any_deposits?).and_return(true).exactly(2).times
      expect(subject).to receive(:total_results).and_return(30).exactly(2)
    end

    it "goes through every page" do
      expect(subject).to receive(:goto_next_page).exactly(4).times

      subject.get_recent_deposits
    end
  end

  describe "duplicate check" do
    before do
      mock_validate_credentials
      mock_site_navigation
    end

    context "without duplicates" do
      before do
        expect(subject).to receive(:get_deposits_try).and_return(
          [
            {
              rut: '12.345.678-9',
              date: Date.parse('01/01/2018'),
              amount: 1000
            }
          ]
        ).exactly(2).times
      end

      it "returns deposits" do
        expect(subject.get_recent_deposits.count).to eq(1)
      end
    end

    context "with duplicates" do
      before do
        expect(subject).to receive(:get_deposits_try).and_return(
          [
            {
              rut: '12.345.678-9',
              date: Date.parse('01/01/2018'),
              amount: 1000
            }
          ],
          [
            {
              rut: '12.345.678-9',
              date: Date.parse('01/01/2018'),
              amount: 1000
            },
            {
              rut: '12.345.678-9',
              date: Date.parse('01/01/2018'),
              amount: 1000
            }
          ]
        )
      end

      it "returns no deposits" do
        expect(subject.get_recent_deposits.count).to eq(0)
      end
    end
  end
end
