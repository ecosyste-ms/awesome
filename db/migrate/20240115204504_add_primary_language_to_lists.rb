class AddPrimaryLanguageToLists < ActiveRecord::Migration[7.1]
  def change
    add_column :lists, :primary_language, :string
    add_column :lists, :list_of_lists, :boolean, default: false
  end
end
