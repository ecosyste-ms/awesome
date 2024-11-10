# -*- encoding: utf-8 -*-
# stub: appsignal 4.1.3 ruby lib ext
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "appsignal".freeze
  s.version = "4.1.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/appsignal/appsignal-ruby/issues", "changelog_uri" => "https://github.com/appsignal/appsignal-ruby/blob/main/CHANGELOG.md", "documentation_uri" => "https://docs.appsignal.com/ruby/", "homepage_uri" => "https://docs.appsignal.com/ruby/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/appsignal/appsignal-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze, "ext".freeze]
  s.authors = ["Robert Beekman".freeze, "Thijs Cadier".freeze, "Tom de Bruijn".freeze]
  s.date = "2024-11-07"
  s.description = "The official appsignal.com gem".freeze
  s.email = ["support@appsignal.com".freeze]
  s.executables = ["appsignal".freeze]
  s.extensions = ["ext/extconf.rb".freeze]
  s.files = ["bin/appsignal".freeze, "ext/extconf.rb".freeze]
  s.homepage = "https://github.com/appsignal/appsignal-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Logs performance and exception data from your app to appsignal.com".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<logger>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.64.1".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0.9.20".freeze])
end
