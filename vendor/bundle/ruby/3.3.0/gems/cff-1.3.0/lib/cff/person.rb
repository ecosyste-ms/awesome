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

require_relative 'model_part'
require_relative 'schema'

##
module CFF
  # A Person represents a person in a CITATION.cff file. A Person might have a
  # number of roles, such as author, contact, editor, etc.
  #
  # Person implements all of the fields listed in the
  # [CFF standard](https://citation-file-format.github.io/). All fields
  # are simple strings and can be set as such. A field which has not been set
  # will return the empty string. The simple fields are (with defaults in
  # parentheses):
  #
  # * `address`
  # * `affiliation`
  # * `alias`
  # * `city`
  # * `country`
  # * `email`
  # * `family_names`
  # * `fax`
  # * `given_names`
  # * `name_particle`
  # * `name_suffix`
  # * `orcid`
  # * `post_code`
  # * `region`
  # * `tel`
  # * `website`
  class Person < ModelPart
    ALLOWED_FIELDS = SCHEMA_FILE['definitions']['person']['properties'].keys.freeze # :nodoc:

    # :call-seq:
    #   new -> Person
    #   new { |person| block } -> Person
    #   new(given_name, family_name) -> Person
    #   new(given_name, family_name) { |person| block } -> Person
    #
    # Create a new Person with the optionally supplied given and family names.
    def initialize(param = nil, *more)
      super()

      if param.is_a?(Hash)
        @fields = param
      else
        @fields = {}

        unless param.nil?
          @fields['family-names'] = more[0]
          @fields['given-names'] = param
        end
      end

      yield self if block_given?
    end
  end
end
