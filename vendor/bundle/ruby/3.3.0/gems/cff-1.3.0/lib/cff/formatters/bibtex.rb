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

require_relative 'formatter'

##
module CFF
  module Formatters # :nodoc:
    # Generates an BibTeX citation string
    class BibTeX < Formatter # :nodoc:
      # Fields without `!` have a simple one-to-one mapping between CFF and
      # BibTeX. Those with `!` call out to a more complex getter.
      ENTRY_TYPE_MAP = {
        'article' => %w[doi journal note! number! pages! volume],
        'book' => %w[address! doi editor! isbn number! pages! publisher! volume],
        'booklet' => %w[address! doi],
        'inproceedings' => %w[address! booktitle! doi editor! pages! publisher! series!],
        'manual' => %w[address! doi],
        'mastersthesis' => %w[address! doi school! type!],
        'misc' => %w[doi pages!],
        'phdthesis' => %w[address! doi school! type!],
        'proceedings' => %w[address! booktitle! doi editor! pages! publisher! series!],
        'software' => %w[doi license version],
        'techreport' => %w[address! doi institution! number!],
        'unpublished' => %w[doi note!]
      }.freeze

      # Convert months to three letter abbreviations, as per
      # https://www.bibtex.com/f/month-field/. Need to downcase from the
      # built-in set.
      MONTHS_MAP = Date::ABBR_MONTHNAMES.map do |month|
        month.downcase unless month.nil?
      end.freeze

      # We need to escape these characters in titles and names, as per
      # https://tex.stackexchange.com/questions/34580/escape-character-in-latex
      ESCAPE_CHARS = Regexp.new(/([&%$#_{}])/)

      def self.format(model:, preferred_citation: true) # rubocop:disable Metrics
        model = select_and_check_model(model, preferred_citation)
        return if model.nil?

        values = {}
        values['author'] = actor_list(model.authors)
        values['title'] = "{#{l(model.title)}}"

        publication_type = bibtex_type(model)
        publication_data_from_model(model, publication_type, values)

        month, year = month_and_year_from_model(model)
        values['month'] = MONTHS_MAP[month.to_i] unless month.empty?
        values['year'] = year

        values['url'] = url(model)

        values['note'] ||= model.notes unless model.is_a?(Index)

        values.reject! { |_, v| v.empty? }
        sorted_values = values.sort.map do |key, value|
          value = "{#{value}}" unless key == 'month'
          "#{key} = #{value}"
        end
        sorted_values.insert(0, generate_citekey(values))

        "@#{publication_type}{#{sorted_values.join(",\n")}\n}"
      end

      # Get various bits of information about the reference publication.
      # Reference: https://www.bibtex.com/format/
      def self.publication_data_from_model(model, type, fields)
        ENTRY_TYPE_MAP[type].each do |field|
          if model.respond_to?(field)
            fields[field] = l(model.send(field).to_s)
          else
            field = field.chomp('!')
            fields[field] = send("#{field}_from_model", model)
          end
        end
      end

      # BibTeX 'number' is CFF 'issue'.
      def self.number_from_model(model)
        model.issue.to_s
      end

      # BibTeX 'address' is taken from the publisher (book, others) or the
      # conference (inproceedings).
      def self.address_from_model(model)
        entity = if model.type == 'conference-paper'
                   model.conference
                 else
                   model.publisher
                 end
        return '' if entity.empty?

        [entity.city, entity.region, entity.country].reject(&:empty?).join(', ')
      end

      # BibTeX 'institution' could be grabbed from an author's affiliation, or
      # provided explicitly.
      def self.institution_from_model(model)
        return l(model.institution.name) unless model.institution.empty?

        l(model.authors.first.affiliation)
      end

      # BibTeX 'school' is CFF 'institution'.
      def self.school_from_model(model)
        institution_from_model(model)
      end

      # BibTeX 'type' for theses is CFF 'thesis-type'.
      def self.type_from_model(model)
        model.thesis_type
      end

      # BibTeX 'booktitle' is CFF 'collection-title'.
      def self.booktitle_from_model(model)
        l(model.collection_title)
      end

      # BibTeX 'editor' is CFF 'editors' or 'editors-series'.
      def self.editor_from_model(model)
        if model.editors.empty?
          model.editors_series.empty? ? '' : actor_list(model.editors_series)
        else
          actor_list(model.editors)
        end
      end

      def self.publisher_from_model(model)
        model.publisher.empty? ? '' : l(model.publisher.name)
      end

      def self.series_from_model(model)
        model.conference.empty? ? '' : l(model.conference.name)
      end

      # If we're citing a conference paper, try and use the date of the
      # conference. Otherwise use the specified month and year, or the date
      # of release.
      def self.month_and_year_from_model(model)
        if model.type == 'conference-paper' && !model.conference.empty?
          date = model.conference.date_start
          return month_and_year_from_date(date) unless date == ''
        end

        super
      end

      # Do what we can to map between CFF reference types and bibtex types.
      # References:
      #  * https://www.bibtex.com/e/entry-types/
      #  * https://ctan.gutenberg.eu.org/macros/latex/contrib/biblatex-contrib/biblatex-software/software-biblatex.pdf
      def self.bibtex_type(model) # rubocop:disable Metrics/CyclomaticComplexity
        return 'software' if model.type.empty? || model.type.include?('software')

        case model.type
        when 'article', 'book', 'manual', 'unpublished', 'phdthesis', 'mastersthesis'
          model.type
        when 'conference', 'proceedings'
          'proceedings'
        when 'conference-paper'
          'inproceedings'
        when 'magazine-article', 'newspaper-article'
          'article'
        when 'pamphlet'
          'booklet'
        when 'report'
          'techreport'
        else
          'misc'
        end
      end

      def self.format_actor(author) # rubocop:disable Metrics/AbcSize
        return "{#{l(author.name)}}" if author.is_a?(Entity)
        return l(author.alias) if author.family_names.empty? && author.given_names.empty?

        particle =
          author.name_particle.empty? ? '' : "#{author.name_particle} "

        [
          "#{particle}#{author.family_names}",
          author.name_suffix,
          author.given_names
        ].reject(&:empty?).join(', ')
      end

      def self.actor_list(actors)
        actors.map { |actor| format_actor(actor) }.join(' and ')
      end

      def self.generate_citekey(fields)
        reference = [
          fields['author'].split(',', 2)[0],
          fields['title'].split[0..2],
          fields['year']
        ].compact.join('_')

        Util.parameterize(reference)
      end

      # Escape a string to preserve special characters in LaTeX output.
      # Used in many places, so short method name to preserve reading flow.
      def self.l(string)
        string.gsub(ESCAPE_CHARS, '\\\\\1')
      end
    end
  end
end
