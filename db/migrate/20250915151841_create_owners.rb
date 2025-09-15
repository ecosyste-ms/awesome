class CreateOwners < ActiveRecord::Migration[8.0]
  def change
    create_table :owners do |t|
      t.string :name, null: false
      t.boolean :hidden, default: false
      t.timestamps
    end

    add_index :owners, :name, unique: true
    add_index :owners, :hidden
  end
end
