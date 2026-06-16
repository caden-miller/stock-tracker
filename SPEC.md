# Stock Tracker — Spec Sheet

## Status (as of 2026-06-16)

Branch: `update` — pushed to GitHub, not yet merged to `main`. Verified running locally (Ruby 3.3.6, Postgres 16, seeded DB, server smoke-tested + browser-tested with Playwright).

### Phase 1 — Foundation Cleanup
- [x] Bump Ruby to 3.3.6 (`.ruby-version`, `Gemfile`)
- [x] Fix `Balance#gains` to use `BasicYahooFinance` consistently
- [x] Declare `current_price` / `current_value` as `attr_accessor` on `StockHolding`
- [x] Wrap Yahoo Finance calls in error handling (verified live: Yahoo's API returned HTTP 429 in this sandbox, app degraded gracefully to "N/A" instead of a 500)
- [x] Add model validations (Stock, StockHolding, Balance)
- [x] Add `Stock` create/edit/destroy UI
- [x] Add edit/destroy to Balances and StockHoldings
- [x] Reusable UI components + color palette design system (`button_link`/`delete_link` helpers, `.card`/`.field`/`.actions`/`.flash` CSS classes, dark-mode via `prefers-color-scheme`)
- [ ] Upgrade Rails 7.0.8 → 8.x (not yet started — bigger lift, do separately)
- [ ] Add authentication (Devise) — gem is stubbed commented in Gemfile
- [ ] Write/update test coverage for the new CRUD actions (existing tests predate these changes)

### Phase 2 — Brokerage (SnapTrade)
- [x] Migrations for `brokerage_connections`, `brokerage_accounts`, `brokerage_positions`
- [x] Stub `Brokerage::ConnectionsController` / `AccountsController` + routes
- [x] Stub `SnaptradeService` with commented SDK calls
- [ ] Real SnapTrade account creation + API keys
- [ ] OAuth connect flow implementation
- [ ] Background sync job

### Phase 3 — Banking (Plaid)
- [x] Migrations for `plaid_items`, `bank_accounts`, `bank_transactions`
- [x] Stub `Banking::ConnectionsController` / `AccountsController` + routes
- [x] Stub `PlaidService` with commented SDK calls
- [ ] Real Plaid account + API keys
- [ ] Plaid Link JS widget integration
- [ ] Webhook endpoint + background sync
- [ ] Encrypt `plaid_access_token` at rest

### Phase 4 — Unified Dashboard
- [ ] Not started

### Known Bugs / Technical Debt (resolved unless noted)
1. ~~`Balance#gains` referenced a missing gem~~ — fixed
2. ~~`current_price`/`current_value` ad-hoc instance vars~~ — fixed
3. ~~No `Stock` create/edit UI~~ — fixed
4. ~~Missing CRUD actions~~ — fixed
5. ~~No error handling around Yahoo Finance calls~~ — fixed
6. No authentication — anyone can access and mutate data (Phase 1 remaining item)
7. Rails 7.0 is approaching EOL — Ruby is now current (3.3.6), Rails upgrade still pending
8. ~~Zero styling~~ — fixed (design system added)
9. **New finding:** the unofficial `basic_yahoo_finance` gem is unreliable in this environment — Yahoo's endpoint returned HTTP 429 during testing. This validates the SnapTrade/Plaid migration path; consider a paid quote API (Alpha Vantage, Polygon.io) as a stopgap if live prices are needed before Phase 2 lands.

### Tech Stack (current)
- **Rails 7.0.8** / **Ruby 3.3.6**
- **PostgreSQL 16** via `pg` gem
- **Hotwire** (Turbo + Stimulus) via importmap (no build step)
- **Sprockets** for assets, plain CSS design system (no Tailwind yet)
- **BasicYahooFinance** gem for live stock price quotes (unreliable — see above)
- **dotenv-rails** for environment variables

### Schema

| Table | Columns |
|---|---|
| `stocks` | `symbol`, `name` |
| `stock_holdings` | `stock_id (FK)`, `quantity`, `purchase_price`, `purchase_date` |
| `balances` | `amount`, `date` |
| `brokerage_connections` *(Phase 2, unused)* | `snaptrade_user_id`, `snaptrade_auth_token`, `broker_name` |
| `brokerage_accounts` *(Phase 2, unused)* | `brokerage_connection_id (FK)`, account details |
| `brokerage_positions` *(Phase 2, unused)* | `brokerage_account_id (FK)`, position details |
| `plaid_items` *(Phase 3, unused)* | `plaid_item_id`, `plaid_access_token`, institution info |
| `bank_accounts` *(Phase 3, unused)* | `plaid_item_id (FK)`, balance info |
| `bank_transactions` *(Phase 3, unused)* | `bank_account_id (FK)`, transaction info |

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
