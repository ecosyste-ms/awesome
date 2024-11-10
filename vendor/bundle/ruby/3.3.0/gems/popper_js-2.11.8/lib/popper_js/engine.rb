# frozen_string_literal: true

module PopperJs
  class Engine < ::Rails::Engine
    initializer 'popper_js.assets' do |app|
      app.config.assets.paths << root.join('assets', 'javascripts').to_s
    end
  end
end
