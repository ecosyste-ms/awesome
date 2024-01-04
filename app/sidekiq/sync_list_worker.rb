class SyncListWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(list_id)
    List.find_by_id(list_id).try(:sync)
  end
end