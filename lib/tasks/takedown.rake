namespace :takedown do
  desc "Hide a user and remove their projects. LOGIN=username"
  task hide_user: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    ActiveRecord::Base.connection.execute("SET statement_timeout = 0")

    owner = Owner.find_or_create_by!(name: login.downcase)
    owner.update!(hidden: true)
    puts "[awesome] hidden owner #{owner.name}"

    ids = Project.where(owner_id: owner.id).pluck(:id)
    ids |= Project.where(owner: login).pluck(:id)
    puts "[awesome] found #{ids.length} projects for #{login}"

    Project.where(id: ids).find_each do |project|
      puts "[awesome] destroying #{project.url}"
      project.destroy
    end
    puts "[awesome] destroyed #{ids.length} projects for #{login}"
  end

  desc "Report what exists for a user. LOGIN=username"
  task report: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    owner = Owner.find_by(name: login.downcase)
    ids = owner ? Project.where(owner_id: owner.id).pluck(:id) : []
    ids |= Project.where(owner: login).pluck(:id)
    puts "[awesome] #{login}: owner=#{owner ? (owner.hidden? ? 'hidden' : 'visible') : 'none'} projects=#{ids.length}"
  end
end
