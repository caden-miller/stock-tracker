# CLAUDE.md — stock-tracker

## Project Overview

A personal finance dashboard built in Ruby on Rails. Current state: a basic manual stock portfolio tracker with live Yahoo Finance price lookups. Planned state: a full financial aggregation dashboard pulling from brokerage accounts (SnapTrade) and bank accounts (Plaid).

See `SPEC.md` for the full spec sheet including proposed architecture, API choices, and phased roadmap.

## Tech Stack

- **Ruby 3.1.2** / **Rails 7.0.8** — upgrade to Ruby 3.3+ / Rails 8.x is planned (Phase 1)
- **PostgreSQL** — primary database
- **Hotwire** (Turbo + Stimulus) — SPA-like UX without a JS build step
- **importmap-rails** — JS dependencies, no webpack/esbuild
- **Sprockets** — asset pipeline
- **BasicYahooFinance** — live stock price quotes (unofficial Yahoo Finance API)
- **dotenv-rails** — loads `.env` for local secrets

## Running Locally

```bash
bundle install
cp .env.example .env          # fill in credentials (see below)
rails db:create db:migrate db:seed
rails server
```

App runs on http://localhost:3000. Root route is `balances#index`.

## Environment Variables

```
# .env (never commit this file)
SNAPTRADE_CLIENT_ID=
SNAPTRADE_CONSUMER_KEY=
PLAID_CLIENT_ID=
PLAID_SECRET=
PLAID_ENV=sandbox            # sandbox | development | production
```

## Directory Structure

```
app/
  models/
    stock.rb            # ticker symbol + name; has_many :stock_holdings
    stock_holding.rb    # a position: stock_id, quantity, purchase_price, purchase_date
    balance.rb          # a cash balance snapshot; has gains calculation
  controllers/
    balances_controller.rb        # index, new, create
    stock_holdings_controller.rb  # index (fetches live prices), new, create
  views/
    balances/           # index (table + gains), new (form)
    stock_holdings/     # index (table + live prices), new (form)
db/
  schema.rb             # authoritative schema — read this first
  seeds.rb              # seeds AAPL, GOOGL, MSFT
```

## Current Data Model

```
stocks            { id, symbol, name }
stock_holdings    { id, stock_id→stocks, quantity, purchase_price, purchase_date }
balances          { id, amount, date }
```

## Known Issues (pre-cleanup)

1. `Balance#gains` calls `StockQuote::Stock.quote` — that gem is not in the Gemfile; only `BasicYahooFinance` is. This will raise `NameError` at runtime.
2. `holding.current_price` / `holding.current_value` are set as ad-hoc instance variables in the controller; no `attr_accessor` in the model. Works today, fragile.
3. No `Stock` create UI — users are limited to the three seeded tickers.
4. No edit/destroy actions on any resource.
5. No authentication — all data is global (single-user assumption).
6. No error handling around Yahoo Finance calls; network failure surfaces as a 500.

## Architecture Decisions

**Why SnapTrade over direct Fidelity API?**
Fidelity does not expose a public retail API. SnapTrade aggregates 50+ brokerages (including Fidelity) behind a single OAuth interface and has a free personal-use tier.

**Why Plaid for banking?**
Plaid has the widest US bank coverage (Capital One, BofA, Wells Fargo, Chase, etc.) and is the industry standard. The dev sandbox is free and lets you test with fake credentials before going live.

**Why Hotwire / importmap over React?**
The app was started with Rails defaults and there's no complex client-side state that requires a full SPA framework. Hotwire keeps things server-rendered with minimal JS overhead.

**Why Solid Queue (planned)?**
Rails 8 ships Solid Queue as the default background job backend (DB-backed, no Redis required). It's the natural choice for syncing brokerage/bank data on a schedule.

## Development Guidelines

- Run `rails test` before committing.
- All external API calls (Yahoo Finance, SnapTrade, Plaid) must have error handling; never let a failed HTTP call bubble up as a 500.
- Plaid access tokens are sensitive — encrypt at rest using Rails 7.1+ `encrypts` or `lockbox` gem. Do not log them.
- Store secrets in Rails credentials (`rails credentials:edit`) or `.env`. Never hardcode or commit secrets.
- When adding brokerage/bank sync jobs, scope the work to the minimum necessary — fetch only what changed, not full history on every run.
