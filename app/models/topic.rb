class Topic < ApplicationRecord

  scope :search, ->(query) { where('name ILIKE ? or short_description ILIKE ?', "%#{query}%", "%#{query}%") }

  def to_param
    slug
  end

  def to_s
    name
  end

  def projects
    Project.keyword(slug)
  end

  def lists
    List.topic(slug)
  end

  def self.load_from_github
    url = 'https://explore-feed.github.com/feed.json'
    conn = Faraday.new(url: url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    json = JSON.parse(response.body)
    json['topics'].map! do |topic|
      sleep 1
      url = topic['url']
      puts "fetching #{url}"
      resp = conn.get(url)
      next unless resp.success?
      html = Nokogiri::HTML(resp.body)
      selector = '.h3.color-fg-muted'
      text = html.css(selector).text

      count = text.match(/(\d{1,3}(?:,\d{3})*|\d+)/).to_s.gsub(',', '').to_i

      topic['count'] = count
      topic

      t = Topic.find_or_initialize_by(slug: topic['topic_name'])
      t.update(
        name: topic['display_name'],
        short_description: topic['short_description'],
        url: topic['url'],
        github_count: topic['count'],
        created_by: topic['created_by'],
        logo_url: topic['logo'],
        released: topic['released'],
        wikipedia_url: topic['wikipedia_url'],
        related_topics: topic['related'].split(',').map(&:strip),
        aliases: topic['aliases'].split(',').map(&:strip),
        github_url: topic['github_url'],
        content: topic['content']
      )
    end

  end

  def load_projects
    resp = Faraday.get("https://repos.ecosyste.ms/api/v1/topics/#{slug}?per_page=100") do |req|
      req.options.timeout = 30           # open/read timeout in seconds
      req.options.open_timeout = 30       # connection open timeout in seconds
    end
    if resp.status == 200
      data = JSON.parse(resp.body)
      urls = data['repositories'].map{|p| p['html_url'] }.uniq.reject(&:blank?)
      urls.each do |url|
        puts url
        project = projects.find_or_create_by(url: url)
        project.sync_async unless project.last_synced_at.present?
      end
    end
  end
end
