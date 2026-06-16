module Banking
  class ConnectionsController < ApplicationController
    # POST /banking/connect
    # Initiates the Plaid Link flow for linking a bank account.
    # Phase 3: replace this stub with a Plaid Link token creation and JS widget launch.
    def new
      render plain: "Bank connection coming soon (Phase 3 — Plaid integration)"
    end
  end
end
