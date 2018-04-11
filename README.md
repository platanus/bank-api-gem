# BankApi

BankApi is a gem that wraps chilean banks web operations. For now, it can get recent deposits on Banco de Chile accounts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bank_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bank_api

## Usage

For now, the gem can get recent deposits of Banco de Chile accounts (only Enterprise accounts have been tested) and BancoSecurity's accounts. To add your credentials so the client can login, create the following initializer:

```
# config/initializers/bank_api.rb

BankApi.configure do |config|
  # Banco de Chile config
  config.bdc_user_rut = '12345678-9'
  # Add the account's password
  config.bdc_password = 'secretpassword'
  config.bdc_company_rut = '98765432-1'

  # Deposits config
  config.days_to_check = 3

  # BancoSecurity config
  config.banco_security.user_rut = '12345678-9'
  config.banco_security.password = 'secretpassword'
  config.banco_security.company_rut = '98765432-1'
  config.banco_security.dynamic_card_entries = "[['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A10'], ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B9', 'B10'], ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10'], ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10'], ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10']]"
end

```

The days to check is set by default to 6, and can be configured as seen in the initializer.

For BancoSecurity's account there's also de posibility to make transfers to third party's accounts using the dynamic card. To use this feature, you must specify the `dynamic_card_entries` variable in the config, then call:

```
  BankApi.company_transfer({
    amount: 1000,
    name: "John Doe",
    rut: "12.345.678-9",
    account_number: "11111111",
    bank: :banco_estado,
    account_type: :cuenta_corriente,
    email: "doe@platan.us",
    comment: "This is a comment",
    origin: "9.876.543-2"
  })
```

If you don't setup the origin on the transfer's data, the default'll be `config.banco_security.company_rut`. You can also make transfers on batches:

```
  BankApi.company_batch_transfers([
    {
      amount: 1000,
      name: "John Doe",
      rut: "12.345.678-9",
      account_number: "11111111",
      bank: :banco_estado,
      account_type: :cuenta_corriente,
      email: "doe@platan.us",
      comment: "This is a comment",
      origin: "9.876.543-2"
    }, {
      amount: 2000,
      name: "John Does",
      rut: "12.345.678-9",
      account_number: "11111111",
      bank: :banco_estado,
      account_type: :cuenta_corriente,
      email: "does@platan.us",
      comment: "This is a comment",
      origin: "9.876.543-2"
    }
  ])
```

Checkout the available banks and account types in [this file](./lib/bank_api/utils/banco_security.rb).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Heroku

1. Add https://github.com/heroku/heroku-buildpack-chromedriver.git buildpack.
2. Add https://github.com/kevinsawicki/heroku-buildpack-xvfb-google-chrome.git buildpack.
3. Set `'GOOGLE_CHROME_BIN_PATH'` env var with value `"/app/.apt/usr/bin/google-chrome-stable"`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/bank_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BankApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/platanus/bank-api-gem/blob/master/CODE_OF_CONDUCT.md).
