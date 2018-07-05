module BankApi::Clients::BancoSecurity
  module PendingTransfers
    TRX_ID_COLUMN = 0
    DATETIME_COLUMN = 1
    ORIGIN_COLUMN = 2
    ACCOUNT_COLUMN = 3
    AMOUNT_COLUMN = 4

    TRANSFER_DETAILS_ACCOUNT_COLUMN = 0
    TRANSFER_DETAILS_RUT_COLUMN = 4
    TRANSFER_DETAILS_AMOUNT_COLUMN = 7

    def find_pending_transfer(trx_id)
      pending_operations_table = browser.search(".Marco table")[1]
      transfers = pending_operations_table.search("tr").drop(1).map do |tr|
        build_pending_transfer(
          tr.search("td").map(&:text).drop(1),
          tr.search("td").first.search("input")
        )
      end
      transfers.find { |t| t[:trx_id] == trx_id }
    end

    def select_pending_transfer(pending_transfer)
      pending_transfer[:input].click
      select_pending_transfer_method
      selenium_browser.execute_script("PagarValores();")
    end

    def select_pending_transfer_method
      set_pending_transfer_method_as_dynamic_card
    end

    def set_pending_transfer_method_as_digipass
      browser.search("input[value=\"TK\"]").click
    end

    def set_pending_transfer_method_as_dynamic_card
      browser.search("input[value=\"TC\"]").click
    end

    def set_pending_transfer_method_as_fea
      browser.search("input[value=\"FE\"]").click
    end

    def fill_pending_transfer_coordinates
      coordinates_table = browser.search(".Marco table")[2]
      coordinates = coordinates_table.search("td span").map(&:text)
      coordinates_inputs = coordinates_table.search("td input")

      3.times.each do |i|
        coordinate = coordinates[i]
        value = @dynamic_card.get_coordinate_value(coordinate)
        coordinates_inputs[i].set(value)
      end
      selenium_browser.execute_script("_Validar('');")
    end

    def validate_pending_transfer_data(transfer_data)
      wait("span:contains('Monto a Transferir')")
      validate_rut(transfer_data[:rut]) unless transfer_data[:rut].nil?
      validate_account(transfer_data[:account]) unless transfer_data[:account].nil?
      validate_origin(transfer_data[:origin]) unless transfer_data[:origin].nil?
      validate_amount(transfer_data[:amount]) unless transfer_data[:amount].nil?
    end

    def transfer_details_table
      browser.search(".Marco table")[1].search("td").map(&:text)
    end

    def validate_rut(rut)
      transfer_rut = transfer_details_table[TRANSFER_DETAILS_RUT_COLUMN]
      unless strip_rut(rut) == strip_rut(transfer_rut)
        raise ::BankApi::Transfer::InvalidAccountData,
          "#{rut} doesn't match transfer's rut #{transfer_rut}"
      end
    end

    def validate_amount(amount)
      transfer_amount = transfer_details_table.last.tr("$.", "").to_i
      unless amount == transfer_amount
        raise ::BankApi::Transfer::InvalidAmount,
          "#{amount} doesn't match transfer's amount #{transfer_amount}"
      end
    end

    def validate_account(account)
      transfer_account = transfer_details_table[TRANSFER_DETAILS_ACCOUNT_COLUMN]
      unless format_account(account) == format_account(transfer_account)
        raise ::BankApi::Transfer::InvalidAccountData,
          "#{account} doesn't match transfer's account #{transfer_account}"
      end
    end

    def validate_origin(origin)
      transfer_origin = browser.search(".Marco table")[0].search("td").first.text
      unless format_account(origin) == format_account(transfer_origin)
        raise ::BankApi::Transfer::InvalidAccountData,
          "#{origin} doesn't match transfer's origin #{transfer_origin}"
      end
    end

    def build_pending_transfer(row, input)
      {
        trx_id: row[TRX_ID_COLUMN].strip,
        datetime: row[DATETIME_COLUMN].strip,
        origin: row[ORIGIN_COLUMN].strip,
        account: row[ACCOUNT_COLUMN].strip,
        amount: row[AMOUNT_COLUMN].strip.delete(".").to_i,
        input: input
      }
    end

    def format_account(number)
      number.match(/0*([0-9]*)/)[1]
    end

    def strip_rut(rut)
      rut.tr(".-", "")
    end
  end
end
