class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.string :slug
      t.string :name
      t.string :short_description
      t.string :url
      t.integer :github_count
      t.string :created_by
      t.string :logo_url
      t.string :released
      t.string :wikipedia_url
      t.string :related_topics, array: true, default: []
      t.string :aliases, array: true, default: []
      t.string :github_url
      t.text :content

      t.timestamps
    end
  end
end
