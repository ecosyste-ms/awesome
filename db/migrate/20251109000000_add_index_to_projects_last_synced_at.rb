class AddIndexToProjectsLastSyncedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :projects, :last_synced_at
  end
end
