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

  test 'documented operations respond with path parameters sent as-is and percent-encoded' do
    SPEC['paths'].each do |path, operations|
      parameters = operations.dig('get', 'parameters').to_a
      query = parameters.select { |parameter| parameter['in'] == 'query' && parameter['required'] }
        .to_h { |parameter| [parameter['name'], parameter['example']] }

      [false, true].each do |encode|
        url = parameters.select { |parameter| parameter['in'] == 'path' }.reduce(path) do |result, parameter|
          value = parameter['example'].to_s
          result.sub("{#{parameter['name']}}", encode ? ERB::Util.url_encode(value) : value)
        end

        get "/api/v1#{url}", params: query

        assert_response :success, "GET #{url} should succeed"
      end
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
