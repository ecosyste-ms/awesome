class AddNaturalLanguageToLists < ActiveRecord::Migration[8.1]
  def change
    add_column :lists, :natural_language, :string
  end
end
