class AddStarsToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :stars, :integer, default: 0
  end
end
