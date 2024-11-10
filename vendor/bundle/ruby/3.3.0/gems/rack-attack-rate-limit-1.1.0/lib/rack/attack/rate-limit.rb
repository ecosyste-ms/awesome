unless defined?(Rack::Attack)
  module Rack
    class Attack
    end
  end
end

module Rack
  class Attack
    class RateLimit
      RACK_ATTACK_KEY = 'rack.attack.throttle_data'

      attr_reader :app, :options

      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def call(env)
        # If env does not have necessary data to extract rate limit data for the provider, then app.call
        return app.call(env) unless rate_limit_available?(env)
        # Otherwise, add rate limit headers
        status, headers, body = app.call(env)
        add_rate_limit_headers!(headers, env)
        [status, headers, body]
      end

      # Returns env key used by Rack::Attack to namespace data
      #
      # Returns string
      def rack_attack_key
        RACK_ATTACK_KEY
      end

      # Default options to configure Rack::RateLimit
      #
      # Returns hash
      def default_options
        { throttle: 'throttle' }
      end

      def throttle
        Array(options[:throttle]) || []
      end

      # Return hash of headers with Rate Limiting data
      #
      # headers - Hash of headers
      #
      # Returns hash
      def add_rate_limit_headers!(headers, env)
        throttle_data = throttle_data_closest_to_limit(env)
        headers['X-RateLimit-Limit']      = rate_limit_limit(throttle_data).to_s
        headers['X-RateLimit-Remaining']  = rate_limit_remaining(throttle_data).to_s
        headers
      end

      protected

      # RateLimit upper limit from Rack::Attack
      #
      # env - Hash
      #
      # Returns Fixnum
      def rate_limit_limit(throttle_data)
        throttle_data[:limit]
      end

      # RateLimit remaining request from Rack::Attack
      #
      # env - Hash
      #
      # Returns Fixnum
      def rate_limit_remaining(throttle_data)
        rate_limit_limit(throttle_data) - throttle_data[:count]
      end

      # Rate Limit available method for Rack::Attack provider
      # Checks that at least one of the keys provided by the user are in the rack.attack.throttle_data env hash key
      #
      # env - Hash
      #
      # Returns boolean
      def rate_limit_available?(env)
        env.key?(rack_attack_key) && (env[rack_attack_key].keys & throttle).any?
      end

      # Throttle Data of Interest
      # Filters the rack.attack.throttle_data env hash key for the throttle names provided by the user
      #
      # env - Hash
      #
      # Returns Hash
      def throttle_data_of_interest(env)
        env[rack_attack_key].select { |k, _v| throttle.include?(k) }
      end

      # Throttle Data Closest to Limit
      # Selects the hash in throttle_data_of_interest where the user is closest to the limit
      #
      # env - Hash
      #
      # Returns Hash
      def throttle_data_closest_to_limit(env)
        min_array = throttle_data_of_interest(env).min_by { |_k, v| v[:limit] - v[:count] }
        # The min_by method returns an array of the form [key, value]
        # We only need the values
        min_array.last
      end
    end
  end
end
