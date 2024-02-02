namespace :lists do
  desc 'sync lists'
  task sync: :environment do
    List.sync_least_recently_synced
  end

  desc 'discover lists'
  task :discover => :environment do
    List.import_lists_from_sindresorhus
    List.import_lists_from_topic(topic: 'awesome-list')
    List.import_lists_from_topic(topic: 'awesome')  
  end

  desc 'output markdown'
  task :markdown => :environment do
    List.displayable.order(Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last).all.each do |list|
      next if list.description.blank?
      next if list.name.include?('?')
      puts "- [#{list.name}](#{list.url}) - #{list.awesome_description}"
    end
  end
end