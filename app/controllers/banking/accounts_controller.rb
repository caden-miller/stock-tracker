module Banking
  class AccountsController < ApplicationController
    # GET /banking/accounts
    def index
      @bank_accounts = BankAccount.includes(:plaid_item).order(:name)
    end

    # GET /banking/accounts/:id
    def show
      @bank_account = BankAccount.find(params[:id])
      @bank_transactions = @bank_account.bank_transactions.order(date: :desc).limit(100)
    end

    # POST /banking/accounts/sync
    def sync
      items = PlaidItem.all
      if items.any?
        items.each { |item| BankSyncJob.perform_later(item.id) }
        redirect_to banking_accounts_path, notice: "Sync started — refresh in a few seconds."
      else
        redirect_to banking_connect_path, alert: "Link a bank account first."
      end
    end
  end
end
