class SyncProjectWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(project_id)
    Project.find_by_id(project_id).try(:sync)
  end
end