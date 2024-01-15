class List < ApplicationRecord
  validates :url, presence: true

  has_many :list_projects, dependent: :destroy
  has_many :projects, through: :list_projects

  belongs_to :matching_project, foreign_key: :url, primary_key: :url, optional: true, class_name: 'Project'

  scope :with_readme, -> { where.not(readme: nil) }
  scope :with_repository, -> { where.not(repository: nil) }

  scope :displayable, -> { with_readme.where('projects_count >= 30').not_awesome_stars }
  scope :not_awesome_stars, -> { where.not('url LIKE ?', '%awesome-stars%') }

  scope :topic, -> (topic) { where('repository ->> \'topics\' ILIKE ?', "%#{topic}%") }

  def self.sync_least_recently_synced
    List.where(last_synced_at: nil).or(List.where("last_synced_at < ?", 1.day.ago)).order('last_synced_at asc nulls first').limit(500).each do |list|
      list.sync_async
    end
  end

  def to_s
    name
  end

  def name
    url.split('/').last
  end

  def self.topics
    List.displayable.pluck(Arel.sql("repository -> 'topics'")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def self.ignorable_topics
    ['hacktoberfest']
  end

  def project_topics
    projects.pluck(Arel.sql("repository -> 'topics'")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reject{|k,v| List.ignorable_topics.include?(k) }.reverse
  end

  def shared_topics
    project_topics.first(topics.length).to_h.keys & topics
  end

  def percentage_shared_topics
    return nil if topics.length == 0
    (shared_topics.length.to_f / topics.length.to_f * 100).round(2)
  end

  def description
    if repository.present? && repository['description'].present?
      repository['description']
    elsif read_attribute(:description).present?
      read_attribute(:description)
    end
  end

  def awesome_description
    return if description.blank?
    # add a period if there isn't one
    d = description.dup
    # remove whitespace from start and end
    d.strip!
    # add a period if there isn't one
    d = description[-1] == '.' ? description : "#{description}."
    # start with a capital letter
    d[0] = d[0].capitalize
    # Should not repeat "."  or "!" more than once 
    d.gsub!(/([.!?])\1+/, '\1')
    # remove extra urls (e.g. http://example.com)
    d.gsub!(/https?:\/\/\S+/, '')
    # proper case for "GitHub"
    d.gsub!(/github/i, 'GitHub')
    # proper case for "JavaScript"
    d.gsub!(/javascript/i, 'JavaScript')
    # OSX should be macOS
    d.gsub!(/MacOS/, 'macOS')
    d.gsub!(/OS X/, 'macOS')
    d.gsub!(/Mac OS X/, 'macOS')
    d.gsub!(/OSX/, 'macOS')
    d.gsub!(/Mac macOS/, 'macOS')
    # youtube should be YouTube
    d.gsub!(/youtube/i, 'YouTube')
    # stackoverflow should be Stack Overflow
    d.gsub!(/stackoverflow/i, 'Stack Overflow')
    # Nodejs should be Node.js
    d.gsub!(/Nodejs/i, 'Node.js')
    # remove all new lines
    d.gsub!(/\n/, ' ')
    # remove all carriage returns
    d.gsub!(/\r/, ' ')
    d
  end

  def last_updated_at
    return updated_at unless repository.present?
    return updated_at unless repository['updated_at'].present?
    Time.parse repository['updated_at']
  end

  def stars
    return 0 unless repository.present?
    repository['stargazers_count']
  end

  def forks
    return 0 unless repository.present?
    repository['forks_count']
  end

  def topics
    return [] unless repository.present?
    return [] unless repository['topics'].present?
    repository['topics']
  end

  def sync_async
    SyncListWorker.perform_async(id)
  end

  def sync
    check_url
    fetch_repository
    fetch_readme
    set_primary_language
    set_list_of_lists
    update(projects_count: readme_links.length, last_synced_at: Time.now)
    load_projects
    ping
  rescue ActiveRecord::RecordNotUnique => e
    puts "Duplicate url #{url}"
    puts e.class
    destroy
  rescue
    puts "Error syncing #{url}"
  end

  def check_url
    conn = Faraday.new(url: url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    update!(url: response.env.url.to_s) 
    # TODO avoid duplicates
  rescue ActiveRecord::RecordInvalid => e
    puts "Duplicate url #{url}"
    puts e.class
    destroy
  rescue
    puts "Error checking url for #{url}"
  end

  def repository_url
    repo_url = github_pages_to_repo_url(url)
    return repo_url if repo_url.present?
    url
  end

  def github_pages_to_repo_url(github_pages_url)
    match = github_pages_url.chomp('/').match(/https?:\/\/(.+)\.github\.io\/(.+)/)
    return nil unless match
  
    username = match[1]
    repo_name = match[2]
  
    "https://github.com/#{username}/#{repo_name}"
  end

  def ping
    ping_urls.each do |url|
      Faraday.get(url) rescue nil
    end
  end

  def ping_urls
    [repos_ping_url].compact
  end

  def repos_ping_url
    return unless repository.present?
    "https://repos.ecosyste.ms/api/v1/hosts/#{repository['host']['name']}/repositories/#{repository['full_name']}/ping"
  end

  def repos_api_url
    "https://repos.ecosyste.ms/api/v1/repositories/lookup?url=#{repository_url}"
  end

  def repos_url
    return unless repository.present?
    "https://repos.ecosyste.ms/hosts/#{repository['host']['name']}/repositories/#{repository['full_name']}"
  end

  def fetch_repository
    conn = Faraday.new(url: repos_api_url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    self.repository = JSON.parse(response.body)
    self.save
  rescue
    puts "Error fetching repository for #{repository_url}"
  end

  def readme_url
    return unless repository.present?
    "#{repository['html_url']}/blob/#{repository['default_branch']}/#{readme_file_name}"
  end

  def blob_url(path)
    return unless repository.present?
    "#{repository['html_url']}/blob/#{repository['default_branch']}/#{path}"
  end 

  def raw_url(path)
    return unless repository.present?
    "#{repository['html_url']}/raw/#{repository['default_branch']}/#{path}"
  end 

  def download_url
    return unless repository.present?
    repository['download_url']
  end

  def archive_url(path)
    return unless download_url.present?
    "https://archives.ecosyste.ms/api/v1/archives/contents?url=#{download_url}&path=#{path}"
  end

  def readme_file_name
    return unless repository.present?
    return unless repository['metadata'].present?
    return unless repository['metadata']['files'].present?
    repository['metadata']['files']['readme']
  end

  def fetch_readme
    return unless readme_file_name.present?
    return unless download_url.present?
    conn = Faraday.new(url: archive_url(readme_file_name)) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end
    response = conn.get
    return unless response.success?
    json = JSON.parse(response.body)

    self.readme = json['contents']
    self.save
  rescue
    puts "Error fetching readme for #{repository_url}"
  end

  def readme_url
    return unless repository.present?
    "#{repository['html_url']}/blob/#{repository['default_branch']}/#{readme_file_name}"
  end

  def parse_readme
    return [] unless readme.present?
    ReadmeParser.new(readme).parse_links
  end

  def load_projects
    readme_links.each do |link|
      project = Project.find_or_create_by(url: link[:url])
      project.sync_async if project.last_synced_at.nil?
      list_project = list_projects.find_or_create_by(project_id: project.id)
      list_project.update(name: link[:name], description: link[:description], category: link[:category], sub_category: link[:sub_category])
    end
  end

  def readme_links
    all_links = []

    parse_readme.each do |category, sub_categories|
      sub_categories.each do |sub_category, links|
        links.each do |link|
          next unless link[:url].present?
          next unless link[:url].start_with?('http')
          next if link[:url].include?(url)
          link[:category] = category
          link[:sub_category] = sub_category
          # strip anchor from url
          link[:url] = link[:url].split('#').first
          all_links << link
          
        end
      end
    end

    all_links
  end

  def self.import_lists_from_sindresorhus
    list = List.find_or_create_by(url: 'https://github.com/sindresorhus/awesome')
    list.fetch_repository
    list.fetch_readme
    list.readme_links.each do |link|
      next unless link[:url].present?
      next unless link[:url].start_with?('https://github.com/')
      next if link[:url].include?(list.url)
      link[:url] = link[:url].chomp('/')

      p link
      
      existing = List.find_by(url: link[:url])
      next if existing.present? && existing.projects_count && existing.projects_count > 0

      l = List.find_or_create_by(url: link[:url])
      l.name = link[:name]
      l.description = link[:description]
      l.save
      l.sync_async
    end
  end

  def self.import_lists_from_topic(page: 1, topic: 'awesome-list', per_page: 1000)
    url = "https://repos.ecosyste.ms/api/v1/topics/#{topic}?per_page=#{per_page}?page=#{page}"

    conn = Faraday.new(url: url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    json = JSON.parse(response.body)

    # TODO pagination

    json['repositories'].each do |repo|
      url = repo['html_url'].chomp('/')
      puts url

      existing = List.find_by(url: url)
      next if existing.present? && existing.projects_count && existing.projects_count > 0

      l = List.find_or_create_by(url: url)
      l.save
      l.sync_async
    end
  end

  def language_breakdown
    breakdown = projects.pluck(Arel.sql('repository ->> \'language\'')).reject(&:blank?)
    breakdown.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def set_primary_language
    # combine "TypeScript" and "JavaScript" into "JavaScript"
    breakdown = language_breakdown.map{|k,v| k == 'TypeScript' ? ['JavaScript', v] : [k, v] }

    # return nil unless one language is used by more than 50% of projects
    return nil unless breakdown && breakdown.first && breakdown.first[1] > projects_count / 2
    self.primary_language = breakdown.first[0]
  end 

  def set_list_of_lists
    # majority of projects are lists
    return false unless projects_count && projects_count > 0
    matching_lists_count = List.where(url: projects.pluck(:url)).count
    
    self.list_of_lists = matching_lists_count > projects_count / 2
  end
end
