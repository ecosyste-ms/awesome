require 'csv'

namespace :projects do
  desc 'sync projects'
  task :sync => :environment do
    Project.sync_least_recently_synced
  end

  desc 'sync reviewed projects'
  task :sync_reviewed => :environment do
    Project.sync_least_recently_synced_reviewed
  end

  desc 'import projects'
  task :import => :environment do
    Project.import_from_readme
  end

  desc 'discover projects'
  task :discover => :environment do
    Project.discover_via_topics
    Project.discover_via_keywords
  end
end