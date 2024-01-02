class CreateLists < ActiveRecord::Migration[7.1]
  def change
    create_table :lists do |t|
      t.string :url
      t.string :name
      t.string :description
      t.integer :projects_count
      t.datetime :last_synced_at
      t.json :repository
      t.text :readme

      t.timestamps
    end
  end
end
