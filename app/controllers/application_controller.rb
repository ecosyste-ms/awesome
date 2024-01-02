class ApplicationController < ActionController::Base
  skip_forgery_protection
  include Pagy::Backend

  def default_url_options(options = {})
    Rails.env.production? ? { :protocol => "https" }.merge(options) : options
  end
end
