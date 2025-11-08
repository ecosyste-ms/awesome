class AddPerformanceIndexesToListsAndProjects < ActiveRecord::Migration[8.0]
  def change
    add_index :lists, :keywords, using: :gin, if_not_exists: true
    add_index :projects, :keywords, using: :gin, if_not_exists: true
    add_index :lists, [:displayable, :stars], if_not_exists: true
    add_index :projects, [:list, :stars], if_not_exists: true
  end
end
