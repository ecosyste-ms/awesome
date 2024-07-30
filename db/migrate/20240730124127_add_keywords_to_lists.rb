class AddKeywordsToLists < ActiveRecord::Migration[7.1]
  def change
    add_column :lists, :keywords, :string, array: true, default: []
    add_column :lists, :stars, :integer, default: 0
  end
end
