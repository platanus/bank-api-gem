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
end
