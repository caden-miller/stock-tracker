module Banking
  class AccountsController < ApplicationController
    # GET /banking/accounts
    def index
      @bank_accounts = BankAccount.order(:name)
    end

    # GET /banking/accounts/:id
    def show
      @bank_account = BankAccount.find(params[:id])
      @bank_transactions = @bank_account.bank_transactions.order(date: :desc).limit(100)
    end

    # POST /banking/accounts/sync
    def sync
      TruthifiSyncJob.perform_later
      redirect_to banking_accounts_path, notice: "Sync started — refresh in a few seconds."
    end
  end
end
