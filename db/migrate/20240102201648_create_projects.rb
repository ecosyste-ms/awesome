class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :url
      t.json :repository
      t.text :readme
      t.string :keywords, array: true, default: []
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
