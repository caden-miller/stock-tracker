module Brokerage
  class ConnectionsController < ApplicationController
    # POST /brokerage/connect
    # Initiates the SnapTrade OAuth flow for linking a brokerage account.
    # Phase 2: replace this stub with a redirect to SnapTrade's hosted auth URL.
    def new
      render plain: "Brokerage connection coming soon (Phase 2 — SnapTrade integration)"
    end
  end
end
