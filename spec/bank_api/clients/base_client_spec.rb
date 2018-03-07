require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BaseClient do
  let (:subject) { described_class.new }

  def mock_validate_credentials
    allow(subject).to receive(:validate_credentials)
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits).and_return([])
  end

  context "get_recent_deposits" do
    before do
      mock_validate_credentials
      mock_get_deposits
    end

    it 'validates and returns entries on get_recent_deposits' do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:get_deposits)

      subject.get_recent_deposits
    end
  end

  context 'without validate_credentials implementation' do
    before do
      mock_get_deposits
    end

    it 'raises NotImplementedError' do
      expect { subject.get_recent_deposits }.to raise_error(NotImplementedError)
    end
  end

  context 'without get_deposits implementation' do
    before do
      mock_validate_credentials
    end

    it 'raises NotImplementedError' do
      expect { subject.get_recent_deposits }.to raise_error(NotImplementedError)
    end
  end

  describe 'wait' do
    let(:browser) do
      double(
        config: {
          wait_timeout: 5.0,
          wait_interval: 0.5
        }
      )
    end
    let(:query) { 'test' }
    let(:div) { double }

    before do
      allow(subject).to receive(:browser).and_return(browser)
      allow(browser).to receive(:search).with(query).and_return(div)
      allow(div).to receive(:any?).and_return(true)
    end

    context 'with block given' do
      it 'calls block' do
        expect(div).to receive(:present?).and_return(true)

        subject.send(:wait, query) { div.present? }
      end

      it "timeouts if condition isn't met" do
        expect(div).to receive(:present?).exactly(10).times.and_return(false)

        subject.send(:wait, query) { div.present? }
      end
    end

    context 'with no block given' do
      it 'calls any? on query result' do
        expect(div).to receive(:any?)

        subject.send(:wait, query)
      end

      it "timeouts if condition isn't met" do
        expect(div).to receive(:any?).exactly(10).times.and_return(false)

        subject.send(:wait, query)
      end
    end
  end
end
