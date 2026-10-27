namespace :ecosystems do
  task :update_shared_assets do
    unless File.executable?('bin/rails') && %w[Gemfile config/application.rb config/environment.rb].all? { |path| File.file?(path) }
      raise 'Shared assets can only be updated in a Rails app'
    end

    shared_asset_repo = 'https://github.com/ecosyste-ms/documentation'
    temp_dir = 'tmp/ecosystems_assets'
    rake_file = 'lib/tasks/ecosystems.rake'
    shared_files = %w[
      app/views/shared/_footer.html.erb
      app/assets/stylesheets/ecosystems.scss
      app/helpers/ecosystems_helper.rb
    ]
    header_file = 'app/views/shared/_header.html.erb'
    menu_file = 'app/views/shared/_menu.html.erb'
    partial_file = 'app/views/shared/_services_menu.html.erb'
    layout_file = 'app/views/layouts/application.html.erb'

    begin
      FileUtils.rm_r(temp_dir) if File.exist?(temp_dir)
      FileUtils.mkdir_p(File.dirname(temp_dir))
      system('git', 'clone', '--depth=1', '--branch', 'main', shared_asset_repo, temp_dir, exception: true)

      unless FileUtils.compare_file("#{temp_dir}/#{rake_file}", rake_file)
        puts 'ecosystems.rake has changed, restarting task with new code...'
        FileUtils.cp("#{temp_dir}/#{rake_file}", rake_file)
        FileUtils.rm_r(temp_dir)
        exec(Gem.ruby, Gem.bin_path('rake', 'rake'), 'ecosystems:update_shared_assets')
      end

      (shared_files + [header_file, menu_file, partial_file, layout_file]).each do |path|
        raise "Missing shared asset: #{path}" unless File.file?("#{temp_dir}/#{path}")
      end
      %w[app/assets/images public].each do |path|
        raise "Missing shared asset directory: #{path}" unless File.directory?("#{temp_dir}/#{path}")
      end

      %w[app/views/shared app/views/layouts app/assets/stylesheets app/helpers app/assets/images public].each do |path|
        FileUtils.mkdir_p(path)
      end
      FileUtils.cp("#{temp_dir}/#{header_file}", header_file) unless File.exist?(header_file)
      Rake::Task['ecosystems:update_services_menu'].invoke(temp_dir)
      shared_files.each { |path| FileUtils.cp("#{temp_dir}/#{path}", path) }
      FileUtils.cp("#{temp_dir}/#{layout_file}", layout_file) unless File.exist?(layout_file)
      FileUtils.cp_r("#{temp_dir}/app/assets/images/.", 'app/assets/images')
      Dir.children("#{temp_dir}/public").each do |entry|
        next if entry == 'robots.txt' && File.exist?('public/robots.txt')

        FileUtils.cp_r("#{temp_dir}/public/#{entry}", "public/#{entry}")
      end
      FileUtils.cp("#{temp_dir}/#{menu_file}", menu_file) unless File.exist?(menu_file)
    ensure
      FileUtils.rm_r(temp_dir) if File.exist?(temp_dir)
    end

    puts 'Shared assets updated; changes left uncommitted.'
  end

  task :update_services_menu, [:source] do |_, args|
    header_file = 'app/views/shared/_header.html.erb'
    partial_file = 'app/views/shared/_services_menu.html.erb'
    partial = File.read(File.join(args[:source], partial_file))
    header = File.read(header_file)
    render_call = "<%= render 'shared/services_menu' %>"

    # Keep the migration independent of future edits to the shared partial.
    legacy_menu = <<~'ERB'.lines.map { |line| "      #{line}" }.join
      <div id="header__global__menu" class="collapse header__global__menu">
        <% ecosystems_services.each do |category, services| %>
          <div class="header__global__menu__category">
            <h2 class="header__global__menu__category-title"><%= category %></h2>
            <ul class="header__global__menu__category-links">
              <% services.each do |service| %>
                <li>
                  <a href="<%= service[:url] %>" target="_blank" class="<%= 'active' if service[:url] == request.base_url %>"><%= service[:name] %></a>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    ERB
    variants = [
      legacy_menu,
      legacy_menu.sub('><%= service[:name] %></a>', ">\n                    <%= service[:name] %>\n                  </a>"),
      legacy_menu.sub('><%= service[:name] %></a>', "\n                    ><%= service[:name] %></a\n                  >")
    ]
    menu_count = header.scan('id="header__global__menu"').length
    render_count = header.scan(render_call).length

    unless render_count == 1 && menu_count.zero?
      matches = variants.select { |menu| header.include?(menu) }
      unless render_count.zero? && menu_count == 1 && matches.one?
        raise "Unrecognized services menu in #{header_file}; inspect it before updating shared assets"
      end
      header = header.sub(matches.first, "      #{render_call}\n")
    end

    File.write(partial_file, partial)
    File.write(header_file, header)
  end

  task :setup_shared_assets, [:target_repo] do |_t, args|
    target_repo_path = "../#{args[:target_repo]}"
    puts "Setting up shared assets for repository at: #{target_repo_path}"

    # Ensure target directory exists
    `mkdir -p #{target_repo_path}/lib/tasks`

    # Copy required files
    `cp lib/tasks/ecosystems.rake #{target_repo_path}/lib/tasks/`

    puts "Shared assets setup completed successfully."

    # add app_name and app_description to the target repo
    puts "Add the following to app/helpers/application_helper.rb in the target repo:"
    puts "module ApplicationHelper"
    puts "  def app_name"
    puts "    \"AppName\""
    puts "  end"
    puts ""
    puts "  def app_description"
    puts "    \"Description of the app.\""
    puts "  end"
    puts "end"
  end
end
