$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + "../lib")

require 'rspec'
require 'rack/test'
require 'rack/attack/rate-limit'

RSpec::configure do |config|

  config.formatter = :documentation
  config.tty = true
  config.color = true
end
