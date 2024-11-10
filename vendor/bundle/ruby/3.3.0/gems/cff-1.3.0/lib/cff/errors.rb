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
  # Error is the base class for all errors raised by this library.
  class Error < RuntimeError
    def initialize(message = nil) # :nodoc:
      super
    end
  end

  # ValidationError is raised when a CFF file fails validation. It contains
  # details of each failure that was detected by the underlying JsonSchema
  # library, which is used to perform the validation.
  #
  # Additionally, the `invalid_filename` flag is used to indicate whether the
  # CFF file is named correctly. This is only used when validating a File;
  # validating a Index directly will not set this flag to `true`.
  class ValidationError < Error
    # The list of JsonSchema::ValidationErrors found by the validator.
    attr_reader :errors

    # If a File was validated, was its filename invalid?
    attr_reader :invalid_filename

    def initialize(errors, invalid_filename: false) # :nodoc:
      super('Validation error')
      @errors = errors
      @invalid_filename = invalid_filename
    end

    def to_s # :nodoc:
      "#{super}: (Invalid filename: #{@invalid_filename}) #{@errors.join(' ')}"
    end
  end
end
