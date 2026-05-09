json.cache! [project, 'v2'] do
  json.extract! project, :id, :url, :last_synced_at, :repository, :keywords, :created_at, :updated_at, :avatar_url, :language, :funding_links, :categories, :sub_categories
  json.readme project.readme.to_s.byteslice(0, Project::README_MAX_BYTES).scrub.presence
  json.project_url api_v1_project_url(project, format: :json)
  json.html_url project_url(project)
  json.lists_url api_v1_project_lists_url(project, format: :json)
end