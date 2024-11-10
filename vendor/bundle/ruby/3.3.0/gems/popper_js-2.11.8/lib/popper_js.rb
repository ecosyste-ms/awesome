# frozen_string_literal: true

require 'popper_js/version'

if defined?(::Rails)
  require 'popper_js/engine'
else
  gem_path = File.expand_path('..', File.dirname(__FILE__))
  assets_path = File.join(gem_path, 'assets')
  if defined?(::Sprockets)
    Sprockets.append_path(File.join(assets_path, 'javascripts'))
  elsif defined?(::Hanami)
    Hanami::Assets.sources << assets_path
  end
end
