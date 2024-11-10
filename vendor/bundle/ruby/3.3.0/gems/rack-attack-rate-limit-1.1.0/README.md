# Rack::Attack::RateLimit

[![Build Status](https://travis-ci.org/jbyck/rack-attack-rate-limit.png?branch=master)](https://travis-ci.org/jbyck/rack-attack-rate-limit)

Add rate limit headers for [Rack::Attack](https://github.com/kickstarter/rack-attack) throttles.

## Installation

Install the gem:

```shell
gem install 'rack-attack-rate-limit'
```

In your gemfile:
```ruby
gem 'rack-attack-rate-limit', require: 'rack/attack/rate-limit'
```



And then execute:
```shell
bundle
```

## Usage

Rack::Attack::RateLimit expects at least one Rack::Attack throttle to be defined:

```ruby
Rack::Attack.throttle('my_throttle') do |req|
  req.ip
end
```

To include rate limit headers for throttles, include the Rack::Attack::RateLimit middleware, and provide it with the names of the throttles you want to add rate limit headers for. A single throttle name can be provided as a string, while multiple throttle names must be provided as an array of strings.

For Rails 3+:

```ruby
config.middleware.use Rack::Attack::RateLimit, throttle: ['my_throttle', 'my_other_throttle']
```

Rate limit headers are:

* 'X-RateLimit-Limit' - The total number of requests allowed.
* 'X-RateLimit-Remaining' - The number of remaining requests.

If a request triggers multiple throttles, the gem will add headers for the throttle with the lowest number of remaining requests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
