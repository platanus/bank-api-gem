module Utils
  module BancoSecurity
    extend self

    BANKS = {
      banco_de_chile: 'Banco Chile-Edwards-Citi',
      banco_consorcio: 'Banco Consorcio',
      banco_del_desarrollo: 'Banco del Desarrollo',
      banco_estado: 'Banco Estado',
      banco_falabella: 'Banco Falabella',
      banco_internacional: 'Banco Internacional',
      banco_itau: 'Banco Ita\u00FA',
      banco_paris: 'Banco Paris',
      banco_rabobank: 'Banco Rabobank',
      banco_ripley: 'Banco Ripley',
      banco_santander: 'Banco Santander',
      banco_security: 'Banco Security',
      bbva: 'BBVA',
      bci: 'BCI',
      bice: 'BICE',
      coopeuch: 'COOPEUCH',
      corpbanca: 'Corpbanca',
      hsbc: 'HSBC BANK',
      scotiabank: 'Scotiabank'
    }

    def bank_name(bank)
      BANKS[bank]
    end

    def valid_banks
      BANKS.keys.sort
    end

    ACCOUNT_TYPES = {
      cuenta_corriente: 'Cuenta Corriente',
      cuenta_vista: 'Cuenta Vista',
      cuenta_de_ahorro: 'Cuenta de Ahorro'
    }

    def account_type(type)
      ACCOUNT_TYPES[type]
    end

    def valid_account_types
      ACCOUNT_TYPES.keys.sort
    end

    def format_rut(rut)
      verification_digit = rut[-1]
      without_verification_digit = rut[0..-2].reverse.scan(/.{1,3}/).join(".").reverse
      "#{without_verification_digit}-#{verification_digit}"
    end
  end
end
