require 'csv'

class Project < ApplicationRecord

  has_many :list_projects, dependent: :destroy
  has_many :lists, through: :list_projects

  belongs_to :matching_list, foreign_key: :url, primary_key: :url, optional: true, class_name: 'List'

  validates :url, presence: true, uniqueness: true

  scope :active, -> { where("(repository ->> 'archived') = ?", 'false') }
  scope :archived, -> { where("(repository ->> 'archived') = ?", 'true') }

  scope :language, ->(language) { where("(repository ->> 'language') = ?", language) }
  scope :owner, ->(owner) { where(owner: owner) }
  scope :keyword, ->(keyword) { where("keywords @> ARRAY[?]::varchar[]", keyword) }
  scope :with_readme, -> { where.not(readme: nil) }
  scope :with_repository, -> { where.not(repository: nil) }

  scope :order_by_stars, -> { order(stars: :desc) }

  scope :not_awesome_list, -> { where(list: false) }

  before_save :set_is_list?
  before_save :set_stars
  before_save :transform_url_to_https
  before_save :set_owner

  def set_is_list?
    self.list = matching_list.present?
  end

  def set_stars
    self.stars = repository.present? ? (repository.dig('stargazers_count') || 0) : 0
  end

  def transform_url_to_https
    self.url = url.gsub(/^http:/, 'https:') if url.present?
  end

  def set_owner
    self.owner = repository.dig('owner') if repository.present?
  end

  def self.find_by_slug!(slug)
    find_by!(url: "https://#{slug}")
  end

  def slug
    url.gsub('https://', '')
  end

  def to_param
    slug
  end
  
  def self.sync_least_recently_synced
    Project.where(last_synced_at: nil).or(Project.where("last_synced_at < ?", 1.day.ago)).order('last_synced_at asc nulls first').limit(500).each do |project|
      project.sync_async
    end
  end

  def self.sync_least_recently_synced_reviewed
    Project.reviewed.where(last_synced_at: nil).or(Project.reviewed.where("last_synced_at < ?", 1.day.ago)).order('last_synced_at asc nulls first').limit(500).each do |project|
      project.sync_async
    end
  end

  def self.sync_all
    Project.all.each do |project|
      project.sync_async
    end
  end

  def to_s
    url
  end

  def list_keywords?
    keywords.include?('awesome-list')
  end

  def awesome_url?
    url.match?(/awesome/i)
  end

  def on_github?
    url.match?(/github\.com/i)
  end

  def list?
    matching_list || list_keywords? || awesome_url?
  end

  def looks_like_list?
    return false unless on_github?
    list_keywords? || awesome_url?
  end

  def sync_list
    return unless looks_like_list? && matching_list.blank?
    list = List.find_or_create_by(url: url.chomp('/'))
    list.sync_async
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

  def first_created
    return unless repository.present?
    Time.parse(repository['created_at'])
  end

  def sync
    return if last_synced_at.present? && last_synced_at > 1.day.ago
    check_url
    fetch_repository
    fetch_readme
    return if destroyed?
    update_column(:last_synced_at, Time.now) 
    sync_list
    ping
  end

  def sync_async
    SyncProjectWorker.perform_async(id)
  end

  def check_url
    url.chomp!('/')
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
  
  def description
    return unless repository.present?
    repository["description"]
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
    self.keywords = repository["topics"].uniq.reject(&:blank?) if repository.present? && repository["topics"].present?
    self.save
  rescue
    puts "Error fetching repository for #{repository_url}"
  end

  
  def timeline_url
    return unless repository.present?
    return unless repository["host"]["name"] == "GitHub"

    "https://timeline.ecosyste.ms/api/v1/events/#{repository['full_name']}/summary"
  end

  def language
    return unless repository.present?
    repository['language']
  end

  def language_with_default
    language.presence || 'Unknown'
  end

  def owner_name
    return unless repository.present?
    repository['owner']
  end

  def avatar_url
    return unless repository.present?
    repository['icon_url']
  end

  def repository_license
    return nil unless repository.present?
    repository['license'] || repository.dig('metadata', 'files', 'license')
  end

  def readme_license
    return nil unless readme.present?
    readme_image_urls.select{|u| u.downcase.include?('license') }.any?
  end

  def open_source_license?
    (packages_licenses + [repository_license] + [readme_license]).compact.uniq.any?
  end

  def archived?
    return false unless repository.present?
    repository['archived']
  end

  def active?
    return false if archived?
  end

  def fork?
    return false unless repository.present?
    repository['fork']
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

  def blob_url(path)
    return unless repository.present?
    "#{repository['html_url']}/blob/#{repository['default_branch']}/#{path}"
  end 

  def raw_url(path)
    return unless repository.present?
    "#{repository['html_url']}/raw/#{repository['default_branch']}/#{path}"
  end 

  def funding_links
    (repo_funding_links + readme_funding_links).uniq
  end

  def repo_funding_links
    return [] if repository.blank? || repository['metadata'].blank? ||  repository['metadata']["funding"].blank?
    return [] if repository['metadata']["funding"].is_a?(String)
    repository['metadata']["funding"].map do |key,v|
      next if v.blank?
      case key
      when "github"
        Array(v).map{|username| "https://github.com/sponsors/#{username}" }
      when "tidelift"
        "https://tidelift.com/funding/github/#{v}"
      when "community_bridge"
        "https://funding.communitybridge.org/projects/#{v}"
      when "issuehunt"
        "https://issuehunt.io/r/#{v}"
      when "open_collective"
        "https://opencollective.com/#{v}"
      when "ko_fi"
        "https://ko-fi.com/#{v}"
      when "liberapay"
        "https://liberapay.com/#{v}"
      when "custom"
        v
      when "otechie"
        "https://otechie.com/#{v}"
      when "patreon"
        "https://patreon.com/#{v}"
      when "polar"
        "https://polar.sh/#{v}"
      else
        v
      end
    end.flatten.compact
  end

  def readme_urls
    return [] unless readme.present?
    urls = URI.extract(readme.gsub(/[\[\]]/, ' '), ['http', 'https']).uniq
    # remove trailing garbage
    urls.map{|u| u.gsub(/\:$/, '').gsub(/\*$/, '').gsub(/\.$/, '').gsub(/\,$/, '').gsub(/\*$/, '').gsub(/\)$/, '').gsub(/\)$/, '').gsub('&nbsp;','') }
  end

  def readme_domains
    readme_urls.map{|u| URI.parse(u).host rescue nil }.compact.uniq
  end

  def funding_domains
    ['opencollective.com', 'ko-fi.com', 'liberapay.com', 'patreon.com', 'otechie.com', 'issuehunt.io', 
    'communitybridge.org', 'tidelift.com', 'buymeacoffee.com', 'paypal.com', 'paypal.me','givebutter.com', 'polar.sh']
  end

  def readme_funding_links
    urls = readme_urls.select{|u| funding_domains.any?{|d| u.include?(d) } || u.include?('github.com/sponsors') }.reject{|u| ['.svg', '.png'].include? File.extname(URI.parse(u).path) }
    # remove anchors
    urls = urls.map{|u| u.gsub(/#.*$/, '') }.uniq
    # remove sponsor/9/website from open collective urls
    urls = urls.map{|u| u.gsub(/\/sponsor\/\d+\/website$/, '') }.uniq
  end

  def doi_domains
    ['doi.org', 'dx.doi.org', 'www.doi.org']
  end

  def readme_doi_urls
    readme_urls.select{|u| doi_domains.include?(URI.parse(u).host) }.uniq
  end

  def dois
    readme_doi_urls.map{|u| URI.parse(u).path.gsub(/^\//, '') }.uniq
  end

  def readme_image_urls
    return [] unless readme.present?
    urls = readme.scan(/!\[.*?\]\((.*?)\)/).flatten.compact.uniq

    # also scan for html images
    urls += readme.scan(/<img.*?src="(.*?)"/).flatten.compact.uniq

    # turn relative urls into absolute urls
    # remove anything after a space
    urls = urls.map{|u| u.split(' ').first }.compact.uniq
    
    urls = urls.map do |u|
      if !u.starts_with?('http')
        # if url starts with slash or alpha character, prepend repo url
        if u.starts_with?('/') || u.match?(/^[[:alpha:]]/)
          raw_url(u)
        end
      else
        u
      end
    end.compact
  end

  def categories
    list_projects.map(&:category).uniq.compact.reject(&:empty?)
  end

  def sub_categories
    list_projects.map(&:sub_category).uniq.compact.reject(&:empty?)
  end
end
