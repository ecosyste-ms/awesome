class List < ApplicationRecord
  include EcosystemsApiClient
  validates :url, presence: true, format: { without: /\A.*\/\z/, message: "should not end with a slash" }

  has_many :list_projects, dependent: :destroy
  has_many :projects, through: :list_projects

  belongs_to :matching_project, foreign_key: :url, primary_key: :url, optional: true, class_name: 'Project'

  scope :active, -> { where("(repository ->> 'archived') = ?", 'false') }
  scope :archived, -> { where("(repository ->> 'archived') = ?", 'true') }
  scope :fork, -> { where("(repository ->> 'fork') = ?", 'true') }
  scope :source, -> { where("(repository ->> 'fork') = ?", 'false') }

  scope :template, -> { where("(repository ->> 'template') = ?", 'true') }
  scope :not_from_template, -> { where("length(repository ->> 'template_full_name') = 0") }
  scope :from_template, -> { where("length(repository ->> 'template_full_name') > 0") }

  scope :with_readme, -> { where.not(readme: nil) }
  scope :with_repository, -> { where.not(repository: nil) }

  scope :displayable, -> { where(displayable: true) }
  scope :not_awesome_stars, -> { where.not('url LIKE ?', '%awesome-stars%') }
  
  scope :with_primary_language, -> { where.not(primary_language: nil) }
  scope :list_of_lists, -> { where(list_of_lists: true) }

  scope :topic, -> (keyword) { where("keywords @> ARRAY[?]::varchar[]", keyword) }
  scope :primary_language, -> (language) { where(primary_language: language) }

  scope :search, -> (query) { where('url ILIKE ? OR repository ->> \'description\' ILIKE ?', "%#{query}%", "%#{query}%") }

  scope :order_by_stars, -> { order(stars: :desc)  }

  before_save :set_stars
  before_save :set_keywords

  def set_stars
    self.stars = repository['stargazers_count'] if repository.present? && repository['stargazers_count'].present?
  end

  def set_keywords
    self.keywords = repository['topics'] if repository.present? && repository['topics'].present?
  end

  def self.find_by_slug!(slug)
    find_by!(url: "https://github.com/#{slug.downcase}")
  end

  def slug
    url.gsub('https://github.com/', '').downcase
  end

  def to_param
    slug
  end

  before_save :set_displayable

  def self.sync_least_recently_synced
    # Optimized: batch enqueue jobs instead of individual sync_async calls
    # Reduced from 500 to 100 to prevent overwhelming Sidekiq
    ids = List.where(last_synced_at: nil)
      .or(List.where("last_synced_at < ?", 1.day.ago))
      .order('last_synced_at asc nulls first')
      .limit(100)
      .pluck(:id)

    # Batch push to Sidekiq (more efficient than 100 individual pushes)
    SyncListWorker.perform_bulk(ids.map { |id| [id] }) if ids.any?
  end

  def to_s
    name
  end

  def name
    url.split('/').last
  end

  def set_displayable
    self.displayable = is_displayable?
  end

  def is_displayable?
    !fork? && !archived? && has_many_projects? && not_awesome_stars? && description.present? && !name.include?('?') && !topics.include?('starred')
  end

  def fork?
    repository.present? && repository['fork'] == true
  end

  def archived?
    repository.present? && repository['archived'] == true
  end

  def has_many_projects?
    projects_count && projects_count > 29
  end

  def not_awesome_stars?
    !url.include?('awesome-stars')
  end

  def self.topics
    List.displayable.pluck(:keywords).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def self.ignorable_topics
    ['hacktoberfest']
  end

  def project_topics
    @project_topics ||= projects.pluck(:keywords).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reject{|k,v| List.ignorable_topics.include?(k) }.reverse
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
    Rails.logger.info "Duplicate url #{url}"
    Rails.logger.info e.class
    destroy
  rescue
    Rails.logger.info "Error syncing #{url}"
  end

  def check_url
    conn = Faraday.new(url: url) do |faraday|
      faraday.response :follow_redirects
      faraday.headers['User-Agent'] = 'awesome.ecosyste.ms'
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    update!(url: response.env.url.to_s)
    # TODO avoid duplicates
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "Duplicate url #{url}"
    Rails.logger.info e.class
    destroy
  rescue
    Rails.logger.info "Error checking url for #{url}"
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
      ecosystems_api_get(url) rescue nil
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
    data = ecosystems_api_get(repos_api_url)
    return unless data
    self.repository = data
    self.save
  rescue
    Rails.logger.info "Error fetching repository for #{repository_url}"
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
    if readme_file_name.blank? || download_url.blank?
      fetch_readme_fallback
    else
      json = ecosystems_api_get(archive_url(readme_file_name))
      return unless json

      self.readme = json['contents']
      self.save
    end
  rescue
    Rails.logger.info "Error fetching readme for #{repository_url}"
    fetch_readme_fallback
  end

  def fetch_readme_fallback
    file_name = readme_file_name.presence || 'README.md'
    conn = Faraday.new(url: raw_url(file_name)) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    self.readme = response.body
    self.save
  rescue
    Rails.logger.info "Error fetching readme for #{repository_url}"
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
    links = readme_links
    return if links.empty?

    # Batch insert/update instead of individual operations
    # This is MUCH faster than N individual find_or_create_by calls
    urls = links.map { |link| link[:url] }

    # Find existing projects in one query
    existing_projects = Project.where(url: urls).index_by(&:url)

    # Collect new projects to insert
    new_project_attrs = []
    projects_to_sync = []

    links.each do |link|
      url = link[:url]
      project = existing_projects[url]

      unless project
        new_project_attrs << { url: url, created_at: Time.current, updated_at: Time.current }
      end

      if project && project.last_synced_at.nil?
        projects_to_sync << project.id
      end
    end

    # Batch insert new projects
    if new_project_attrs.any?
      Project.insert_all(new_project_attrs, unique_by: :url)
      # Reload to get the newly created projects
      existing_projects = Project.where(url: urls).index_by(&:url)
    end

    # Batch sync projects (max 100 at a time to avoid overwhelming queue)
    if projects_to_sync.any?
      SyncProjectWorker.perform_bulk(projects_to_sync.first(100).map { |id| [id] })
    end

    # Now handle list_projects association
    project_ids = existing_projects.values.map(&:id)
    existing_list_projects = list_projects.where(project_id: project_ids).index_by(&:project_id)

    list_projects_to_insert = []
    list_projects_to_update = []

    links.each do |link|
      project = existing_projects[link[:url]]
      next unless project

      list_project = existing_list_projects[project.id]

      if list_project
        # Update existing
        list_projects_to_update << {
          id: list_project.id,
          name: link[:name],
          description: link[:description],
          category: link[:category],
          sub_category: link[:sub_category],
          updated_at: Time.current
        }
      else
        # Insert new
        list_projects_to_insert << {
          list_id: id,
          project_id: project.id,
          name: link[:name],
          description: link[:description],
          category: link[:category],
          sub_category: link[:sub_category],
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    # Batch operations
    ListProject.insert_all(list_projects_to_insert) if list_projects_to_insert.any?
    ListProject.upsert_all(list_projects_to_update) if list_projects_to_update.any?
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
    json = ecosystems_api_get(url)
    return unless json

    # TODO pagination

    json['repositories'].each do |repo|
      url = repo['html_url'].chomp('/')

      existing = List.find_by(url: url)
      next if existing.present? && existing.projects_count && existing.projects_count > 0

      l = List.find_or_create_by(url: url)
      l.save
      l.sync_async
    end
  end

  def language_breakdown
    @language_breakdown ||= projects.pluck(Arel.sql('repository ->> \'language\'')).reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def set_primary_language
    if primarily_oss_repositories?
      # combine "TypeScript" and "JavaScript" into "JavaScript"
      breakdown = language_breakdown.map{|k,v| k == 'TypeScript' ? ['JavaScript', v] : [k, v] }

      # return nil unless one language is used by more than 50% of projects
      # TODO should consider projects_count as projects with a language, not all links
      return nil unless breakdown && breakdown.first && breakdown.first[1] > projects_with_language_count / 2 && breakdown.first[1] > 30
      self.primary_language = breakdown.first[0]
    else
      self.primary_language = nil
    end
  end 

  def projects_with_language_count
    projects.with_repository.map(&:language).compact.length
  end

  def set_list_of_lists
    if projects_count && projects_count > 0
      matching_lists_count = List.where(url: projects.pluck(:url)).count
    
      self.list_of_lists = matching_lists_count > projects.with_repository.count / 2 && matching_lists_count > 150
    else
      self.list_of_lists = false
    end
  end

  def primarily_oss_repositories?
    return false unless projects_count && projects_count > 0
    projects_with_repository_count = projects.with_repository.count
    return false unless projects_with_repository_count > 0
    projects_with_repository_count > projects_count / 2
  end

  def find_spoken_language
    return unless description.present?
    return unless description.length > 20
    # remove emojis
    formatted_description = self.description.gsub(/[\u{1F600}-\u{1F6FF}]/, '')
    # remove markdown emoji
    formatted_description = formatted_description.gsub(/:[a-z_]+:/, '')
    cld3 = CLD3::NNetLanguageIdentifier.new(0, 1000)
    lang = cld3.find_language(formatted_description)
    ISO_639.find_by_code(lang.language.to_s).try(:[],3).try(:split, ';').try(:first) if lang.probability > 0.99
  end

  def categories
    list_projects.pluck(:category).uniq.compact
  end

  def category_counts
    @category_counts ||= list_projects.group(:category).count.sort_by{|k,v| v}.reverse
  end

  def sub_categories
    list_projects.pluck(:sub_category).uniq.compact
  end

  def sub_category_counts
    @sub_category_counts ||= list_projects.group(:sub_category).count.sort_by{|k,v| v}.reverse
  end

  IGNORED_CATEGORIES = ['license', 'other', 'miscellaneous', 'misc', 'related', "other awesome lists", "related lists", 'contributing',
                        'footnotes', "table of contents", 'others', 'uncategorized', 'projects', 'software', 'other lists', 'general',
                        'official resources', 'other resources']

  def self.categories
    List.displayable
      .map(&:categories)
      .flatten
      .compact
      .map(&:downcase)
      .reject { |category| IGNORED_CATEGORIES.include?(category) }
      .group_by(&:itself)
      .transform_values(&:count)
      .sort_by { |_, v| v }
      .reverse
  end

  def self.sub_categories
    List.displayable
      .map(&:sub_categories)
      .flatten
      .compact
      .map(&:downcase)
      .reject { |category| IGNORED_CATEGORIES.include?(category) }
      .group_by(&:itself)
      .transform_values(&:count)
      .sort_by { |_, v| v }
      .reverse
  end  

  def self.combined_categories
    categories = List.categories.to_h
    sub_categories = List.sub_categories.to_h

    combined = categories.merge(sub_categories) do |key, oldval, newval|
      oldval + newval
    end
  end

  def self.count_category_usage(category)
    ListProject.where('category ILIKE ? OR sub_category ILIKE ?', category, category).count
  end

  def self.category_summary
    combined_categories.first(100).map do |category, count|
      { category: category, count: count, usage: count_category_usage(category) }
    end
  end

  def self.category_summary_csv
    csv = CSV.generate do |csv|
      csv << ['Category', 'Count', 'Usage']
      category_summary.each do |category|
        csv << [category[:category], category[:count], category[:usage]]
      end
    end
    csv
  end
end
