module Banking
  class ConnectionsController < ApplicationController
    # Single-user app (no auth yet) — one Plaid client_user_id for the whole app.
    DEFAULT_USER_ID = "stock-tracker-default-user"

    skip_before_action :verify_authenticity_token, only: :webhook

    # GET /banking/connect
    # Creates a Plaid Link token and renders the Link widget.
    def new
      @link_token = PlaidService.create_link_token(client_user_id: DEFAULT_USER_ID)
    rescue PlaidService::Error => e
      redirect_to root_path, alert: e.message
    end

    # POST /banking/connect
    # Receives the public_token from the Plaid Link widget, exchanges it for an
    # access_token, and kicks off the first sync.
    def create
      plaid_item = PlaidService.exchange_public_token!(params.require(:public_token))
      BankSyncJob.perform_later(plaid_item.id)
      redirect_to banking_accounts_path, notice: "Bank account linked! Syncing your accounts now."
    rescue PlaidService::Error => e
      redirect_to banking_connect_path, alert: e.message
    end

    # POST /banking/webhook
    # Plaid pushes item/transaction update notifications here.
    def webhook
      payload = JSON.parse(request.body.read)
      plaid_item = PlaidItem.find_by(plaid_item_id: payload["item_id"])
      BankSyncJob.perform_later(plaid_item.id) if plaid_item
      head :ok
    end
  end
end
