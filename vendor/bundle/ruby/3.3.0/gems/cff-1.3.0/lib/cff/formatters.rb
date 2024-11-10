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

##
module CFF
  # A registry of output formatters for converting CFF files into citations.
  module Formatters
    @formatters = {}

    # :call-seq:
    #   formatters -> Array
    #
    # Return the list of formatters that are available.
    def self.formatters
      @formatters.keys
    end

    # :call-seq:
    #   register_formatter(class)
    #
    # Register a citation formatter. To be registered as a formatter, a
    # class should at least provide the following class methods:
    #
    # * `format`, which takes the model to be formatted
    # as a named parameter, and the option to cite a CFF file's
    # `preferred-citation`:
    # ```ruby
    # def self.format(model:, preferred_citation: true); end
    # ```
    # * `label`, which returns a short name for the formatter, e.g.
    # `'BibTeX'`. If your formatter class subclasses `CFF::Formatter`,
    # then `label` is provided for you.
    def self.register_formatter(clazz)
      return unless clazz.singleton_methods.include?(:format)
      return if @formatters.has_value?(clazz)

      format = clazz.label.downcase.to_sym
      @formatters[format] = clazz
      Citable.add_to_format_method(format) if defined?(Citable)
    end

    def self.formatter_for(format) # :nodoc:
      @formatters[format.downcase.to_sym]
    end
  end
end

require_relative 'formatters/all'
