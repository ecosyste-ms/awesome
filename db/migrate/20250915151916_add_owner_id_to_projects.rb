class AddOwnerIdToProjects < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :owner, foreign_key: true, index: true
  end
end
