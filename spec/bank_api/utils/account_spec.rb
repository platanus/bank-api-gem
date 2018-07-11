require 'date'
require 'spec_helper'

RSpec.describe Utils::Account do
  describe "#format_account" do
    it "removes first zeroes" do
      expect(described_class.format_account("0000123456789")).to eq("123456789")
    end

    it "keeps account number if there's no padding zeroes" do
      expect(described_class.format_account("123456789")).to eq("123456789")
    end
  end
end
