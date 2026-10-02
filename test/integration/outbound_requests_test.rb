require 'test_helper'

class OutboundRequestsTest < ActionDispatch::IntegrationTest
  teardown do
    SyncProjectWorker.clear
    SyncListWorker.clear
  end

  ['127.0.0.1', '169.254.169.254', '[::1]', '[::ffff:127.0.0.1]'].each do |host|
    test "project lookup cannot fetch #{host}" do
      url = "https://#{host}/repo"
      get lookup_api_v1_projects_path, params: { url: url }
      assert_response :success
      project = Project.find_by!(url: url)
      stub_request(:get, project.repos_api_url).to_return(status: 503)

      SyncProjectWorker.drain

      assert_not_requested :get, url
      assert_nil project.reload.last_synced_at
      assert_not_nil project.last_sync_attempt_at
    end
  end

  test 'project lookup cannot fetch a hostname resolving to a private address' do
    Resolv.stubs(:getaddresses).with('internal.example').returns(['10.0.0.5'])
    url = 'https://internal.example/repo'
    get lookup_api_v1_projects_path, params: { url: url }
    project = Project.find_by!(url: url)
    stub_request(:get, project.repos_api_url).to_return(status: 503)

    SyncProjectWorker.drain

    assert_not_requested :get, url
    assert_nil project.reload.last_synced_at
  end

  test 'project sync rejects a redirect from a public site to a private address' do
    Resolv.stubs(:getaddresses).with('public.example').returns(['93.184.216.34'])
    Resolv.stubs(:getaddresses).with('127.0.0.1').returns(['127.0.0.1'])
    url = 'https://public.example/repo'
    get lookup_api_v1_projects_path, params: { url: url }
    project = Project.find_by!(url: url)
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => 'https://127.0.0.1/private' })
    stub_request(:get, project.repos_api_url).to_return(status: 503)

    SyncProjectWorker.drain

    assert_requested :get, url, at_least_times: 1
    assert_not_requested :get, 'https://127.0.0.1/private'
    assert_equal url, project.reload.url
    assert_nil project.last_synced_at
  end

  test 'list lookup cannot fetch a private address or its cached README' do
    url = 'https://127.0.0.1/list'
    get lookup_api_v1_lists_path, params: { url: url }
    assert_response :success
    list = List.find_by!(url: url)
    list.update!(repository: { 'html_url' => url, 'default_branch' => 'main' })
    stub_request(:get, list.repos_api_url).to_return(status: 503)

    SyncListWorker.drain

    assert_not_requested :get, url
    assert_not_requested :get, "#{url}/raw/main/README.md"
    assert_nil list.reload.readme
  end

  test 'list sync follows a public redirect and fetches a public README' do
    Resolv.stubs(:getaddresses).with('github.com').returns(['93.184.216.34'])
    url = 'https://github.com/old/list'
    destination = 'https://github.com/new/list'
    get lookup_api_v1_lists_path, params: { url: url }
    list = List.find_by!(url: url)
    stub_request(:get, url).to_return(status: 301, headers: { 'Location' => '/new/list' })
    stub_request(:get, destination).to_return(status: 200)
    repository = { 'html_url' => destination, 'default_branch' => 'main',
      'host' => { 'name' => 'GitHub' }, 'full_name' => 'new/list' }
    stub_request(:get, "https://repos.ecosyste.ms/api/v1/repositories/lookup?url=#{destination}")
      .to_return(status: 200, body: repository.to_json)
    stub_request(:get, "#{destination}/raw/main/README.md").to_return(status: 200, body: '# List')
    stub_request(:get, 'https://repos.ecosyste.ms/api/v1/hosts/GitHub/repositories/new/list/ping')
      .to_return(status: 200, body: '{}')

    SyncListWorker.drain

    assert_equal destination, list.reload.url
    assert_equal '# List', list.readme
    assert_not_nil list.last_synced_at
  end
end
