# frozen_string_literal: true

# Copyright (c) 2018-2024 The Ruby Citation File Format Developers.
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

require_relative 'util'
require_relative 'model_part'
require_relative 'entity'
require_relative 'identifier'
require_relative 'licensable'
require_relative 'person'
require_relative 'reference'
require_relative 'schema'
require_relative 'validatable'
require_relative 'citable'

##
module CFF
  # Index is the core data structure for a CITATION.cff file. It can be
  # accessed direcly, or via File.
  #
  # Index implements all of the fields listed in the
  # [CFF standard](https://citation-file-format.github.io/). Complex
  # fields - `authors`, `contact`, `identifiers`, `keywords`,
  # `preferred-citation`, `references` and `type` - are documented below. All
  # other fields are simple strings and can be set as such. A field which has
  # not been set will return the empty string. The simple fields are (with
  # defaults in parentheses):
  #
  # * `abstract`
  # * `cff_version`
  # * `commit`
  # * `date_released` - *Note:* returns a `Date` object
  # * `doi`
  # * `license`
  # * `license_url`
  # * `message` (If you use this software in your work, please cite it using
  # the following metadata)
  # * `repository`
  # * `repository_artifact`
  # * `repository_code`
  # * `title`
  # * `url`
  # * `version`
  class Index < ModelPart
    include Citable
    include Licensable
    include Validatable

    ALLOWED_FIELDS = SCHEMA_FILE['properties'].keys.freeze # :nodoc:

    # The allowed CFF [types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#type).
    MODEL_TYPES = SCHEMA_FILE['properties']['type']['enum'].dup.freeze

    # The default message to use if none is explicitly set.
    DEFAULT_MESSAGE = 'If you use this software in your work, please cite ' \
                      'it using the following metadata'

    attr_date :date_released

    # :call-seq:
    #   new(title) -> Index
    #   new(title) { |index| block } -> Index
    #
    # Initialize a new Index with the supplied title.
    def initialize(param)
      super()

      if param.is_a?(Hash)
        @fields = build_index(param)
      else
        @fields = {}
        @fields['cff-version'] = DEFAULT_SPEC_VERSION
        @fields['message'] = DEFAULT_MESSAGE
        @fields['title'] = param
      end

      %w[authors contact identifiers keywords references].each do |field|
        @fields[field] = [] if @fields[field].nil? || @fields[field].empty?
      end

      yield self if block_given?
    end

    # :call-seq:
    #   read(String) -> Index
    #
    # Read a CFF Index from a String and parse it for subsequent manipulation.
    def self.read(index)
      new(Util.parse_yaml(index))
    end

    # :call-seq:
    #   open(String) -> Index
    #   open(String) { |cff| block } -> Index
    #
    # With no associated block, Index.open is a synonym for ::read. If the
    # optional code block is given, it will be passed the parsed index as an
    # argument and the Index will be returned when the block terminates.
    def self.open(index)
      cff = Index.read(index)

      yield cff if block_given?

      cff
    end

    # :call-seq:
    #   type = type
    #
    # Sets the type of this CFF Index. The type is currently restricted to one
    # of `software` or `dataset`. If this field is not set then you should
    # assume that the type is `software`.
    def type=(type)
      type = type.downcase
      @fields['type'] = type if MODEL_TYPES.include?(type)
    end

    def to_yaml # :nodoc:
      YAML.dump fields, line_width: -1, indentation: 2
    end

    private

    def fields
      %w[authors contact identifiers references].each do |field|
        Util.normalize_modelpart_array!(@fields[field])
      end

      Util.fields_to_hash(@fields)
    end

    def build_index(fields) # rubocop:disable Metrics
      Util.build_actor_collection!(fields['authors'] || [])
      Util.build_actor_collection!(fields['contact'] || [])
      (fields['identifiers'] || []).map! do |i|
        Identifier.new(i)
      end
      (fields['references'] || []).map! do |r|
        Reference.new(r)
      end
      fields['preferred-citation'] &&=
        Reference.new(fields['preferred-citation'])

      # Only attempt an update of the `cff-version` field if it is present.
      fields['cff-version'] &&= Util.update_cff_version(fields['cff-version'])

      fields
    end

    public

    # Some documentation of "hidden" methods is provided here, out of the
    # way of the main class code.

    ##
    # :method: authors
    # :call-seq:
    #   authors -> Array
    #
    # Return the list of authors for this citation. To add an author to the
    # list, use:
    #
    # ```
    # index.authors << author
    # ```
    #
    # Authors can be a Person or Entity.

    ##
    # :method: authors=
    # :call-seq:
    #   authors = array_of_authors -> Array
    #
    # Replace the list of authors for this citation.
    #
    # Authors can be a Person or Entity.

    ##
    # :method: contact
    # :call-seq:
    #   contact -> Array
    #
    # Return the list of contacts for this citation. To add a contact to the
    # list, use:
    #
    # ```
    # index.contact << contact
    # ```
    #
    # Contacts can be a Person or Entity.

    ##
    # :method: contact=
    # :call-seq:
    #   contact = array_of_contacts -> Array
    #
    # Replace the list of contacts for this citation.
    #
    # Contacts can be a Person or Entity.

    ##
    # :method: identifiers
    # :call-seq:
    #   identifiers -> Array
    #
    # Return the list of identifiers for this citation. To add a identifier to
    # the list, use:
    #
    # ```
    # index.identifiers << identifier
    # ```

    ##
    # :method: identifiers=
    # :call-seq:
    #   identifiers = array_of_identifiers -> Array
    #
    # Replace the list of identifiers for this citation.

    ##
    # :method: keywords
    # :call-seq:
    #   keywords -> Array
    #
    # Return the list of keywords for this citation. To add a keyword to the
    # list, use:
    #
    # ```
    # index.keywords << keyword
    # ```
    #
    # Keywords will be converted to Strings on output.

    ##
    # :method: keywords=
    # :call-seq:
    #   keywords = array_of_keywords -> Array
    #
    # Replace the list of keywords for this citation.
    #
    # Keywords will be converted to Strings on output.

    ##
    # :method: preferred_citation
    # :call-seq:
    #   preferred_citation -> Reference
    #
    # Return the preferred citation for this citation.

    ##
    # :method: preferred_citation=
    # :call-seq:
    #   preferred_citation = Reference
    #
    # Replace the preferred citation for this citation.

    ##
    # :method: references
    # :call-seq:
    #   references -> Array
    #
    # Return the list of references for this citation. To add a reference to the
    # list, use:
    #
    # ```
    # index.references << reference
    # ```

    ##
    # :method: references=
    # :call-seq:
    #   references = array_of_references -> Array
    #
    # Replace the list of references for this citation.
  end
end
