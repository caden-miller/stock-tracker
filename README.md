# Finance Monitor

Personal finance dashboard built with Ruby on Rails. Pulls live data from BofA, Empower, Fidelity, Capital One and 18,000+ other institutions via **Truthifi MCP** — a read-only financial aggregator. Displays net worth, money-flow Sankey, spending breakdown, cash-flow charts, top holdings, and recent transactions.

## Stack

- Ruby 3.3.x / Rails 7.0.8
- PostgreSQL
- Hotwire (Turbo + Stimulus) — live UX without a JS build step
- importmap-rails — no webpack/esbuild
- ruby-mcp-client — MCP JSON-RPC bridge to Truthifi
- Chartkick / D3-Sankey — charts

## Setup

```bash
bundle install
cp .env.example .env      # fill in DB credentials (see .env.example)
rails db:create db:migrate
rails server               # http://localhost:3000
```

Then visit `/truthifi/connect` to link your financial accounts via the Truthifi OAuth flow.

## Environment variables

See `.env.example` for all required keys and how to generate them.

## Architecture

All financial data flows through Truthifi's MCP endpoint. On connect, the app performs OAuth 2.1 + PKCE dynamic client registration and stores an encrypted access/refresh token. `TruthifiSyncJob` calls `TruthifiService#sync_all!` to pull accounts, positions, and transactions into local Postgres tables. The dashboard reads only from local tables, so it loads fast.

See `CLAUDE.md` for developer notes and `SPEC.md` for the full roadmap.
