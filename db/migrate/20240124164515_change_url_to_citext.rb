class ChangeUrlToCitext < ActiveRecord::Migration[7.1]
  def change
    enable_extension :citext
    change_column :lists, :url, :citext
  end
end
