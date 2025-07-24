class ChangeStarsToBigintInProjects < ActiveRecord::Migration[8.0]
  def change
    change_column :projects, :stars, :bigint, default: 0
    change_column :lists, :stars, :bigint, default: 0
  end
end
