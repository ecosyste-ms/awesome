class AddOwnerToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :owner, :string
  end
end
