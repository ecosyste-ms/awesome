json.extract! list, :id, :url, :name, :description, :projects_count, :last_synced_at, :repository, :readme, :created_at, :updated_at, :primary_language, :list_of_lists, :displayable, :categories, :sub_categories
json.projects_url api_v1_list_projects_url(list, format: :json)