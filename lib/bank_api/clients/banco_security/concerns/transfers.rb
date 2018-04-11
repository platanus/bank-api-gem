module BankApi::Clients::BancoSecurity
  module Transfers
    def validate_transfer_missing_data(transfer_data)
      if [transfer_data[:origin] || @company_rut].all?(&:nil?)
        raise BankApi::Transfer::MissingTransferData
      end
      if [
        transfer_data[:amount],
        transfer_data[:name],
        transfer_data[:rut],
        transfer_data[:account_number],
        transfer_data[:email]
      ].any?(&:nil?)
        raise BankApi::Transfer::MissingTransferData
      end
    end

    def validate_transfer_valid_data(transfer_data)
      unless Utils::BancoSecurity.valid_banks.include? transfer_data[:bank]
        raise BankApi::Transfer::InvalidBank
      end
      unless Utils::BancoSecurity.valid_account_types.include? transfer_data[:account_type]
        raise BankApi::Transfer::InvalidAccountType
      end
    end

    def submit_transfer_form(transfer_data)
      set_transfer_transaction_data(transfer_data)
      set_transfer_user_data(transfer_data)
      browser.search('.active #enviar-paso-1').click
    end

    def set_transfer_user_data(transfer_data)
      browser.search('.active #destinatario-nombre').set(transfer_data[:name])
      browser.search('.active #destinatario-rut').set(transfer_data[:rut])
      browser.search('.active #Email').set(transfer_data[:email])
    end

    def set_transfer_transaction_data(transfer_data)
      browser.search('.active #Monto').set(transfer_data[:amount])
      browser.search('.active #destinatario-cuenta').set(transfer_data[:account_number])
      browser.search('.active #destinatario-banco').set(
        Utils::BancoSecurity.bank_name(transfer_data[:bank])
      )
      browser.search(
        ".active [name=\"tipo-cuenta\"][data-nombre=\"" +
          Utils::BancoSecurity.account_type(transfer_data[:account_type]) +
          "\"]"
      ).set
      browser.search('.active #Comentario').set(transfer_data[:comment])
    end

    def fill_coordinates
      browser.search("[name=\"clave-dinamica-radio\"][value=\"tarjeta-clave\"]").set
      (1..3).each do |i|
        coordinate = browser.search("label[for=\"coordenada-#{i}\"").text
        value = @dynamic_card.get_coordinate_value(coordinate)
        browser.search("#coordenada-#{i}").set(value)
      end
      browser.search('#enviar-paso-2').click
    end
  end
end
