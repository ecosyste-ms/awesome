class RemoveDuplicateIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :list_projects, :list_id
    remove_index :projects, :list
  end
end
