# -*- encoding: utf-8 -*-
# stub: rack-attack-rate-limit 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-attack-rate-limit".freeze
  s.version = "1.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jason Byck".freeze]
  s.date = "2014-08-01"
  s.description = " Add RateLimit headers for Rack::Attack throttling ".freeze
  s.email = ["jasonbyck@gmail.com".freeze]
  s.homepage = "https://github.com/jbyck/rack-attack-rate-limit".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.2.2".freeze
  s.summary = "Add RateLimit headers for Rack::Attack throttling".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
end
