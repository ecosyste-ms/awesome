class ListProject < ApplicationRecord
  belongs_to :list
  belongs_to :project

  def to_s
    project.try(:name) || name
  end

  def url
    project.try(:url) || find_url
  end

  def find_url
    list.readme_links.first{|link| link[:name] == name}[:url]
  end
end
