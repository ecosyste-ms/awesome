class AddStarsIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :projects, :stars
    add_index :lists, :stars
  end
end
