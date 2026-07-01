module Brokerage
  class AccountsController < ApplicationController
    # GET /brokerage/accounts
    def index
      @brokerage_accounts = BrokerageAccount.includes(:brokerage_positions).all
    end

    # GET /brokerage/accounts/:id
    def show
      @brokerage_account = BrokerageAccount.includes(:brokerage_positions).find(params[:id])
    end

    # POST /brokerage/accounts/sync
    def sync
      TruthifiSyncJob.perform_later
      redirect_to brokerage_accounts_path, notice: "Sync started — refresh in a few seconds."
    end
  end
end
