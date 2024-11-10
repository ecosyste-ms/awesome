# -*- encoding: utf-8 -*-
# stub: sidekiq-status 3.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq-status".freeze
  s.version = "3.0.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Evgeniy Tsvigun".freeze, "Kenaniah Cerny".freeze]
  s.date = "2023-05-04"
  s.email = ["utgarda@gmail.com".freeze, "kenaniah@gmail.com".freeze]
  s.homepage = "https://github.com/kenaniah/sidekiq-status".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "An extension to the sidekiq message processing to track your jobs".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 6.0".freeze, "< 8".freeze])
  s.add_runtime_dependency(%q<chronic_duration>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<colorize>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sinatra>.freeze, [">= 0".freeze])
end
