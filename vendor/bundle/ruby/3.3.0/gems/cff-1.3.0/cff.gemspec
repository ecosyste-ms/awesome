# frozen_string_literal: true

# Copyright (c) 2018-2022 The Ruby Citation File Format Developers.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'lib/cff/version'

Gem::Specification.new do |spec|
  spec.name          = 'cff'
  spec.version       = CFF::VERSION
  spec.authors       = [
    'Robert Haines',
    'The Ruby Citation File Format Developers'
  ]
  spec.email         = ['robert.haines@manchester.ac.uk']

  spec.summary       = 'A Ruby library for manipulating CITATION.cff files.'
  spec.description   = 'See https://citation-file-format.github.io/ ' \
                       'for more info.'
  spec.homepage      = 'https://github.com/citation-file-format/ruby-cff'
  spec.license       = 'Apache-2.0'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/citation-file-format/ruby-cff/issues',
    'changelog_uri' => 'https://github.com/citation-file-format/ruby-cff/blob/main/CHANGES.md',
    'documentation_uri' => 'https://citation-file-format.github.io/ruby-cff/',
    'source_code_uri' => 'https://github.com/citation-file-format/ruby-cff',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^((test|spec|features)/|\.)})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_runtime_dependency 'json_schema', '~> 0.20.4'
  spec.add_runtime_dependency 'language_list', '~> 1.2.1'

  spec.add_development_dependency 'minitest', '~> 5.16.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rdoc', '~> 6.4.0'
  spec.add_development_dependency 'rubocop', '~> 1.35.0'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.21.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'simplecov', '0.18.3'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.8.0'
  spec.add_development_dependency 'test_construct', '~> 2.0'
end
