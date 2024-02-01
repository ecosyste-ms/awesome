class AddDisplayableToLists < ActiveRecord::Migration[7.1]
  def change
    add_column :lists, :displayable, :boolean, default: false
  end
end
