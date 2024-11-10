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

require 'bundler/gem_tasks'
require 'minitest/test_task'
require 'rdoc/task'
require 'rubocop/rake_task'

task default: :test

Minitest::TestTask.create do |test|
  test.test_globs = 'test/**/*_test.rb'
end

RDoc::Task.new do |r|
  r.main = 'README.md'
  r.rdoc_files.include(
    'README.md', 'LICENCE', 'CODE_OF_CONDUCT.md', 'CONTRIBUTING.md',
    'CHANGES.md', 'lib/**/*.rb'
  )
  r.options << '--markup=markdown'
  r.options << '--tab-width=2'
  r.options << "-t Ruby CFF Library (version #{::CFF::VERSION})"
end

RuboCop::RakeTask.new
