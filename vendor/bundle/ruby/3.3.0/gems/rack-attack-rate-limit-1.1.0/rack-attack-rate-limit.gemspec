# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack/attack/rate-limit/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-attack-rate-limit"
  spec.version       = Rack::Attack::RateLimit::VERSION
  spec.authors       = ["Jason Byck"]
  spec.email         = ["jasonbyck@gmail.com"]
  spec.description   = %q{ Add RateLimit headers for Rack::Attack throttling }
  spec.summary       = %q{ Add RateLimit headers for Rack::Attack throttling }
  spec.homepage      = "https://github.com/jbyck/rack-attack-rate-limit"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rack'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rubocop'

end
