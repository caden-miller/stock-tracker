# CLAUDE.md — Finance Monitor

## Project Overview

Personal finance monitoring dashboard built in Ruby on Rails. Pulls live data from BofA, Empower, Fidelity, Capital One and 18,000+ other institutions via the **Truthifi MCP** (`https://api.truthifi.com/mcp`) — a read-only financial aggregator that normalizes data across institutions. Displays net worth, Sankey money-flow, spending breakdowns, top holdings, and cash-flow charts.

See `SPEC.md` for the full spec sheet.

## Tech Stack

- **Ruby 3.3.x** / **Rails 7.0.8**
- **PostgreSQL** — primary database
- **Hotwire** (Turbo + Stimulus) — SPA-like UX without a JS build step
- **importmap-rails** — JS dependencies, no webpack/esbuild
- **Sprockets** + plain CSS design system
- **ruby-mcp-client** — MCP JSON-RPC client for Truthifi
- **Chartkick** — bar/column charts; **D3 Sankey** — money-flow diagram
- **dotenv-rails** — loads `.env` for local secrets

## Running Locally

```bash
bundle install
cp .env.example .env          # fill in DB credentials
rails db:create db:migrate
rails server
```

App runs on `http://localhost:3000`. Root route is `dashboard#index`.

Then visit `/truthifi/connect` to link your financial accounts through the Truthifi OAuth 2.1 flow.

## Environment Variables

```
DATABASE_USER=caden
DATABASE_PASSWORD=...
DATABASE_PORT=5433

# OAuth redirect — must match port the app runs on
TRUTHIFI_REDIRECT_URI=http://localhost:3000/truthifi/callback

# Active Record encryption for TruthifiConnection tokens
AR_ENCRYPTION_PRIMARY_KEY=...
AR_ENCRYPTION_DETERMINISTIC_KEY=...
AR_ENCRYPTION_KEY_DERIVATION_SALT=...
```

No static API token is required — authentication is fully OAuth 2.1 + PKCE via the connect flow.

## Directory Structure

```
app/
  controllers/
    dashboard_controller.rb         # main dashboard — index (widgets), sync (queues job)
    truthifi/connections_controller.rb  # OAuth 2.1 connect/callback/disconnect
  services/
    truthifi_service.rb             # MCP client — sync_all!, sync_accounts!, sync_positions!, sync_transactions!
    truthifi_oauth.rb               # OAuth 2.1 + DCR (Dynamic Client Registration) helpers
    portfolio_service.rb            # aggregates brokerage + bank totals for net worth display
  jobs/
    truthifi_sync_job.rb            # background job: TruthifiService.new.sync_all!
  models/
    truthifi_connection.rb          # stores encrypted access_token + refresh_token
  views/
    dashboard/index.html.erb        # Sankey, spending chart, cash flow, top holdings, recent transactions
db/
  schema.rb                         # authoritative schema
```

## Data Model

```
truthifi_connections  { client_id, access_token (enc), refresh_token (enc), token_expires_at }
brokerage_accounts    { truthifi_account_id, institution_name, account_name, account_type, cash_balance, last_synced_at }
brokerage_positions   { brokerage_account_id→, symbol, quantity, average_purchase_price, current_price, current_value }
bank_accounts         { truthifi_account_id, institution_name, name, account_type, account_subtype, current_balance, available_balance }
bank_transactions     { bank_account_id→, truthifi_transaction_id, date, name, merchant_name, amount, category, pending }
benchmark_prices      { symbol, date, close_price }  — historical closes for SPY/QQQ/AGG/VTI
balances              { amount, date }               — manual net-worth snapshots
```

## Truthifi MCP Flow

1. User visits `/truthifi/connect`
2. App performs Dynamic Client Registration (RFC 7591) to get a `client_id`
3. App builds PKCE authorization URL and redirects user to `https://app.truthifi.com/oauth/consent`
4. User authorizes → Truthifi redirects to `/truthifi/callback`
5. App exchanges code for access + refresh tokens, saves to `truthifi_connections` (encrypted at rest)
6. `TruthifiSyncJob` is enqueued; `TruthifiService` calls the MCP endpoint to pull accounts, positions, transactions

## Development Guidelines

- Run `rails test` before committing.
- All MCP / external API calls must have error handling; never let a failed call bubble to a 500.
- `access_token` and `refresh_token` are encrypted at rest via `ActiveRecord::Encrypts`. Do not log them.
- Store secrets in `.env`. Never hardcode or commit secrets.
- When adding sync logic, fetch only what changed — not full history on every run.
