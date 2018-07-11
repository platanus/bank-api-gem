require 'date'
require 'spec_helper'

RSpec.describe Utils::Rut do
  describe "#strip_rut" do
    let(:rut) { "12.345.678-9" }
    let(:expected_rut) { "123456789" }

    it "returns expected rut" do
      expect(described_class.strip_rut(rut)).to eq(expected_rut)
    end
  end
end
