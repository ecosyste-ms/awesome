# -*- encoding: utf-8 -*-
# stub: pghero 3.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "pghero".freeze
  s.version = "3.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2024-10-15"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/pghero".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.5.16".freeze
  s.summary = "A performance dashboard for Postgres".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.1".freeze])
end
