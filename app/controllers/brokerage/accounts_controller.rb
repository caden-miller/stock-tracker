module Brokerage
  class AccountsController < ApplicationController
    # GET /brokerage/accounts
    # Phase 2: list all SnapTrade-linked brokerage accounts for the current user.
    def index
      render plain: "Brokerage accounts coming soon (Phase 2 — SnapTrade integration)"
    end

    # GET /brokerage/accounts/:id
    # Phase 2: show positions for a single brokerage account.
    def show
      render plain: "Brokerage account detail coming soon (Phase 2)"
    end
  end
end
