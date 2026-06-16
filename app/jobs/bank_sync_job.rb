class BankSyncJob < ApplicationJob
  queue_as :default

  def perform(plaid_item_id)
    plaid_item = PlaidItem.find(plaid_item_id)
    service = PlaidService.new(plaid_item)
    service.sync_accounts!
    service.sync_transactions!
  rescue PlaidService::Error => e
    Rails.logger.error("BankSyncJob failed for item #{plaid_item_id}: #{e.message}")
  end
end
