# -*- encoding: utf-8 -*-
# stub: cff 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "cff".freeze
  s.version = "1.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/citation-file-format/ruby-cff/issues", "changelog_uri" => "https://github.com/citation-file-format/ruby-cff/blob/main/CHANGES.md", "documentation_uri" => "https://citation-file-format.github.io/ruby-cff/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/citation-file-format/ruby-cff" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Robert Haines".freeze, "The Ruby Citation File Format Developers".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-10-26"
  s.description = "See https://citation-file-format.github.io/ for more info.".freeze
  s.email = ["robert.haines@manchester.ac.uk".freeze]
  s.homepage = "https://github.com/citation-file-format/ruby-cff".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A Ruby library for manipulating CITATION.cff files.".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<json_schema>.freeze, ["~> 0.20.4".freeze])
  s.add_runtime_dependency(%q<language_list>.freeze, ["~> 1.2.1".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.16.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.4.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.35.0".freeze])
  s.add_development_dependency(%q<rubocop-minitest>.freeze, ["~> 0.21.0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.14.0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.6.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["= 0.18.3".freeze])
  s.add_development_dependency(%q<simplecov-lcov>.freeze, ["~> 0.8.0".freeze])
  s.add_development_dependency(%q<test_construct>.freeze, ["~> 2.0".freeze])
end
