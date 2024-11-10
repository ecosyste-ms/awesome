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

require_relative 'licensable'
require_relative 'model_part'
require_relative 'schema'
require_relative 'util'

##
module CFF
  # Reference provides a reference pertaining to the software version or the
  # software itself, e.g., a software paper describing the abstract concepts of
  # the software, a paper describing an algorithm that has been implemented in
  # the software version, etc.
  #
  # Reference implements all of the fields listed in the
  # [CFF standard](https://citation-file-format.github.io/). Complex
  # fields - `authors`, `contact`, `editors`, `editors_series`, `identifiers`,
  # `keywords`, `languages`, `patent_states`, `recipients`, `senders` and
  # `translators` - are documented below. All other fields are simple strings
  # and can be set as such. A field which has not been set will return the
  # empty string. The simple fields are (with defaults in parentheses):
  #
  # * `abbreviation`
  # * `abstract`
  # * `collection_doi`
  # * `collection_title`
  # * `collection_type`
  # * `commit`
  # * `conference`
  # * `copyright`
  # * `data-type`
  # * `database`
  # * `database_provider`
  # * `date_accessed` - *Note:* returns a `Date` object
  # * `date_downloaded` - *Note:* returns a `Date` object
  # * `date_published` - *Note:* returns a `Date` object
  # * `date_released` - *Note:* returns a `Date` object
  # * `department`
  # * `doi`
  # * `edition`
  # * `end`
  # * `entry`
  # * `filename`
  # * `format`
  # * `institution`
  # * `isbn`
  # * `issn`
  # * `issue`
  # * `issue_date` - *Note:* returns a `Date` object
  # * `issue_title`
  # * `journal`
  # * `license` - *Note:* see documentation for `license =` below
  # * `license_url`
  # * `loc_end`
  # * `loc_start`
  # * `location`
  # * `medium`
  # * `month`
  # * `nihmsid`
  # * `notes`
  # * `number`
  # * `number_volumes`
  # * `pages`
  # * `pmcid`
  # * `publisher`
  # * `repository`
  # * `repository_artifact`
  # * `repository_code`
  # * `scope`
  # * `section`
  # * `start`
  # * `status` - *Note:* see documentation for `status =` below
  # * `term`
  # * `thesis_type`
  # * `title`
  # * `type` - *Note:* see documentation for `type =` below
  # * `url`
  # * `version`
  # * `volume`
  # * `volume_title`
  # * `year`
  # * `year_original`
  class Reference < ModelPart
    include Licensable

    # This list does not include `format` for reasons explained below, where
    # the `format` method is defined!
    ALLOWED_FIELDS = (
      SCHEMA_FILE['definitions']['reference']['properties'].keys - %w[format languages]
    ).freeze # :nodoc:

    # The [defined set of reference types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#definitionsreferencetype).
    REFERENCE_TYPES =
      SCHEMA_FILE['definitions']['reference']['properties']['type']['enum'].dup.freeze

    # The [defined set of reference status types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#definitionsreferencestatus).
    REFERENCE_STATUS_TYPES =
      SCHEMA_FILE['definitions']['reference']['properties']['status']['enum'].dup.freeze

    attr_date :date_accessed, :date_downloaded, :date_published,
              :date_released, :issue_date

    # :call-seq:
    #   new(title) -> Reference
    #   new(title) { |ref| block } -> Reference
    #   new(title, type) -> Reference
    #   new(title, type) { |ref| block } -> Reference
    #
    # Create a new Reference with the supplied title and, optionally, type.
    # If type is not given, or is not one of the
    # [defined set of reference types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#definitionsreferencetype),
    # 'generic' will be used by default.
    def initialize(param, *more) # rubocop:disable Metrics
      super()

      if param.is_a?(Hash)
        @fields = build_model(param)
      else
        @fields = {}
        type = more[0] &&= more[0].downcase
        @fields['type'] = REFERENCE_TYPES.include?(type) ? type : 'generic'
        @fields['title'] = param
      end

      %w[
        authors contact editors editors-series identifiers
        keywords patent-states recipients senders translators
      ].each do |field|
        @fields[field] = [] if @fields[field].nil? || @fields[field].empty?
      end

      yield self if block_given?
    end

    # :call-seq:
    #   from_cff(File, type: 'software') -> Reference
    #   from_cff(Index, type: 'software') -> Reference
    #
    # Create a Reference from another CFF File or Index. This is useful for
    # easily adding a reference to something with its own CITATION.cff file
    # already.
    #
    # This method assumes that the type of the Reference should be `software`,
    # but this can be overridden with the `type` parameter.
    def self.from_cff(model, type: 'software')
      new(model.title, type) do |ref|
        %w[
          abstract authors contact commit date_released doi
          identifiers keywords license license_url repository
          repository_artifact repository_code url version
        ].each do |field|
          value = model.send(field)
          ref.send("#{field}=", value.dup) unless value == ''
        end
      end
    end

    # :call-seq:
    #   add_language language
    #
    # Add a language to this Reference. Input is converted to the ISO 639-3
    # three letter language code, so `GER` becomes `deu`, `french` becomes
    # `fra` and `en` becomes `eng`.
    def add_language(lang)
      require 'language_list'
      @fields['languages'] = [] if @fields['languages'].nil? || @fields['languages'].empty?
      lang = LanguageList::LanguageInfo.find(lang)
      return if lang.nil?

      lang = lang.iso_639_3
      @fields['languages'] << lang unless @fields['languages'].include?(lang)
    end

    # :call-seq:
    #   reset_languages
    #
    # Reset the list of languages for this Reference to be empty.
    def reset_languages
      @fields.delete('languages')
    end

    # :call-seq:
    #   languages -> Array
    #
    # Return the list of languages associated with this Reference.
    def languages
      @fields['languages'].nil? || @fields['languages'].empty? ? [] : @fields['languages'].dup
    end

    # Returns the format of this Reference.
    #
    # This method is explicitly defined to override the private format method
    # that all objects seem to have.
    def format # :nodoc:
      @fields['format'].nil? ? '' : @fields['format']
    end

    # Sets the format of this Reference.
    #
    # This method is explicitly defined to override the private format method
    # that all objects seem to have.
    def format=(fmt) # :nodoc:
      @fields['format'] = fmt
    end

    # :call-seq:
    #   status = status
    #
    # Sets the status of this Reference. The status is restricted to a
    # [defined set of status types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#definitionsreferencestatus).
    def status=(status)
      status = status.downcase
      @fields['status'] = status if REFERENCE_STATUS_TYPES.include?(status)
    end

    # :call-seq:
    #   type = type
    #
    # Sets the type of this Reference. The type is restricted to a
    # [defined set of reference types](https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#definitionsreferencetype).
    def type=(type)
      type = type.downcase
      @fields['type'] = type if REFERENCE_TYPES.include?(type)
    end

    # Override superclass #fields as References contain model parts too.
    def fields # :nodoc:
      %w[
        authors contact editors editors-series identifiers
        recipients senders translators
      ].each do |field|
        Util.normalize_modelpart_array!(@fields[field])
      end

      Util.fields_to_hash(@fields)
    end

    private

    def build_model(fields) # :nodoc:
      %w[
        authors contact editors editors-series recipients senders translators
      ].each do |field|
        Util.build_actor_collection!(fields[field]) if fields.include?(field)
      end

      %w[
        conference database-provider institution location publisher
      ].each do |field|
        fields[field] &&= Entity.new(fields[field])
      end

      (fields['identifiers'] || []).map! do |i|
        Identifier.new(i)
      end

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
    # Return the list of authors for this Reference. To add an author to the
    # list, use:
    #
    # ```
    # reference.authors << author
    # ```
    #
    # Authors can be a Person or Entity.

    ##
    # :method: authors=
    # :call-seq:
    #   authors = array_of_authors -> Array
    #
    # Replace the list of authors for this reference.
    #
    # Authors can be a Person or Entity.

    ##
    # :method: contact
    # :call-seq:
    #   contact -> Array
    #
    # Return the list of contacts for this Reference. To add a contact to the
    # list, use:
    #
    # ```
    # reference.contact << contact
    # ```
    #
    # Contacts can be a Person or Entity.

    ##
    # :method: contact=
    # :call-seq:
    #   contact = array_of_contacts -> Array
    #
    # Replace the list of contacts for this reference.
    #
    # Contacts can be a Person or Entity.

    ##
    # :method: editors
    # :call-seq:
    #   editors -> Array
    #
    # Return the list of editors for this Reference. To add an editor to the
    # list, use:
    #
    # ```
    # reference.editors << editor
    # ```
    #
    # An editor can be a Person or Entity.

    ##
    # :method: editors=
    # :call-seq:
    #   editors = array_of_editors -> Array
    #
    # Replace the list of editors for this reference.
    #
    # Editors can be a Person or Entity.

    ##
    # :method: editors_series
    # :call-seq:
    #   editors_series -> Array
    #
    # Return the list of series editors for this Reference. To add a series
    # editor to the list, use:
    #
    # ```
    # reference.editors_series << editor
    # ```
    #
    # An editor can be a Person or Entity.

    ##
    # :method: editors_series=
    # :call-seq:
    #   editors_series = array_of_series_editors -> Array
    #
    # Replace the list of series editors for this reference.
    #
    # Series editors can be a Person or Entity.

    ##
    # :method: identifiers
    # :call-seq:
    #   identifiers -> Array
    #
    # Return the list of identifiers for this citation. To add a identifier to
    # the list, use:
    #
    # ```
    # reference.identifiers << identifier
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
    # Return the list of keywords for this reference. To add a keyword to the
    # list, use:
    #
    # ```
    # reference.keywords << keyword
    # ```
    #
    # Keywords will be converted to Strings on output.

    ##
    # :method: keywords=
    # :call-seq:
    #   keywords = array_of_keywords -> Array
    #
    # Replace the list of keywords for this reference.
    #
    # Keywords will be converted to Strings on output.

    ##
    # :method: patent_states
    # :call-seq:
    #   patent_states -> Array
    #
    # Return the list of patent states for this reference. To add a patent
    # state to the list, use:
    #
    # ```
    # reference.patent_states << patent_state
    # ```
    #
    # Patent states will be converted to Strings on output.

    ##
    # :method: patent_states=
    # :call-seq:
    #   patent_states = array_of_states -> Array
    #
    # Replace the list of patent states for this reference.
    #
    # Patent states will be converted to Strings on output.

    ##
    # :method: recipients
    # :call-seq:
    #   recipients -> Array
    #
    # Return the list of recipients for this Reference. To add a recipient
    # to the list, use:
    #
    # ```
    # reference.recipients << recipient
    # ```
    #
    # Recipients can be a Person or Entity.

    ##
    # :method: recipients=
    # :call-seq:
    #   recipients = array_of_recipients -> Array
    #
    # Replace the list of recipients for this reference.
    #
    # Recipients can be a Person or Entity.

    ##
    # :method: senders
    # :call-seq:
    #   senders -> Array
    #
    # Return the list of senders for this Reference. To add a sender to the
    # list, use:
    #
    # ```
    # reference.senders << sender
    # ```
    #
    # Senders can be a Person or Entity.

    ##
    # :method: senders=
    # :call-seq:
    #   senders = array_of_senders -> Array
    #
    # Replace the list of senders for this reference.
    #
    # Senders can be a Person or Entity.

    ##
    # :method: translators
    # :call-seq:
    #   translators -> Array
    #
    # Return the list of translators for this Reference. To add a translator
    # to the list, use:
    #
    # ```
    # reference.translators << translator
    # ```
    #
    # Translators can be a Person or Entity.

    ##
    # :method: translators=
    # :call-seq:
    #   translators = array_of_translators -> Array
    #
    # Replace the list of translators for this reference.
    #
    # Translators can be a Person or Entity.
  end
end
