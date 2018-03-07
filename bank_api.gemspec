
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bank_api/version"

Gem::Specification.new do |spec|
  spec.name          = "bank_api"
  spec.version       = BankApi::VERSION
  spec.authors       = ["oaestay"]
  spec.email         = ["oaestay@uc.cl"]

  spec.summary       = 'Wrapper for chilean banks'
  spec.description   = 'Wrapper for chilean banks'
  spec.homepage      = 'https://github.com/platanus/bank-api-gem'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'pincers'
  spec.add_dependency 'timezone', '~> 1.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
