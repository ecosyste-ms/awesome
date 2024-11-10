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

require_relative 'formatter'

##
module CFF
  module Formatters # :nodoc:
    # Generates an APALIKE citation string
    class APALike < Formatter # :nodoc:
      def self.format(model:, preferred_citation: true) # rubocop:disable Metrics/AbcSize
        model = select_and_check_model(model, preferred_citation)
        return if model.nil?

        output = []
        output << combine_authors(
          model.authors.map { |author| format_author(author) }
        )

        date = month_and_year_from_model(model)
        output << "(#{date})" unless date.empty?

        version = " (Version #{model.version})" unless model.version.to_s.empty?
        output << "#{model.title}#{version}#{type_label(model)}"
        output << publication_data_from_model(model)
        output << url(model)

        output.reject(&:empty?).join('. ')
      end

      def self.publication_data_from_model(model) # rubocop:disable Metrics
        case model.type
        when 'article'
          [
            model.journal,
            volume_from_model(model),
            pages_from_model(model, dash: '–'),
            note_from_model(model) || ''
          ].reject(&:empty?).join(', ')
        when 'book'
          model.publisher.empty? ? '' : model.publisher.name
        when 'conference-paper'
          [
            model.collection_title,
            volume_from_model(model),
            pages_from_model(model, dash: '–')
          ].reject(&:empty?).join(', ')
        when 'report'
          if model.institution.empty?
            model.authors.first.affiliation
          else
            model.institution.name
          end
        when 'phdthesis'
          type_and_school_from_model(model, 'Doctoral dissertation')
        when 'mastersthesis'
          type_and_school_from_model(model, "Master's thesis")
        when 'unpublished'
          note_from_model(model) || ''
        else
          ''
        end
      end

      def self.type_and_school_from_model(model, type)
        type = model.thesis_type == '' ? type : model.thesis_type
        school = model.institution.empty? ? model.authors.first.affiliation : model.institution.name
        "[#{type}, #{school}]"
      end

      def self.volume_from_model(model)
        issue = model.issue.to_s.empty? ? '' : "(#{model.issue})"
        model.volume.to_s.empty? ? '' : "#{model.volume}#{issue}"
      end

      # If we're citing a conference paper, try and use the date of the
      # conference. Otherwise use the specified month and year, or the date
      # of release.
      def self.month_and_year_from_model(model)
        if model.type == 'conference-paper' && !model.conference.empty?
          start = model.conference.date_start
          unless start == ''
            finish = model.conference.date_end
            return month_and_year_from_date(start)[1] if finish == '' || start >= finish

            return date_range(start, finish)
          end
        end

        super[1]
      end

      def self.date_range(start, finish)
        start_str = '%Y, %B %-d'
        finish_str = '%-d'
        finish_str = "%B #{finish_str}" unless start.month == finish.month
        finish_str = "%Y, #{finish_str}" unless start.year == finish.year

        "#{start.strftime(start_str)}–#{finish.strftime(finish_str)}"
      end

      # Prefer a DOI over the other URI options.
      def self.url(model)
        model.doi.empty? ? super : "https://doi.org/#{model.doi}"
      end

      def self.type_label(model)
        return ' [Data set]' if model.type.include?('data')
        return ' [Conference paper]' if model.type.include?('conference')
        return '' if model.is_a?(Reference) && !model.type.include?('software')

        ' [Computer software]'
      end

      def self.combine_authors(authors)
        return authors[0].chomp('.') if authors.length == 1

        "#{authors[0..-2].join(', ')}, & #{authors[-1]}".chomp('.')
      end

      def self.format_author(author)
        return author.name if author.is_a?(Entity)

        particle =
          author.name_particle.empty? ? '' : "#{author.name_particle} "
        suffix = author.name_suffix.empty? ? '' : ", #{author.name_suffix}"

        "#{particle}#{format_name(author)}#{suffix}"
      end

      # Format a name using an alias if needs be.
      # https://blog.apastyle.org/apastyle/2012/02/how-to-cite-pseudonyms.html
      def self.format_name(author)
        if author.family_names.empty?
          if author.given_names.empty?
            author.alias
          else
            author.given_names
          end
        elsif author.given_names.empty?
          author.family_names
        else
          "#{author.family_names}, #{initials(author.given_names)}."
        end
      end
    end
  end
end
