class AddLastSyncAttemptAtIndexToProjects < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :projects, :last_sync_attempt_at,
              where: "last_sync_attempt_at IS NOT NULL",
              algorithm: :concurrently
  end
end
