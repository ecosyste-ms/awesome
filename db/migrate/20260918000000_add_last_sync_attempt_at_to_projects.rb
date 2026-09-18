class AddLastSyncAttemptAtToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :last_sync_attempt_at, :datetime
  end
end
