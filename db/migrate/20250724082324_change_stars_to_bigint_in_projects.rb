class ChangeStarsToBigintInProjects < ActiveRecord::Migration[8.0]
  def change
    execute "SET statement_timeout = 0"
    change_column :projects, :stars, :bigint, default: 0
    change_column :lists, :stars, :bigint, default: 0
    execute "SET statement_timeout = '30s'"
  end
end
