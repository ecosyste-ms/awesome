namespace :lists do
  desc 'sync lists'
  task sync: :environment do
    List.sync_least_recently_synced
  end

  desc 'discover lists'
  task :discover => :environment do
    List.import_lists_from_sindresorhus
    List.import_lists_from_topic('awesome-list')
    List.import_lists_from_topic('awesome')  
  end
end