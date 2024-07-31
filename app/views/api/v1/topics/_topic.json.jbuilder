



json.extract! topic, :id, :slug, :name, :short_description, :url, :github_count, :created_by, :logo_url, :released, :wikipedia_url, :related_topics, :aliases, :github_url, :content, :created_at, :updated_at
json.topic_url api_v1_topic_url(topic)
json.html_url topic_url(topic)
json.projects_url api_v1_projects_url(keyword: topic.slug)
json.lists_url api_v1_lists_url(topic: topic.slug)