require 'bank_api/values/dynamic_card'

module BankApi::Configs
  class BancoSecurity
    attr_accessor :user_rut, :password, :company_rut, :dynamic_card_entries

    def initialize
      @user_rut = nil
      @password = nil
      @company_rut = nil
      @dynamic_card_entries = nil
    end

    def dynamic_card
      DynamicCard.new(@dynamic_card_entries) unless @dynamic_card_entries.nil?
    end
  end
end
