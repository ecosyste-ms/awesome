namespace :takedown do
  desc "Hide a user and remove their projects. LOGIN=username"
  task hide_user: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    owner = Owner.find_or_create_by!(name: login.downcase)
    owner.update!(hidden: true)
    puts "[awesome] hidden owner #{owner.name}"

    projects = Project.where(owner_id: owner.id).or(Project.where('lower(owner) = ?', login.downcase))
    count = projects.count
    projects.find_each do |project|
      puts "[awesome] destroying #{project.url}"
      project.destroy
    end
    puts "[awesome] destroyed #{count} projects for #{login}"
  end

  desc "Report what exists for a user. LOGIN=username"
  task report: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    owner = Owner.find_by(name: login.downcase)
    project_count = if owner
      Project.where(owner_id: owner.id).or(Project.where('lower(owner) = ?', login.downcase)).count
    else
      Project.where('lower(owner) = ?', login.downcase).count
    end
    puts "[awesome] #{login}: owner=#{owner ? (owner.hidden? ? 'hidden' : 'visible') : 'none'} projects=#{project_count}"
  end
end
