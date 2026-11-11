module SyncScheduling
  extend ActiveSupport::Concern

  class_methods do
    # Picks up to SYNC_BATCH_SIZE ids from scope, reserving SYNC_RETRY_BATCH_SIZE
    # slots for records whose last sync failed at least SYNC_RETRY_INTERVAL ago,
    # so records that keep failing can't crowd out first attempts (or vice versa).
    def sync_candidate_ids(scope)
      retry_ids = scope.where("last_sync_attempt_at <= ?", self::SYNC_RETRY_INTERVAL.ago)
                       .reorder(:last_sync_attempt_at).limit(self::SYNC_BATCH_SIZE).pluck(:id)
      reserved_retry_ids = retry_ids.first(self::SYNC_RETRY_BATCH_SIZE)
      first_attempt_ids = scope.where(last_sync_attempt_at: nil).limit(self::SYNC_BATCH_SIZE - reserved_retry_ids.length).pluck(:id)
      remaining = self::SYNC_BATCH_SIZE - first_attempt_ids.length - reserved_retry_ids.length

      first_attempt_ids + reserved_retry_ids + retry_ids.drop(self::SYNC_RETRY_BATCH_SIZE).first(remaining)
    end
  end
end
