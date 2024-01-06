require 'faraday/typhoeus'
Faraday.default_adapter = :typhoeus

Faraday.default_connection = Faraday::Connection.new do |builder|
  builder.response :follow_redirects
  builder.request :url_encoded
  builder.adapter Faraday.default_adapter

  # Set timeouts
  builder.options.timeout = 5           # open/read timeout in seconds
  builder.options.open_timeout = 2      # connection open timeout in seconds
end