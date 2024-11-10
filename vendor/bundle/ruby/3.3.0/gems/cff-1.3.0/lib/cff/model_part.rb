# frozen_string_literal: true

# Copyright (c) 2018-2023 The Ruby Citation File Format Developers.
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

require 'date'

##
module CFF
  # ModelPart is the superclass of anything that makes up part of the CFF Index.
  # This includes Index, Person, Entity and Reference.
  #
  # ModelPart provides only one method for the public API: `empty?`.
  class ModelPart
    # :stopdoc:
    attr_reader :fields

    def method_missing(name, *args)
      n = method_to_field(name.id2name)
      super unless self.class::ALLOWED_FIELDS.include?(n.chomp('='))

      if n.end_with?('=')
        @fields[n.chomp('=')] = args[0] || ''
      else
        @fields[n].nil? ? '' : @fields[n]
      end
    end

    def respond_to_missing?(name, *)
      n = method_to_field(name.id2name)
      self.class::ALLOWED_FIELDS.include?(n.chomp('=')) || super
    end
    # :startdoc:

    # :call-seq:
    #   empty? -> false
    #
    # Define `empty?` for CFF classes so that they can be tested in the
    # same way as strings and arrays.
    #
    # This always returns `false` because CFF classes always return something
    # from all of their methods.
    def empty?
      false
    end

    def self.attr_date(*symbols) # :nodoc:
      symbols.each do |symbol|
        field = symbol.to_s.tr('_', '-')

        date_getter(symbol, field)
        date_setter(symbol, field)
      end
    end

    def self.date_getter(symbol, field)
      class_eval(
        # def date_end
        #   date = @fields['date-end']
        #   return date if date.is_a?(Date)
        #
        #   begin
        #     Date.parse(date)
        #   rescue
        #     ''
        #   end
        # end
        <<-END_GETTER, __FILE__, __LINE__ + 1
          def #{symbol}
            date = @fields['#{field}']
            return date if date.is_a?(Date)

            begin
              Date.parse(date)
            rescue
              ''
            end
          end
        END_GETTER
      )
    end

    def self.date_setter(symbol, field)
      class_eval(
        # def date_end=(date)
        #   date = (date.is_a?(Date) ? date.dup : Date.parse(date))
        #
        #   @fields['date-end'] = date
        # end
        <<-END_SETTER, __FILE__, __LINE__ + 1
          def #{symbol}=(date)
            date = (date.is_a?(Date) ? date.dup : Date.parse(date))

            @fields['#{field}'] = date
          end
        END_SETTER
      )
    end

    private_class_method :date_getter, :date_setter

    private

    def method_to_field(name)
      name.tr('_', '-')
    end
  end
end
