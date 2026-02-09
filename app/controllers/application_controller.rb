class ApplicationController < ActionController::Base
  skip_forgery_protection
  include Pagy::Backend

  before_action :set_cache_headers

  def default_url_options(options = {})
    Rails.env.production? ? { :protocol => "https" }.merge(options) : options
  end

  def set_cache_headers
    return unless request.get? || request.head?
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour
    response.headers['CDN-Cache-Control'] = "max-age=#{4.hours.to_i}, stale-while-revalidate=#{1.day.to_i}"
  end
end
