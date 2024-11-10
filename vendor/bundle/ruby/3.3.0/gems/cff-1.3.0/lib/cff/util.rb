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

require_relative 'entity'
require_relative 'person'
require_relative 'version'

require 'rubygems'
require 'yaml'

##
module CFF
  # Util provides utility methods useful throughout the rest of the CFF library.
  #
  # Util does not provide any methods or fields for the public API.
  module Util
    # :stopdoc:

    module_function

    def parse_yaml(string)
      YAML.safe_load(string, aliases: true, permitted_classes: [Date, Time])
    end

    def update_cff_version(version)
      return '' if version.nil? || version.empty?

      if Gem::Version.new(version) < Gem::Version.new(MIN_VALIDATABLE_VERSION)
        MIN_VALIDATABLE_VERSION
      else
        version
      end
    end

    # Currently need to make some sort of guess as to whether an actor
    # is a Person or Entity. This isn't perfect, but works 99.99% I think.
    def build_actor_collection!(source)
      source.map! do |s|
        next s if s.is_a?(Person) || s.is_a?(Entity)

        s.has_key?('name') ? Entity.new(s) : Person.new(s)
      end
    end

    def normalize_modelpart_array!(array)
      array.select! { |i| i.respond_to?(:fields) }
    end

    def fields_to_hash(fields)
      hash = {}

      fields.each do |field, value|
        if value.respond_to?(:map)
          unless value.empty?
            hash[field] = value.map do |v|
              v.respond_to?(:fields) ? v.fields : v.to_s
            end
          end
        else
          hash[field] = value.respond_to?(:fields) ? value.fields : value
        end
      end

      hash
    end

    DEFAULT_CHAR_APPROXIMATIONS = {
      'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Ä' => 'A', 'Å' => 'A',
      'Æ' => 'AE', 'Ç' => 'C', 'È' => 'E', 'É' => 'E', 'Ê' => 'E', 'Ë' => 'E',
      'Ì' => 'I', 'Í' => 'I', 'Î' => 'I', 'Ï' => 'I', 'Ð' => 'D', 'Ñ' => 'N',
      'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O', '×' => 'x',
      'Ø' => 'O', 'Ù' => 'U', 'Ú' => 'U', 'Û' => 'U', 'Ü' => 'U', 'Ý' => 'Y',
      'Þ' => 'Th', 'ß' => 'ss', 'à' => 'a', 'á' => 'a', 'â' => 'a',
      'ã' => 'a', 'ä' => 'a', 'å' => 'a', 'æ' => 'ae', 'ç' => 'c', 'è' => 'e',
      'é' => 'e', 'ê' => 'e', 'ë' => 'e', 'ì' => 'i', 'í' => 'i', 'î' => 'i',
      'ï' => 'i', 'ð' => 'd', 'ñ' => 'n', 'ò' => 'o', 'ó' => 'o', 'ô' => 'o',
      'õ' => 'o', 'ö' => 'o', 'ø' => 'o', 'ù' => 'u', 'ú' => 'u', 'û' => 'u',
      'ü' => 'u', 'ý' => 'y', 'þ' => 'th', 'ÿ' => 'y', 'Ā' => 'A', 'ā' => 'a',
      'Ă' => 'A', 'ă' => 'a', 'Ą' => 'A', 'ą' => 'a', 'Ć' => 'C', 'ć' => 'c',
      'Ĉ' => 'C', 'ĉ' => 'c', 'Ċ' => 'C', 'ċ' => 'c', 'Č' => 'C', 'č' => 'c',
      'Ď' => 'D', 'ď' => 'd', 'Đ' => 'D', 'đ' => 'd', 'Ē' => 'E', 'ē' => 'e',
      'Ĕ' => 'E', 'ĕ' => 'e', 'Ė' => 'E', 'ė' => 'e', 'Ę' => 'E', 'ę' => 'e',
      'Ě' => 'E', 'ě' => 'e', 'ệ' => 'e', 'Ĝ' => 'G', 'ĝ' => 'g', 'Ğ' => 'G',
      'ğ' => 'g', 'Ġ' => 'G', 'ġ' => 'g', 'Ģ' => 'G', 'ģ' => 'g', 'Ĥ' => 'H',
      'ĥ' => 'h', 'Ħ' => 'H', 'ħ' => 'h', 'Ĩ' => 'I', 'ĩ' => 'i', 'Ī' => 'I',
      'ī' => 'i', 'Ĭ' => 'I', 'ĭ' => 'i', 'Į' => 'I', 'į' => 'i', 'İ' => 'I',
      'ı' => 'i', 'Ĳ' => 'IJ', 'ĳ' => 'ij', 'Ĵ' => 'J', 'ĵ' => 'j',
      'Ķ' => 'K', 'ķ' => 'k', 'ĸ' => 'k', 'Ĺ' => 'L', 'ĺ' => 'l', 'Ļ' => 'L',
      'ļ' => 'l', 'Ľ' => 'L', 'ľ' => 'l', 'Ŀ' => 'L', 'ŀ' => 'l', 'Ł' => 'L',
      'ł' => 'l', 'Ń' => 'N', 'ń' => 'n', 'Ņ' => 'N', 'ņ' => 'n', 'Ň' => 'N',
      'ň' => 'n', 'ŉ' => "'n", 'Ŋ' => 'NG', 'ŋ' => 'ng', 'Ō' => 'O',
      'ō' => 'o', 'Ŏ' => 'O', 'ŏ' => 'o', 'Ő' => 'O', 'ő' => 'o', 'Œ' => 'OE',
      'œ' => 'oe', 'Ŕ' => 'R', 'ŕ' => 'r', 'Ŗ' => 'R', 'ŗ' => 'r', 'Ř' => 'R',
      'ř' => 'r', 'Ś' => 'S', 'ś' => 's', 'Ŝ' => 'S', 'ŝ' => 's', 'Ş' => 'S',
      'ş' => 's', 'Š' => 'S', 'š' => 's', 'Ţ' => 'T', 'ţ' => 't', 'Ť' => 'T',
      'ť' => 't', 'Ŧ' => 'T', 'ŧ' => 't', 'Ũ' => 'U', 'ũ' => 'u', 'Ū' => 'U',
      'ū' => 'u', 'Ŭ' => 'U', 'ŭ' => 'u', 'Ů' => 'U', 'ů' => 'u', 'Ű' => 'U',
      'ű' => 'u', 'Ų' => 'U', 'ų' => 'u', 'Ŵ' => 'W', 'ŵ' => 'w', 'Ŷ' => 'Y',
      'ŷ' => 'y', 'Ÿ' => 'Y', 'Ź' => 'Z', 'ź' => 'z', 'Ż' => 'Z', 'ż' => 'z',
      'Ž' => 'Z', 'ž' => 'z'
    }.freeze

    def transliterate(string, fallback: '')
      string.gsub(/[^\x00-\x7f]/u) do |char|
        DEFAULT_CHAR_APPROXIMATIONS[char] || fallback
      end
    end

    def parameterize(string, separator: '_')
      # Normalize into ASCII.
      param = transliterate(string)

      # Remove unwanted chars by turning them into the separator.
      param.gsub!(/[^a-z0-9\-_]+/i, separator)

      # Only one separator at a time.
      param.gsub!(/#{separator}{2,}/, separator)

      # No leading/trailing separators.
      param.gsub(/^#{separator}|#{separator}$/i, '')
    end

    # :startdoc:
  end
end
