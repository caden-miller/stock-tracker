module Brokerage
  class ConnectionsController < ApplicationController
    # Single-user app (no auth yet) — one SnapTrade user registered for the whole app.
    DEFAULT_USER_ID = "stock-tracker-default-user"

    # GET /brokerage/connect
    # Registers a SnapTrade user (first time only) and redirects to SnapTrade's
    # hosted Connection Portal to link a brokerage account.
    def new
      connection = BrokerageConnection.first || SnaptradeService.register!(user_id: DEFAULT_USER_ID)
      redirect_uri = SnaptradeService.new(connection).auth_url(custom_redirect: brokerage_callback_url)
      redirect_to redirect_uri, allow_other_host: true
    rescue SnaptradeService::Error => e
      redirect_to root_path, alert: e.message
    end

    # GET /brokerage/callback
    # SnapTrade redirects here once the user finishes connecting their brokerage.
    def callback
      connection = BrokerageConnection.first
      BrokerageSyncJob.perform_later(connection.id) if connection
      redirect_to brokerage_accounts_path, notice: "Brokerage account linked! Syncing your accounts now."
    end
  end
end
