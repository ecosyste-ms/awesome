# -*- encoding: utf-8 -*-
# stub: sidekiq-unique-jobs 8.0.10 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq-unique-jobs".freeze
  s.version = "8.0.10".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikael Henriksson".freeze]
  s.date = "2024-02-22"
  s.description = "Prevents simultaneous Sidekiq jobs with the same unique arguments to run.\nHighly configurable to suite your specific needs.\n".freeze
  s.email = ["mikael@mhenrixon.com".freeze]
  s.executables = ["uniquejobs".freeze]
  s.files = ["bin/uniquejobs".freeze]
  s.homepage = "https://github.com/mhenrixon/sidekiq-unique-jobs".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.5.6".freeze
  s.summary = "Sidekiq middleware that prevents duplicates jobs".freeze

  s.installed_by_version = "3.5.16".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze, ">= 1.0.5".freeze])
  s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 7.0.0".freeze, "< 8.0.0".freeze])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 1.0".freeze, "< 3.0".freeze])
end
