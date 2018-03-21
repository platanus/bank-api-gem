require 'date'
require 'spec_helper'

RSpec.describe BankApi::SignDeposits do
  let(:entries) do
    [
      BankApi::Values::DepositEntry.new(
        25000, Date.new(2017, 3, 3), '12345678-9', :security
      )
    ]
  end

  let(:expected_signature) { '6e652e430638ab1c6fa631553c21344972017c48666' }

  before { allow(Time).to receive(:now).and_return(666) }

  context 'with a single entry' do
    it 'calculates the corresponding signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq(expected_signature)
    end
  end

  context 'with entries with same data' do
    before do
      entries << BankApi::Values::DepositEntry.new(
        25000, Date.new(2017, 3, 3), '12345678-9', :security
      )
    end

    it 'calculates different signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq(expected_signature)
      expect(entries[1].signature).not_to eq(expected_signature)
    end
  end
end
