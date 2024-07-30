class AddIndexToProjectKeywords < ActiveRecord::Migration[7.1]
  def change
    add_index :projects, :keywords, using: 'gin'
  end
end
