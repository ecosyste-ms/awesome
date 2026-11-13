require 'test_helper'

class OpenapiTest < ActionDispatch::IntegrationTest
  SPEC = YAML.load_file(Rails.root.join('openapi/api/v1/openapi.yaml'))

  setup do
    project = create(:project, url: 'https://github.com/bcoe/awesome-cross-platform-nodejs', last_synced_at: Time.current)
    list = create(:list, url: 'https://github.com/sindresorhus/awesome')
    create(:list_project, list: list, project: project)
    Topic.create!(slug: 'ruby', name: 'Ruby')
  end

  test 'path parameters are documented as strings with an example' do
    path_parameters.each do |path, parameters|
      parameters.each do |parameter|
        assert_equal 'string', parameter.dig('schema', 'type'), "#{path} {#{parameter['name']}} should be a string"
        assert parameter['example'].present?, "#{path} {#{parameter['name']}} should have an example"
      end
    end
  end

  test 'path parameter examples resolve with and without percent-encoding' do
    path_parameters.each do |path, parameters|
      [false, true].each do |encode|
        url = parameters.reduce(path) do |result, parameter|
          value = parameter['example'].to_s
          result.sub("{#{parameter['name']}}", encode ? ERB::Util.url_encode(value) : value)
        end

        get "/api/v1#{url}"

        assert_response :success, "GET #{url} should succeed"
      end
    end
  end

  test 'list sort fields match the sortable columns' do
    sort_parameters = SPEC['paths'].filter_map do |path, operations|
      parameter = operations.dig('get', 'parameters').to_a.find { |parameter| parameter['in'] == 'query' && parameter['name'] == 'sort' }
      [path, parameter] if parameter
    end

    assert_equal ['/lists', '/projects/{id}/lists'], sort_parameters.map(&:first).sort
    sort_parameters.each do |path, parameter|
      assert_equal List.sortable_columns.keys.sort, parameter.dig('schema', 'enum').sort, "#{path} sort"
    end
  end

  private

  def path_parameters
    SPEC['paths'].filter_map do |path, operations|
      parameters = operations.dig('get', 'parameters').to_a.select { |parameter| parameter['in'] == 'path' }
      [path, parameters] if parameters.any?
    end
  end
end
