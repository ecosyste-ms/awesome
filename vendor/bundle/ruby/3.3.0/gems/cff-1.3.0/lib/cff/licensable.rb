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

require_relative 'schema'

##
module CFF
  # Functionality to add licence(s) to parts of the CFF model.
  module Licensable
    LICENSES = SCHEMA_FILE['definitions']['license-enum']['enum'].dup.freeze # :nodoc:

    # :call-seq:
    #   license = license
    #   license = Array
    #
    # Set the license, or licenses, of this work. Only licenses that conform
    # to the [SPDX License List](https://spdx.org/licenses/) will be accepted.
    # If you need specify a different license you should set `license-url`
    # with a link to the license instead.
    def license=(lic)
      list = [*lic].select { |l| LICENSES.include?(l) }
      @fields['license'] = case list.length
                           when 0
                             @fields['license']
                           when 1
                             list[0]
                           else
                             list
                           end
    end
  end
end
