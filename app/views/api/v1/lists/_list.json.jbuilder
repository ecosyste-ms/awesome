json.cache! [list, 'v2'] do
  json.extract! list, :id, :url, :name, :description, :projects_count, :last_synced_at, :repository, :created_at, :updated_at, :primary_language, :list_of_lists, :displayable, :categories, :sub_categories
  json.readme list.readme.to_s.byteslice(0, List::README_MAX_BYTES).scrub.presence
  json.projects_url api_v1_list_projects_url(list, format: :json)
end