# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "language_list/version"

Gem::Specification.new do |s|
  s.name        = "language_list"
  s.version     = LanguageList::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Steve Smith"]
  s.email       = ["gems@dynedge.co.uk"]
  s.homepage    = "https://github.com/scsmith/language_list"
  s.summary     = %q{A list of languages and methods to find and work with these languages.}
  s.description = %q{A list of languages based upon ISO-639-1 and ISO-639-3 with functions to retrieve only common languages.}

  s.rubyforge_project = "language_list"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency 'minitest', '> 5.0.0'
  s.add_development_dependency 'rake'
end
