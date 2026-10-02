class PublicHttp
  REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze
  MAX_REDIRECTS = 5

  Response = Data.define(:status, :body, :url) do
    def success?
      (200..299).cover?(status)
    end
  end

  def self.get(url, allowed_hosts: nil)
    uri = URI.parse(url.to_s)

    (MAX_REDIRECTS + 1).times do |redirects|
      unless uri.is_a?(URI::HTTP) && uri.hostname.present? && uri.userinfo.nil?
        raise SsrfFilter::Error, 'An HTTP(S) URL without credentials is required'
      end
      if allowed_hosts && !allowed_hosts.include?(uri.hostname.downcase)
        raise SsrfFilter::Error, 'Host is not allowed'
      end

      response = SsrfFilter.get(uri.to_s,
        max_redirects: 0, allow_unfollowed_redirects: true,
        headers: { 'User-Agent' => 'awesome.ecosyste.ms' },
        http_options: { open_timeout: 10, read_timeout: 30 })
      status = response.code.to_i
      unless REDIRECT_STATUSES.include?(status) && response['location'].present?
        return Response.new(status, response.body, uri.to_s)
      end

      raise SsrfFilter::TooManyRedirects, 'Too many redirects' if redirects == MAX_REDIRECTS
      uri = URI.join(uri.to_s, response['location'])
    end
  end
end
