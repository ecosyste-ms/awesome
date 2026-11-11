class AddLastSyncAttemptAtToLists < ActiveRecord::Migration[8.1]
  def change
    add_column :lists, :last_sync_attempt_at, :datetime
  end
end
