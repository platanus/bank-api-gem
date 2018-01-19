require 'date'
require 'spec_helper'

RSpec.describe BankApi::SignDeposits do
  let(:entries) { [BankApi::Values::DepositEntry.new(25000, Date.new(2017, 3, 3), '12345678-9')] }

  context 'with a single entry' do
    it 'calculates the corresponding signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq('d304467760d30830cc339127b47fc36bdbc20999')
    end
  end

  context 'with entries with same data' do
    before do
      entries << BankApi::Values::DepositEntry.new(25000, Date.new(2017, 3, 3), '12345678-9')
    end

    it 'calculates different signature' do
      BankApi::SignDeposits.sign(entries)
      expect(entries[0].signature).to eq('d304467760d30830cc339127b47fc36bdbc20999')
      expect(entries[1].signature).not_to eq('d304467760d30830cc339127b47fc36bdbc20999')
    end
  end
end
