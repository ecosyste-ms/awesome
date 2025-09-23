class Topic < ApplicationRecord
  include EcosystemsApiClient

  scope :search, ->(query) { where('name ILIKE ? or short_description ILIKE ?', "%#{query}%", "%#{query}%") }

  scope :with_logo, -> { where.not(logo_url: nil) }
  scope :with_wikipedia, -> { where.not(wikipedia_url: nil) }
  scope :with_github_url, -> { where.not(github_url: [nil,'']) }

  scope :suggestable, -> { where('github_url is not null or (wikipedia_url is not null and logo_url is not null)') }

  scope :without_wikipedia, -> { where(wikipedia_url: nil) }

  scope :not_language, -> { where.not(name: PROGRAMMING_LANGUAGES) }

  scope :other_excluded, -> { where.not(name: (EXCLUDED_TOPICS + EXCLUDED_COMPANIES + EXCLUDED_GAMES)) }

  scope :not_google, -> { where('name not ilike ?', '%google%') }

  PROGRAMMING_LANGUAGES = %w[Ruby JavaScript Python Java PHP C C++ C# D Swift Objective-C Go Kotlin
                             TypeScript Scala R Rust Perl Shell HTML CSS Bash Haskell Elixir Assembly
                             Elm Erlang OCaml Lisp Groovy Nim F# Crystal Fortran ClojureScript Haxe
                             Dart Julia MATLAB Razor SQL VBScript COBOL Solidity SAS Markdown Lua Lean
                             Tcl Logo Smalltalk Ada ActionScript PostScript Racket ECMAScript Less Emacs VBA TeX Sass] +
                             ['Visual Basic', 'Common Lisp', 'The Julia Language', 'Clojure', 'PureScript', 'Squeak/Smalltalk']

  EXCLUDED_TOPICS = ['iOS', 'Command-line interface', 'JSON', 'Database', 'Artificial Intelligence', 'Bot',
                     'Game Development', 'macOS', 'npm', 'dotfiles', 'Authentication', 'Chat Bot', 'COVID-19',
                    'Terminal', 'Video', 'LeetCode', 'Ajax', 'PWA','Mathematics', 'Crawler', 'Blockchain',
                    'DevOps', 'Cryptography', 'Material Design', 'SVG', 'OAuth 2.0', 'RSS', 'Remote Procedure Call (RPC)',
                    'Quantum Computing', 'Malware', 'Firefox extension', 'pip', 'Pixel Art', 'friendly interactive shell',
                    'Jamstack', 'Oracle Database', 'Node.js', 'Git', 'Apache Cassandra', 'Steganography', 'Simple DirectMedia Layer',
                    'Climate change', 'Mazes', 'eBPF', 'UEFI', 'FIRST', 'Batch file', 'Creative Commons License',
                    'Open Access', 'Christianity', 'Finite Element Method (FEM)', 'The Gene Ontology Consortium',
                    'Document Object Model (DOM)', 'Awesome Lists', 'Windows', 'Discord.JS', 'Chrome', 'End-to-End Encryption',
                    'Windows UI Library (WinUI)', 'Discord Bots (Extensions)']
  EXCLUDED_COMPANIES = ['GitHub', 'Amazon Web Services', 'Discord', 'Azure', 'Heroku', 'Telegram', 'Android Studio',
                         'Twitter', 'Linux', 'Debian', 'Instagram', 'Slack', 'Docker','Netlify', 'Ubuntu',
                      'Facebook', 'Microsoft', 'Apple', 'Firefox', 'Twitch', 'Reddit', 'Cloudflare', 'HackerRank',
                      'Arch Linux', 'Steam', 'Atom', 'GitLab', 'Chromium', 'Sketch', 'NASA', 'Gmail',
                      'Visual Studio Code', 'sql-server', 'Postman', 'Visual Studio', 'Coursera', 'Homebrew', 'Netflix',
                    'Unreal Engine', 'Sublime Text', 'Azure DevOps', 'Ansible', 'Maven', 'Notion',
                    'Nvidia', 'BigQuery', 'Binance', 'Fedora','Android', '.NET', 'TikTok', 'Edge', 'Stack Overflow', 'tvOS',
                    'EPITECH', 'CodeChef', 'Medium', 'Algolia', 'Mozilla', 'MyAnimeList', 'ITMO', 'DuckDuckGo', 'Apple Music',
                  'Blogger', 'Spotify', 'YouTube', 'WhatsApp', 'Auth0', 'Contentful', 'SoundCloud', 'ZEIT', 'FIRST Tech Challenge']
  EXCLUDED_GAMES = ['Minecraft', 'Minecraft Mod', 'Minecraft Server', 'League of Legends', "Garry's Mod", 'VALORANT',
                    'Geometry Dash', 'Elite Dangerous', 'Guild Wars 2', 'Space Station 13', 'Riot Games', 'FlightGear', 'Bukkit',
                   'Js13kGames', 'Minecraft Forge', 'Factorio', 'Minetest', 'Ludum Dare', 'PocketMine-MP', 'ComputerCraft']

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
    List.topic(slug).displayable
  end

  def categories
    lists.map(&:category_counts).flatten(1).group_by(&:first).map{|k,v| [k, v.sum(&:last)]}.sort_by(&:last).reverse
  end

  def fallback_logo_url
    logo_url.presence || github_logo_url
  end

  def github_owner_url
    return unless github_url.present?
    github_url.split('/')[0..3].join('/')
  end

  def github_logo_url
    return unless github_owner_url.present?
    github_owner_url + '.png'
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
        related_topics: topic['related'],
        aliases: topic['aliases'],
        github_url: topic['github_url'],
        content: topic['content']
      )
    end

  end

  def load_projects
    data = ecosystems_api_get("https://repos.ecosyste.ms/api/v1/topics/#{slug}?per_page=100")
    if data
      urls = data['repositories'].map{|p| p['html_url'] }.uniq.reject(&:blank?)
      urls.each do |url|
        puts url
        project = projects.find_or_create_by(url: url)
        project.sync_async unless project.last_synced_at.present?
      end
    end
  end
end
