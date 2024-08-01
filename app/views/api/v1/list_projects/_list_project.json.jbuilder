json.extract! list_project, :id, :list_id, :project_id, :name, :description, :category, :sub_category, :created_at, :updated_at
json.project do
  if list_project.project
    json.partial! 'api/v1/projects/project', project: list_project.project
  else
    json.null!
  end
end