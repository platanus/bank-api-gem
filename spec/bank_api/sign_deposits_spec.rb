require 'date'
require 'spec_helper'

RSpec.describe BankApi::SignDeposits do
  let(:entries) do
    [
      BankApi::Values::DepositEntry.new(
        25000, Date.new(2017, 3, 3), nil, '12345678-9', :security, "Lean"
      )
    ]
  end

  let(:expected_signature) { '25000|2017-03-03|12345678-9|security|1' }

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
        25000, Date.new(2017, 3, 3), nil, '12345678-9', :security, "Lean"
      )
    end

    it 'calculates different signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq(expected_signature)
      expect(entries[1].signature).not_to eq(expected_signature)
    end
  end

  context 'when entry has nil rut' do
    let(:expected_signature) { '25000|2017-03-03|lean|security|1' }

    before { entries.first.rut = nil }

    it 'calculates different signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq(expected_signature)
    end
  end
end
