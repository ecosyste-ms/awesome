class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :projects, :url, unique: true
    add_index :lists, :url, unique: true
    add_index :list_projects, :project_id
    add_index :list_projects, :list_id
  end
end
