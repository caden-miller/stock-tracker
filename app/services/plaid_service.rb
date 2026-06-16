# Plaid integration service — Phase 3
#
# Connects bank accounts via the Plaid Link JS widget and syncs balances/transactions
# into the local plaid_items/bank_accounts/bank_transactions tables.
class PlaidService
  class Error < StandardError; end

  def self.client
    configuration = Plaid::Configuration.new
    configuration.server_index = Plaid::Configuration::Environment.fetch(ENV.fetch("PLAID_ENV", "sandbox"))
    configuration.api_key["PLAID-CLIENT-ID"] = ENV.fetch("PLAID_CLIENT_ID")
    configuration.api_key["PLAID-SECRET"] = ENV.fetch("PLAID_SECRET")
    Plaid::PlaidApi.new(Plaid::ApiClient.new(configuration))
  end

  # Creates a Link token used to initialize the Plaid Link widget on the frontend.
  def self.create_link_token(client_user_id:)
    request = Plaid::LinkTokenCreateRequest.new(
      user: { client_user_id: client_user_id.to_s },
      client_name: "Stock Tracker",
      products: ["transactions"],
      country_codes: ["US"],
      language: "en"
    )
    client.link_token_create(request).link_token
  rescue Plaid::ApiError => e
    raise Error, "Plaid link token creation failed: #{e.message}"
  end

  # Exchanges a Link public_token for a permanent access_token and persists a PlaidItem.
  def self.exchange_public_token!(public_token)
    request = Plaid::ItemPublicTokenExchangeRequest.new(public_token: public_token)
    response = client.item_public_token_exchange(request)

    PlaidItem.create!(
      plaid_item_id: response.item_id,
      plaid_access_token: response.access_token
    )
  rescue Plaid::ApiError => e
    raise Error, "Plaid token exchange failed: #{e.message}"
  end

  def initialize(plaid_item)
    @plaid_item = plaid_item
    @client = self.class.client
  end

  # Fetches current balances for all accounts under this item and upserts them locally.
  def sync_accounts!
    request = Plaid::AccountsBalanceGetRequest.new(access_token: @plaid_item.plaid_access_token)
    accounts = @client.accounts_balance_get(request).accounts

    accounts.each do |account|
      local_account = @plaid_item.bank_accounts.find_or_initialize_by(plaid_account_id: account.account_id)
      local_account.update!(
        name: account.name,
        official_name: account.official_name,
        account_type: account.type,
        account_subtype: account.subtype,
        current_balance: account.balances&.current,
        available_balance: account.balances&.available,
        iso_currency_code: account.balances&.iso_currency_code || "USD"
      )
    end
  rescue Plaid::ApiError => e
    raise Error, "Plaid account sync failed: #{e.message}"
  end

  # Pages through transactions_sync and upserts new/updated transactions locally.
  def sync_transactions!
    cursor = @plaid_item.sync_cursor
    loop do
      request = Plaid::TransactionsSyncRequest.new(access_token: @plaid_item.plaid_access_token, cursor: cursor)
      response = @client.transactions_sync(request)

      (response.added + response.modified).each { |transaction| upsert_transaction(transaction) }
      response.removed.each { |removed| BankTransaction.where(plaid_transaction_id: removed.transaction_id).destroy_all }

      cursor = response.next_cursor
      break unless response.has_more
    end
    @plaid_item.update!(sync_cursor: cursor)
  rescue Plaid::ApiError => e
    raise Error, "Plaid transaction sync failed: #{e.message}"
  end

  private

  def upsert_transaction(transaction)
    bank_account = @plaid_item.bank_accounts.find_by(plaid_account_id: transaction.account_id)
    return unless bank_account

    record = bank_account.bank_transactions.find_or_initialize_by(plaid_transaction_id: transaction.transaction_id)
    record.update!(
      date: transaction.date,
      name: transaction.name,
      merchant_name: transaction.merchant_name,
      amount: transaction.amount,
      category: transaction.personal_finance_category&.primary,
      subcategory: transaction.personal_finance_category&.detailed,
      pending: transaction.pending,
      iso_currency_code: transaction.iso_currency_code || "USD"
    )
  end
end
