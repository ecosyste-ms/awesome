# -*- encoding: utf-8 -*-
# stub: rswag-api 2.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rswag-api".freeze
  s.version = "2.15.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Richie Morris".freeze, "Greg Myers".freeze, "Jay Danielian".freeze]
  s.date = "2024-10-04"
  s.description = "Open up your API to the phenomenal OpenAPI ecosystem by exposing OpenAPI files, that describe your service, as JSON endpoints. More about the OpenAPI initiative here: http://spec.openapis.org/".freeze
  s.email = ["domaindrivendev@gmail.com".freeze]
  s.homepage = "https://github.com/rswag/rswag".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.11".freeze
  s.summary = "A Rails Engine that exposes OpenAPI (formerly called Swagger) files as JSON endpoints".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze, "< 8.0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2".freeze, "< 8.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["= 0.21.2".freeze])
end
