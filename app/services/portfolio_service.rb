# Aggregates real account data (synced from SnapTrade + Plaid) into the figures
# shown on the balances page: per-account breakdown and total net worth.
class PortfolioService
  # Plaid reports `current_balance` as a positive amount owed for credit/loan
  # accounts, so those subtract from net worth instead of adding to it.
  LIABILITY_ACCOUNT_TYPES = %w[credit loan].freeze

  def self.net_worth
    new.net_worth
  end

  def brokerage_accounts
    @brokerage_accounts ||= BrokerageAccount.includes(:brokerage_positions)
  end

  def bank_accounts
    @bank_accounts ||= BankAccount.all
  end

  def brokerage_total
    brokerage_accounts.sum { |account| account_total(account) }
  end

  def bank_total
    bank_accounts.sum { |account| bank_account_value(account) }
  end

  def net_worth
    brokerage_total + bank_total
  end

  def account_total(account)
    (account.cash_balance || 0) + account.brokerage_positions.sum { |p| p.current_value || 0 }
  end

  def bank_account_value(account)
    balance = account.current_balance || 0
    LIABILITY_ACCOUNT_TYPES.include?(account.account_type) ? -balance : balance
  end
end
