# -*- encoding: utf-8 -*-
# stub: chronic_duration 0.10.6 ruby lib

Gem::Specification.new do |s|
  s.name = "chronic_duration".freeze
  s.version = "0.10.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["hpoydar".freeze]
  s.date = "2014-09-08"
  s.description = "A simple Ruby natural language parser for elapsed time. (For example, 4 hours and 30 minutes, 6 minutes 4 seconds, 3 days, etc.) Returns all results in seconds. Will return an integer unless you get tricky and need a float. (4 minutes and 13.47 seconds, for example.) The reverse can also be performed via the output method.".freeze
  s.email = ["henry@poydar.com".freeze]
  s.homepage = "https://github.com/hpoydar/chronic_duration".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.2.2".freeze
  s.summary = "A simple Ruby natural language parser for elapsed time".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<numerizer>.freeze, ["~> 0.1.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.12.0".freeze])
end
