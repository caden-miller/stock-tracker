class BrokerageSyncJob < ApplicationJob
  queue_as :default

  def perform(brokerage_connection_id)
    connection = BrokerageConnection.find(brokerage_connection_id)
    SnaptradeService.new(connection).sync_accounts!
  rescue SnaptradeService::Error => e
    Rails.logger.error("BrokerageSyncJob failed for connection #{brokerage_connection_id}: #{e.message}")
  end
end
