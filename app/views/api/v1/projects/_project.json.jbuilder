json.extract! project, :id, :url, :last_synced_at, :repository, :keywords, :created_at, :updated_at, :avatar_url, :language, :readme, :funding_links
json.project_url api_v1_project_url(project, format: :json)
json.html_url project_url(project)
json.lists_url api_v1_project_lists_url(project, format: :json)