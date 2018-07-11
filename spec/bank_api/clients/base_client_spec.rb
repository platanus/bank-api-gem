require 'date'
require 'spec_helper'

RSpec.describe BankApi::Clients::BaseClient do
  let (:subject) { described_class.new }
  let(:transfer_data) { double }
  let(:transfers_data) { [transfer_data, double] }

  def mock_validate_credentials
    allow(subject).to receive(:validate_credentials)
  end

  def mock_get_deposits
    allow(subject).to receive(:get_deposits).and_return([])
  end

  def mock_validate_transfer_missing_data
    allow(subject).to receive(:validate_transfer_missing_data)
  end

  def mock_validate_transfer_valid_data
    allow(subject).to receive(:validate_transfer_valid_data)
  end

  def mock_execute_transfer
    allow(subject).to receive(:execute_transfer)
  end

  def mock_execute_batch_transfers
    allow(subject).to receive(:execute_batch_transfers)
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

  context 'without validate_credentials implementation on get_recent_deposits' do
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

  describe "#get_statement" do
    let(:account_number) { "000012345678" }
    let(:company_rut) { "12.345.678-9" }
    let(:month) { 1 }
    let(:year) { 2018 }

    it "validates credentials and returns statement" do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:get_statement_of_month)
      subject.get_statement(
        account_number: account_number, month: month, year: year, company_rut: company_rut
      )
    end
  end

  describe "#get_statement_of_month" do
    let(:account_number) { "000012345678" }
    let(:company_rut) { "12.345.678-9" }
    let(:month) { 1 }
    let(:year) { 2018 }

    it "raises error" do
      expect do
        subject.send(:get_statement_of_month, account_number, month, year, company_rut)
      end.to raise_error(NotImplementedError)
    end
  end

  describe "#transfer" do
    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
      mock_execute_transfer
    end

    it "validates and executes transfer" do
      expect(subject).to receive(:validate_credentials)
      expect(subject).to receive(:validate_transfer_missing_data).with(transfer_data)
      expect(subject).to receive(:validate_transfer_valid_data).with(transfer_data)
      expect(subject).to receive(:execute_transfer).with(transfer_data)

      subject.transfer(transfer_data)
    end
  end

  describe "#batch_transfers" do
    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
      mock_execute_transfer
    end

    it "validates and executes transfer" do
      expect(subject).to receive(:validate_credentials)
      transfers_data.each do |transfer_data|
        expect(subject).to receive(:validate_transfer_missing_data).with(transfer_data)
        expect(subject).to receive(:validate_transfer_valid_data).with(transfer_data)
      end
      expect(subject).to receive(:execute_batch_transfers).with(transfers_data)

      subject.batch_transfers(transfers_data)
    end
  end

  context "without validate_credentials implementation on transfer" do
    before do
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
      mock_execute_transfer
    end

    it "raises NotImplementedError" do
      expect { subject.transfer(transfer_data) }.to raise_error(NotImplementedError)
    end
  end

  context "without validate_transfer_missing_data implementation" do
    before do
      mock_validate_credentials
      mock_validate_transfer_valid_data
      mock_execute_transfer
    end

    it "raises NotImplementedError" do
      expect { subject.transfer(transfer_data) }.to raise_error(NotImplementedError)
    end
  end

  context "without validate_transfer_valid_data implementation" do
    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_execute_transfer
    end

    it "raises NotImplementedError" do
      expect { subject.transfer(transfer_data) }.to raise_error(NotImplementedError)
    end
  end

  context "without execute_transfer implementation" do
    before do
      mock_validate_credentials
      mock_validate_transfer_missing_data
      mock_validate_transfer_valid_data
    end

    it "raises NotImplementedError" do
      expect { subject.transfer(transfer_data) }.to raise_error(NotImplementedError)
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
