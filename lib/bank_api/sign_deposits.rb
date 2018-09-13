module BankApi::SignDeposits
  extend self

  def sign(deposits)
    entries = get_entry_occurrencies(deposits)
    sign_entries(entries)
  end

  private

  def get_entry_occurrencies(deposits)
    entry_occurrencies_keys = {}

    deposits.map do |entry|
      key = entry_key(entry)
      occurrency = entry_occurrencies_keys[key] || 0
      entry_occurrencies_keys[key] = occurrency + 1

      { deposit_entry: entry, occurrencies: entry_occurrencies_keys[key] }
    end
  end

  def sign_entries(entries)
    entries.each { |entry_occurrency| sign_entry(entry_occurrency) }
  end

  def sign_entry(entry_occurrency)
    entry = entry_occurrency[:deposit_entry]
    occurrencies = entry_occurrency[:occurrencies]

    entry.signature = entry_signature(entry, occurrencies)
  end

  def entry_signature(entry, occurrencies)
    key = entry_key(entry)
    "#{key}|#{occurrencies}"
  end

  def entry_key(entry)
    rut_or_client = entry.rut || entry.client.to_s.downcase.delete(' ')
    "#{entry.amount}|#{entry.date}|#{rut_or_client}|#{entry.bank}"
  end
end
