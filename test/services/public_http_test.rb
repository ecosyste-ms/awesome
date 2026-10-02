require 'test_helper'

class PublicHttpTest < ActiveSupport::TestCase
  test 'connects to the validated address without a second DNS lookup' do
    Resolv.expects(:getaddresses).with('public.example').once.returns(['93.184.216.34'])
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    response.stubs(:body).returns('public response')
    http = mock
    http.expects(:request).with { |request| request['host'] == 'public.example' }.returns(response)
    Net::HTTP.expects(:start).with('public.example', 443, nil,
      has_entries(ipaddr: '93.184.216.34', use_ssl: true)).yields(http)

    assert_equal 'public response', PublicHttp.get('https://public.example/repo').body
  end

  test 'validates the hostname again after a same-host redirect' do
    Resolv.stubs(:getaddresses).with('public.example').returns(['93.184.216.34'], ['127.0.0.1'])
    stub_request(:get, 'https://public.example/repo')
      .to_return(status: 302, headers: { 'Location' => 'private' })

    assert_raises(SsrfFilter::PrivateIPAddress) { PublicHttp.get('https://public.example/repo') }
    assert_not_requested :get, 'https://public.example/private'
  end

  test 'rejects unsupported schemes and credentials before resolving DNS' do
    Resolv.expects(:getaddresses).never
    ['file:///etc/passwd', 'javascript:alert(1)', '//example.com/repo', 'https://user:password@example.com/repo'].each do |url|
      assert_raises(SsrfFilter::Error) { PublicHttp.get(url) }
    end
  end

  test 'limits redirect loops' do
    Resolv.stubs(:getaddresses).with('public.example').returns(['93.184.216.34'])
    stub_request(:get, 'https://public.example/repo').to_return(status: 302, headers: { 'Location' => '/repo' })

    assert_raises(SsrfFilter::TooManyRedirects) { PublicHttp.get('https://public.example/repo') }
    assert_requested :get, 'https://public.example/repo', times: PublicHttp::MAX_REDIRECTS + 1
  end
end
