# Stock Tracker — Spec Sheet

## Current State (as of June 2026)

### Tech Stack
- **Rails 7.0.8** / **Ruby 3.1.2** (both outdated; target Rails 8.x / Ruby 3.3+)
- **PostgreSQL** via `pg` gem
- **Hotwire** (Turbo + Stimulus) via importmap (no build step)
- **Sprockets** for assets
- **BasicYahooFinance** gem for live stock price quotes
- **dotenv-rails** for environment variables
- No authentication, no styling framework, no job queue wired up

### Existing Models & Schema

| Table | Columns |
|---|---|
| `stocks` | `symbol`, `name` |
| `stock_holdings` | `stock_id (FK)`, `quantity`, `purchase_price`, `purchase_date` |
| `balances` | `amount`, `date` |

### Existing Features
- **Stock Holdings** — manually track equity positions (ticker, quantity, buy price, buy date); index fetches live price from Yahoo Finance per holding and shows total portfolio value
- **Balances** — record a cash balance snapshot; `Balance#gains` attempts to calculate unrealized gains between balance snapshots
- **Seed data** — AAPL, GOOGL, MSFT pre-seeded; no UI to add new stocks

### Known Bugs / Technical Debt
1. `Balance#gains` references `StockQuote::Stock.quote` (a different gem) while the controller uses `BasicYahooFinance` — one of these will crash at runtime
2. `holding.current_price` / `holding.current_value` are assigned as ad-hoc instance variables in the controller but never declared as model attributes — fragile
3. No `Stock` create/edit UI; the only stocks available are the three seeded ones
4. Missing CRUD actions: no edit/update/destroy on `Balances` or `StockHoldings`
5. No error handling around Yahoo Finance API calls (network failure = 500)
6. No authentication — anyone can access and mutate data
7. Rails 7.0 / Ruby 3.1 are both EOL or approaching EOL
8. Zero styling; plain HTML tables with no layout

---

## Proposed Architecture

### Goals
Evolve the app into a **unified personal finance dashboard** that aggregates:
1. Brokerage accounts (equities, options, ETFs) via SnapTrade
2. Bank accounts and card transactions (checking, savings, credit, debit) via Plaid
3. Manual stock holdings (existing feature, kept for accounts not covered by APIs)
4. A net-worth / gain/loss overview page tying everything together

---

### Phase 1 — Foundation Cleanup

- Upgrade to **Rails 8.x** and **Ruby 3.3+**
- Add **Devise** for user authentication (each user owns their own holdings/balances)
- Add scope on all models to `belongs_to :user`
- Add missing CRUD (edit/destroy) for StockHoldings and Balances
- Add `Stock` creation UI so users can add arbitrary tickers
- Fix `Balance#gains` to use `BasicYahooFinance` consistently
- Declare `current_price` / `current_value` as `attr_accessor` on `StockHolding`
- Wrap all external API calls in error handling with graceful UI fallback
- Add **Tailwind CSS** (via `tailwindcss-rails`) for styling

---

### Phase 2 — Brokerage Integration (SnapTrade)

**API:** [SnapTrade](https://snaptrade.com) — free for personal use, supports 50+ brokerages including Fidelity, Schwab, TD Ameritrade, IBKR, Robinhood, Webull, etc.

**What it provides:**
- OAuth-based brokerage account linking (user logs in to their broker through SnapTrade's hosted UI)
- Account balances, positions, and order history
- Real-time and delayed quotes

**Note on Fidelity:** Fidelity does not expose a public API for retail customers. Access via SnapTrade is the supported path — SnapTrade connects through screen-scraping or Fidelity's open finance portal where available.

**New models:**
```
brokerage_connections  user_id, snaptrade_user_id, snaptrade_auth_token
brokerage_accounts     brokerage_connection_id, account_number, account_name, account_type, balance_cash
brokerage_positions    brokerage_account_id, symbol, quantity, average_purchase_price, current_price, current_value, last_synced_at
```

**Sync strategy:** Background job (Solid Queue, already in Rails 8) polls SnapTrade for each connected account on a schedule (e.g., every 15 minutes during market hours). Store results locally so the dashboard loads instantly.

**New routes:**
```
/brokerage/connect         → SnapTrade OAuth flow
/brokerage/accounts        → list all linked brokerage accounts + positions
/brokerage/accounts/:id    → per-account detail with position breakdown
```

---

### Phase 3 — Banking Integration (Plaid)

**API:** [Plaid](https://plaid.com) — the de-facto standard for US bank connectivity. Supports Capital One, Bank of America, Wells Fargo, Chase, Citi, and thousands more. Free development tier (up to 100 items).

**What it provides:**
- OAuth-based bank account linking via Plaid Link (hosted JS widget)
- Account balances (checking, savings, credit, debit)
- Transaction history (last 24 months on most institutions)
- Categorized spending data

**New models:**
```
plaid_items            user_id, plaid_access_token (encrypted), institution_id, institution_name
bank_accounts          plaid_item_id, plaid_account_id, name, type, subtype, current_balance, available_balance
bank_transactions      bank_account_id, plaid_transaction_id, date, name, merchant_name, amount, category, pending
```

**Security:** Plaid access tokens must be encrypted at rest (use `lockbox` or Rails 7.1+ `encrypts`). Never log them.

**Sync strategy:** Plaid webhooks push transaction updates in near-real-time. Store a webhook endpoint and process via background job.

**New routes:**
```
/banking/connect           → Plaid Link flow
/banking/accounts          → list all linked bank accounts
/banking/accounts/:id      → per-account transaction history with search/filter
/banking/spending          → spending breakdown by category (charts)
```

---

### Phase 4 — Unified Dashboard

**Home page / `/dashboard`:**
- Net worth = brokerage positions (current value) + bank balances − credit card balances
- Portfolio performance chart (time-series using stored `balances` snapshots)
- Recent transactions from all linked bank accounts
- Top holdings by current value
- Sector/asset allocation breakdown

**Tech for charts:** Chartkick + Groupdate (both Rails-friendly, work with importmap, no build step needed)

---

### API Key / Credentials Summary

| Service | Where to get | Free tier |
|---|---|---|
| SnapTrade | https://snaptrade.com/developers | Yes — personal use |
| Plaid | https://dashboard.plaid.com/signup | Yes — 100 items dev |
| Yahoo Finance (current) | Via `basic_yahoo_finance` gem | Unofficial; may break |
| Alpha Vantage (alternative) | https://www.alphavantage.co | Yes — 25 req/day |
| Polygon.io (alternative) | https://polygon.io | Yes — 5 calls/min |

Store all keys in Rails credentials (`rails credentials:edit`) or `.env` (already using dotenv-rails). Never commit secrets.

---

### Deferred / Out of Scope for Now
- Crypto portfolio (Coinbase/Binance APIs — can add in Phase 5)
- Tax lot tracking / realized gain/loss reporting
- Mobile app
- Bill pay or spending alerts
