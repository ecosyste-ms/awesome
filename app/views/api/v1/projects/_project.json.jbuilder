json.extract! project, :id, :name, :description, :url, :last_synced_at, :repository, :owner, :packages, :commits, :issues_stats, :events, :keywords, :dependencies, :score, :created_at, :updated_at, :avatar_url, :language, :category, :sub_category, :monthly_downloads, :readme, :funding_links, :readme_doi_urls, :works
json.project_url api_v1_project_url(project, format: :json)
json.html_url project_url(project)
