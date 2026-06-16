module Brokerage
  class AccountsController < ApplicationController
    # GET /brokerage/accounts
    def index
      @connection = BrokerageConnection.first
      @brokerage_accounts = @connection ? @connection.brokerage_accounts.includes(:brokerage_positions) : BrokerageAccount.none
    end

    # GET /brokerage/accounts/:id
    def show
      @brokerage_account = BrokerageAccount.includes(:brokerage_positions).find(params[:id])
    end

    # POST /brokerage/accounts/sync
    def sync
      connection = BrokerageConnection.first
      if connection
        BrokerageSyncJob.perform_later(connection.id)
        redirect_to brokerage_accounts_path, notice: "Sync started — refresh in a few seconds."
      else
        redirect_to brokerage_connect_path, alert: "Link a brokerage account first."
      end
    end
  end
end
