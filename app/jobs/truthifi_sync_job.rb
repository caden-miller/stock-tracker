class TruthifiSyncJob < ApplicationJob
  queue_as :default

  def perform
    return unless TruthifiService.configured?

    TruthifiService.new.sync_all!
  rescue TruthifiService::Error => e
    Rails.logger.error("[TruthifiSyncJob] Sync failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    raise
  rescue StandardError => e
    Rails.logger.error("[TruthifiSyncJob] Sync failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    raise
  end
end
