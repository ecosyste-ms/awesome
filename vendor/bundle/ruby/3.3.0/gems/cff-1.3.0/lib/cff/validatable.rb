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

require_relative 'errors'
require_relative 'schema'

require 'json_schema'

##
module CFF
  # Methods to validate CFF files/models against a formal schema.
  module Validatable
    SCHEMA = JsonSchema.parse!(SCHEMA_FILE) # :nodoc:

    # :call-seq:
    #   validate!(fail_fast: false)
    #
    # Validate a CFF file or model (Index) and raise a ValidationError upon
    # failure. If an error is raised it will contain the detected validation
    # failures for further inspection. Setting `fail_fast` to true will fail
    # validation at the first detected failure, rather than gathering and
    # returning all failures.
    def validate!(fail_fast: false)
      result = validate(fail_fast: fail_fast)
      return if result[0]

      raise ValidationError.new(result[1])
    end

    # :call-seq:
    #   validate(fail_fast: false) -> Array
    #
    # Validate a CFF file or model (Index) and return an array with the result.
    # The result array is a two-element array, with `true`/`false` at index 0
    # to indicate pass/fail, and an array of errors at index 1 (if any).
    # Setting `fail_fast` to true will fail validation at the first detected
    # failure, rather than gathering and returning all failures.
    def validate(fail_fast: false)
      SCHEMA.validate(fields, fail_fast: fail_fast)
    end
  end
end
