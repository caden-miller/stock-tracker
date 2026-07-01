class DashboardController < ApplicationController
  def index
    @portfolio             = PortfolioService.new
    @truthifi_configured   = TruthifiService.configured?
    @last_synced_at        = last_synced_at
    @top_holdings          = BrokeragePosition.order(current_value: :desc).limit(10)
    @recent_transactions   = BankTransaction.order(date: :desc).limit(30)
    @spending_by_category  = spending_by_category
    @monthly_cash_flow     = monthly_cash_flow
    @sankey_data           = sankey_data
    @syncing               = Rails.cache.read("truthifi_sync_started_at").present?
  end

  def sync
    if TruthifiService.configured?
      Rails.cache.write("truthifi_sync_started_at", Time.current, expires_in: 5.minutes)
      TruthifiSyncJob.perform_later
      redirect_to dashboard_path, notice: "Sync queued — data will update momentarily."
    else
      redirect_to dashboard_path, alert: "Connect Truthifi first — visit /truthifi/connect."
    end
  end

  private

  def last_synced_at
    [
      BrokerageAccount.maximum(:last_synced_at),
      BankAccount.maximum(:updated_at)
    ].compact.max
  end

  # Positive amount = expense (Plaid/Truthifi convention).
  # Negative amount = income / credit.
  def spending_by_category
    BankTransaction
      .where("date >= ?", 30.days.ago)
      .where("amount > 0")
      .where.not(category: [nil, ""])
      .group(:category)
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(10)
      .to_h
  end

  def monthly_cash_flow
    (5).downto(0).each_with_object({}) do |n, hash|
      month = n.months.ago.beginning_of_month
      label = month.strftime("%b %Y")
      txns  = BankTransaction.where(date: month..(month.end_of_month))
      hash[label] = {
        income:   txns.where("amount < 0").sum("ABS(amount)"),
        expenses: txns.where("amount > 0").sum(:amount)
      }
    end.reverse_each.to_h
  end

  # Sankey: Income → Bank Accounts → Expense Categories
  def sankey_data
    cutoff   = 30.days.ago
    accounts = BankAccount.includes(:bank_transactions).to_a
    return { nodes: [], links: [] } if accounts.empty?

    nodes      = []
    links      = []
    node_index = {}

    # ── Income node ──────────────────────────────────────────────────────────
    total_income = BankTransaction.where("date >= ? AND amount < 0", cutoff).sum("ABS(amount)")
    if total_income.positive?
      nodes << { id: 0, label: "Income", group: "income" }
      node_index["income"] = 0
    end

    # ── Account nodes ────────────────────────────────────────────────────────
    accounts.each do |acct|
      idx = nodes.length
      label = acct.name.presence || acct.institution_name.presence || "Account"
      nodes << { id: idx, label: label, group: "account" }
      node_index["acct_#{acct.id}"] = idx
    end

    # ── Expense category nodes ───────────────────────────────────────────────
    categories = BankTransaction
      .where("date >= ? AND amount > 0", cutoff)
      .where.not(category: [nil, ""])
      .group(:category)
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(8)

    categories.each do |cat, _|
      idx = nodes.length
      label = cat.tr("_", " ").split.map(&:capitalize).join(" ")
      nodes << { id: idx, label: label, group: "expense" }
      node_index["cat_#{cat}"] = idx
    end

    # ── Links: income → accounts ─────────────────────────────────────────────
    if node_index["income"]
      accounts.each do |acct|
        acct_income = acct.bank_transactions
                          .where("date >= ? AND amount < 0", cutoff)
                          .sum("ABS(amount)")
        next unless acct_income.positive?
        links << {
          source: node_index["income"],
          target: node_index["acct_#{acct.id}"],
          value:  acct_income.to_f.round(2)
        }
      end
    end

    # ── Links: accounts → categories ─────────────────────────────────────────
    categories.each do |cat, _|
      accounts.each do |acct|
        cat_spend = acct.bank_transactions
                        .where("date >= ? AND amount > 0 AND category = ?", cutoff, cat)
                        .sum(:amount)
        next unless cat_spend.positive?
        links << {
          source: node_index["acct_#{acct.id}"],
          target: node_index["cat_#{cat}"],
          value:  cat_spend.to_f.round(2)
        }
      end
    end

    { nodes: nodes, links: links }
  end
end
