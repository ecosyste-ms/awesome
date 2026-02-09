class Api::V1::ApplicationController < ApplicationController
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def set_cache_headers
    return unless request.get? || request.head?
    expires_in 5.minutes, public: true, stale_while_revalidate: 30.minutes
    response.headers['CDN-Cache-Control'] = "max-age=#{1.hour.to_i}, stale-while-revalidate=#{4.hours.to_i}"
  end
end