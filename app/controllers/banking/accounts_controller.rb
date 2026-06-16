module Banking
  class AccountsController < ApplicationController
    # GET /banking/accounts
    # Phase 3: list all Plaid-linked bank accounts for the current user.
    def index
      render plain: "Bank accounts coming soon (Phase 3 — Plaid integration)"
    end

    # GET /banking/accounts/:id
    # Phase 3: show transaction history for a single bank account.
    def show
      render plain: "Bank account detail coming soon (Phase 3)"
    end
  end
end
