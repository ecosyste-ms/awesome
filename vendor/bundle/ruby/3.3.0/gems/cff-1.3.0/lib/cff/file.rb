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

require_relative 'errors'
require_relative 'index'
require_relative 'version'

require 'date'

##
module CFF
  # File provides direct access to a CFF Index, with the addition of some
  # filesystem utilities.
  #
  # To be a fully compliant and valid CFF file its filename should be
  # 'CITATION.cff'. This class allows you to create files with any filename,
  # and to validate the contents of those files independently of the preferred
  # filename.
  class File
    # A comment to be inserted at the top of the resultant CFF file.
    attr_reader :comment

    # The filename of this CFF file.
    attr_reader :filename

    YAML_HEADER = "---\n" # :nodoc:
    CFF_COMMENT = [
      "This CITATION.cff file was created by ruby-cff (v #{CFF::VERSION}).",
      'Gem: https://rubygems.org/gems/cff',
      'CFF: https://citation-file-format.github.io/'
    ].freeze # :nodoc:
    CFF_VALID_FILENAME = 'CITATION.cff' # :nodoc:

    # :call-seq:
    #   new(filename, title) -> File
    #   new(filename, index) -> File
    #
    # Create a new File. Either a pre-existing Index can be passed in or, as
    # with Index itself, a title can be supplied to initalize a new File.
    #
    # All methods provided by Index are also available directly on File
    # objects.
    def initialize(filename, param, comment = CFF_COMMENT, create: false)
      param = Index.new(param) unless param.is_a?(Index)

      @filename = filename
      @index = param
      @comment = comment
      @dirty = create
    end

    # :call-seq:
    #   read(filename) -> File
    #
    # Read a file and parse it for subsequent manipulation.
    def self.read(file)
      content = ::File.read(file)
      comment = File.parse_comment(content)

      new(file, Util.parse_yaml(content), comment)
    end

    # :call-seq:
    #   open(filename) -> File
    #   open(filename) { |cff| block }
    #
    # With no associated block, File.open is a synonym for ::read. If the
    # optional code block is given, it will be passed the opened file as an
    # argument and the File object will automatically be written (if edited)
    # and closed when the block terminates.
    #
    # File.open will create a new file if one does not already exist with the
    # provided file name.
    def self.open(file)
      if ::File.exist?(file)
        content = ::File.read(file)
        comment = File.parse_comment(content)
        yaml = Util.parse_yaml(content)
      else
        comment = CFF_COMMENT
        yaml = ''
      end

      cff = new(file, yaml, comment, create: (yaml == ''))
      return cff unless block_given?

      begin
        yield cff
      ensure
        cff.write
      end
    end

    # :call-seq:
    #   validate(filename, fail_on_filename: true) -> Array
    #
    # Read a file and return an array with the result. The result array is a
    # three-element array, with `true`/`false` at index 0 to indicate
    # pass/fail, an array of schema validation errors at index 1 (if any), and
    # `true`/`false` at index 2 to indicate whether the filename passed/failed
    # validation.
    #
    # You can choose whether filename validation failure should cause overall
    # validation failure with the `fail_on_filename` parameter (default: true).
    def self.validate(file, fail_on_filename: true)
      File.read(file).validate(fail_on_filename: fail_on_filename)
    end

    # :call-seq:
    #   validate!(filename, fail_on_filename: true)
    #
    # Read a file and raise a ValidationError upon failure. If an error is
    # raised it will contain the detected validation failures for further
    # inspection.
    #
    # You can choose whether filename validation failure should cause overall
    # validation failure with the `fail_on_filename` parameter (default: true).
    def self.validate!(file, fail_on_filename: true)
      File.read(file).validate!(fail_on_filename: fail_on_filename)
    end

    # :call-seq:
    #   write(filename, File)
    #   write(filename, Index)
    #   write(filename, yaml)
    #
    # Write the supplied File, Index or yaml string to `file`.
    def self.write(file, cff, comment = '')
      comment = cff.comment if cff.respond_to?(:comment)
      cff = cff.to_yaml unless cff.is_a?(String)
      content = File.format_comment(comment) + cff[YAML_HEADER.length...-1]

      ::File.write(file, content)
    end

    # :call-seq:
    #   validate(fail_fast: false, fail_on_filename: true) -> Array
    #
    # Validate this file and return an array with the result. The result array
    # is a three-element array, with `true`/`false` at index 0 to indicate
    # pass/fail, an array of schema validation errors at index 1 (if any), and
    # `true`/`false` at index 2 to indicate whether the filename passed/failed
    # validation.
    #
    # You can choose whether filename validation failure should cause overall
    # validation failure with the `fail_on_filename` parameter (default: true).
    def validate(fail_fast: false, fail_on_filename: true)
      valid_filename = (::File.basename(@filename) == CFF_VALID_FILENAME)
      result = (@index.validate(fail_fast: fail_fast) << valid_filename)
      result[0] &&= valid_filename if fail_on_filename

      result
    end

    # :call-seq:
    #   validate!(fail_fast: false, fail_on_filename: true)
    #
    # Validate this file and raise a ValidationError upon failure. If an error
    # is raised it will contain the detected validation failures for further
    # inspection.
    #
    # You can choose whether filename validation failure should cause overall
    # validation failure with the `fail_on_filename` parameter (default: true).
    def validate!(fail_fast: false, fail_on_filename: true)
      result = validate(
        fail_fast: fail_fast, fail_on_filename: fail_on_filename
      )
      return if result[0]

      raise ValidationError.new(result[1], invalid_filename: !result[2])
    end

    # :call-seq:
    #   write(save_as: filename)
    #
    # Write this CFF File. The `save_as` parameter can be used to save a new
    # copy of this CFF File under a different filename, leaving the original
    # file untouched. If `save_as` is used then the internal filename of the
    # File will be updated to the supplied filename.
    def write(save_as: nil)
      unless save_as.nil?
        @filename = save_as
        @dirty = true
      end

      File.write(@filename, @index, @comment) if @dirty
      @dirty = false
    end

    # :call-seq:
    #   comment = string or array
    #
    # A comment to be inserted at the top of the resultant CFF file. This can
    # be supplied as a simple string or an array of strings. When the file is
    # saved this comment is formatted as follows:
    #
    # * a simple string is split into 75 character lines and `'# '` is prepended
    # to each line;
    # * an array of strings is joined into a single string with `'\n'` and
    # `'# '` is prepended to each line;
    #
    # If you care about formatting, use an array of strings for your comment,
    # if not, use a single string.
    def comment=(comment)
      @dirty = true
      @comment = comment
    end

    def to_yaml # :nodoc:
      @index.to_yaml
    end

    def method_missing(name, *args) # :nodoc:
      if @index.respond_to?(name)
        @dirty = true if name.to_s.end_with?('=') # Remove to_s when Ruby >2.6.
        @index.send(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(name, *all) # :nodoc:
      @index.respond_to?(name, *all)
    end

    def self.format_comment(comment) # :nodoc:
      return '' if comment.empty?

      comment = comment.scan(/.{1,75}/) if comment.is_a?(String)
      c = comment.map do |l|
        l.empty? ? '#' : "# #{l}"
      end.join("\n")

      "#{c}\n\n"
    end

    def self.parse_comment(content) # :nodoc:
      content = content.split("\n")

      content.reduce([]) do |acc, line|
        break acc unless line.start_with?('#')

        acc << line.sub(/^#+/, '').strip
      end
    end
  end
end
