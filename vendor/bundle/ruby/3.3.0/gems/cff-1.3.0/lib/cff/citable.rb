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

require_relative 'formatters'

##
module CFF
  # Methods to enable turning a CFF model or file into a citation.
  #
  # The core functionality is in the `citation` method. In addition, each
  # available output format has a `to_{format}` method generated for it as
  # well, e.g. `to_bibtex` or `to_apalike`. These methods take a single
  # parameter, `preferred_citation:`, which defaults to `true` as in the
  # `citation` method.
  module Citable
    # :call-seq:
    #   citation(format, preferred_citation: true) -> String
    #
    # Output this Index in the specified format. Setting
    # `preferred_citation: true` will honour the `preferred_citation` field in
    # the index if one is present (default).
    #
    # `format` can be supplied as a String or a Symbol.
    #
    # Formats that are built-in to Ruby CFF are:
    #
    # * APAlike (e.g. `:apalike`, `'apalike'` or `'APAlike'`)
    # * BibTeX (e.g. `:bibtex`, `'bibtex'` or `'BibTeX'`)
    #
    # *Note:* This method assumes that this Index is valid when called.
    def citation(format, preferred_citation: true)
      formatter = Formatters.formatter_for(format)
      return '' if formatter.nil?

      formatter.format(model: self, preferred_citation: preferred_citation)
    end

    def self.add_to_format_method(format) # :nodoc:
      method = "to_#{format}"
      return if method_defined?(method)

      class_eval(
        # def to_bibtex(preferred_citation: true)
        #   citation(:bibtex, preferred_citation: preferred_citation)
        # end
        <<-END_TO_FORMAT, __FILE__, __LINE__ + 1
          def #{method}(preferred_citation: true)
            citation(:#{format}, preferred_citation: preferred_citation)
          end
        END_TO_FORMAT
      )
    end

    # Add the formatters we know about already upfront.
    Formatters.formatters.each do |format|
      add_to_format_method(format)
    end
  end
end
