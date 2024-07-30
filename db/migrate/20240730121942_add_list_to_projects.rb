class AddListToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :list, :boolean, default: false
  end
end
