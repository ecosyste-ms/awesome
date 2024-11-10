require 'spec_helper'

describe Rack::Attack::RateLimit do

  include Rack::Test::Methods

  let(:throttle_one)    { 'foo_throttle' }
  let(:throttle_two)    { 'bar_throttle' }
  let(:throttle_three)  { 'baz_throttle' }

  let(:app) do
    use_throttle = throttle_one
    Rack::Builder.new do
      use Rack::Attack::RateLimit, throttle: use_throttle
      run ->(_env) { [200, {}, 'Hello, World!'] }
    end.to_app
  end

  context 'Throttle data not present from Rack::Attack' do

    before(:each) do
      get '/'
    end

    it 'should not create RateLimit headers' do
      last_response.header.key?('X-RateLimit-Limit').should be false
      last_response.header.key?('X-RateLimit-Remaining').should be false
    end

  end

  context 'Throttle data present from Rack::Attack' do
    before(:each) do
      get '/', {}, "#{Rack::Attack::RateLimit::RACK_ATTACK_KEY}" => rack_attack_throttle_data
    end

    let(:request_limit) { (1..10_000).to_a.sample }
    let(:request_count) { (1..(request_limit - 10)).to_a.sample }

    context 'one throttle only' do

      let(:rack_attack_throttle_data) do
        { "#{throttle_one}" => { count: request_count, limit: request_limit } }
      end

      it 'should include RateLimit headers' do
        last_response.header.key?('X-RateLimit-Limit').should be true
        last_response.header.key?('X-RateLimit-Remaining').should be true
      end

      it 'should return correct rate limit in header' do
        last_response.header['X-RateLimit-Limit'].to_i.should eq request_limit
      end

      it 'should return correct remaining calls in header' do
        last_response.header['X-RateLimit-Remaining'].to_i.should eq(request_limit - request_count)
      end
    end

    context 'multiple throttles' do

      let(:app) do
        use_throttle = [throttle_one, throttle_two, throttle_three]
        Rack::Builder.new do
          use Rack::Attack::RateLimit, throttle: use_throttle
          run ->(_env) { [200, {}, 'Hello, World!'] }
        end.to_app
      end

      let(:request_limits) { 3.times.map { (1..10_000).to_a.sample } }
      let(:request_counts) { 3.times.map { |index| (1..(request_limits[index] - 10)).to_a.sample } }

      let(:rack_attack_throttle_data) do
        data = {}
        [throttle_one, throttle_two, throttle_three].each_with_index do |thr, thr_index|
          data["#{thr}"] = { count: request_counts[thr_index], limit: request_limits[thr_index] }
        end
        data
      end
      it 'should include RateLimit headers' do
        last_response.header.key?('X-RateLimit-Limit').should be true
        last_response.header.key?('X-RateLimit-Remaining').should be true
      end

      describe 'header values' do
        let(:request_differences) do
          request_limits.map.each_with_index { |limit, index| limit - request_counts[index] }
        end
        let(:min_index) { request_differences.each_with_index.min.last }

        it 'should return correct rate limit' do
          last_response.header['X-RateLimit-Limit'].to_i.should eq request_limits[min_index]
        end

        it 'should return correct remaining calls' do
          last_response.header['X-RateLimit-Remaining'].to_i.should eq(request_differences[min_index])
        end
      end
    end
  end
end
