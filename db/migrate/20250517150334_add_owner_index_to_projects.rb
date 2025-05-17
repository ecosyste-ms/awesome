class AddOwnerIndexToProjects < ActiveRecord::Migration[8.0]
  def change
    add_index :projects, :owner
  end
end
