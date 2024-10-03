namespace :topics do
  desc 'Load featured topics from GitHub'
  task load_from_github: :environment do
    Topic.load_from_github
  end
end