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

For now, the gem can only get recent deposits of Banco de Chile accounts (only Enterprise accounts have been tested). To add your credentials so the client can login, create the following initializer:

```
# config/initializers/bank_api.rb

BankApi.configure do |config|
  # Add the rut linked to the account
  config.bdc_user_rut = '12345678-9'
  # Add the account's password
  config.bdc_password = 'secretpassword'
  # Add the account's enterprise rut
  config.bdc_company_rut = '98765432-1'
  config.days_to_check = 3
end

```

The days to check is set by default to 6, and can be configured as seen in the initializer.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/bank_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BankApi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/platanus/bank-api-gem/blob/master/CODE_OF_CONDUCT.md).
