# Truthifi MCP integration service.
#
# Connects to the Truthifi MCP server at https://api.truthifi.com/mcp using an
# OAuth 2.1 access token stored in TruthifiConnection. Run the connect flow at
# /truthifi/connect to authorize and store the token.
class TruthifiService
  class Error < StandardError; end
  class NotConfiguredError < Error; end
  class SyncError < Error; end

  MCP_ENDPOINT = "https://api.truthifi.com/mcp".freeze

  # Candidate tool names for each data type, tried in order.
  ACCOUNT_TOOLS     = %w[list_accounts get_accounts accounts get_financial_data].freeze
  HOLDING_TOOLS     = %w[list_holdings get_holdings list_positions get_positions holdings positions get_portfolio].freeze
  TRANSACTION_TOOLS = %w[list_transactions get_transactions transactions recent_transactions list_recent_transactions].freeze

  INVESTMENT_ACCOUNT_TYPES = %w[investment brokerage retirement ira 401k].freeze
  BANK_ACCOUNT_TYPES       = %w[depository credit loan mortgage].freeze

  def self.configured?
    TruthifiConnection.current.present?
  end

  def initialize
    @connection = TruthifiConnection.current
    raise NotConfiguredError, "No Truthifi connection — visit /truthifi/connect" unless @connection
    @connection.refresh! if @connection.expired?
    @token = @connection.access_token
  end

  def sync_all!
    sync_accounts!
    sync_positions!
    sync_transactions!
  rescue MCPClient::Errors::MCPError => e
    raise SyncError, "Truthifi MCP error: #{e.message}"
  end

  # ── Public sync methods ────────────────────────────────────────────────────

  def sync_accounts!
    data = call_first_matching_tool(ACCOUNT_TOOLS)
    return unless data

    accounts = extract_array(data, %w[accounts data])
    accounts.each { |acct| upsert_account(acct) }
  end

  def sync_positions!
    data = call_first_matching_tool(HOLDING_TOOLS)
    return unless data

    holdings = extract_array(data, %w[holdings positions data])
    holdings.each { |h| upsert_position(h) }
  end

  def sync_transactions!
    data = call_first_matching_tool(TRANSACTION_TOOLS)
    return unless data

    transactions = extract_array(data, %w[transactions data])
    transactions.each { |txn| upsert_transaction(txn) }
  end

  private

  # ── MCP client ─────────────────────────────────────────────────────────────

  def client
    @client ||= MCPClient.connect(
      MCP_ENDPOINT,
      headers: { "Authorization" => "Bearer #{@token}" },
      read_timeout: 60,
      retries: 2
    )
  end

  def available_tools
    @available_tools ||= client.list_tools.map(&:name)
  rescue => e
    raise SyncError, "Failed to list Truthifi tools: #{e.message}"
  end

  def call_first_matching_tool(candidates)
    tool_name = candidates.find { |t| available_tools.include?(t) }
    return nil unless tool_name

    result = client.call_tool(tool_name, {})
    parse_mcp_result(result)
  rescue MCPClient::Errors::MCPError, StandardError => e
    Rails.logger.error("[TruthifiService] Tool call failed (#{tool_name}): #{e.class}: #{e.message}")
    raise SyncError, "Tool call failed (#{tool_name}): #{e.message}"
  end

  # MCP tool results are returned as either structured content or a JSON text blob.
  # The gem hands back the full JSON-RPC result object, e.g.
  #   { "content" => [{ "type" => "text", "text" => "{...json...}" }], "isError" => false }
  #   { "content" => [...], "structuredContent" => { "accounts" => [...] } }
  def parse_mcp_result(result)
    if result.is_a?(Hash)
      # Structured content (preferred — tools that define output schemas)
      structured = result["structuredContent"] || result[:structuredContent]
      return structured if structured.is_a?(Hash) && structured.any?

      content = result["content"] || result[:content]
    else
      # Array or other — treat the value itself as the content array
      content = result
    end

    # Text content block: [{type: "text", text: "{...json...}"}]
    content = Array(content)
    text_block = content.find do |block|
      (block.respond_to?(:type) ? block.type : block["type"]) == "text"
    end
    return nil unless text_block

    text = text_block.respond_to?(:text) ? text_block.text : text_block["text"]
    JSON.parse(text)
  rescue JSON::ParserError
    nil
  end

  # Pull a list from a hash by trying multiple key candidates.
  def extract_array(data, key_candidates)
    return Array(data) if data.is_a?(Array)
    return [] unless data.is_a?(Hash)

    key_candidates.each do |key|
      val = data[key] || data[key.to_sym]
      return Array(val) if val.is_a?(Array)
    end
    []
  end

  # ── Upsert helpers ─────────────────────────────────────────────────────────

  def upsert_account(acct)
    id     = str(acct, "id", "account_id")
    return unless id.present?

    type   = str(acct, "type", "account_type").to_s.downcase
    inst   = str(acct, "institution", "institution_name", "bank")
    name   = str(acct, "name", "account_name")
    bal    = dig_balance(acct, "current", "current_balance")
    avail  = dig_balance(acct, "available", "available_balance")
    sub    = str(acct, "subtype", "account_subtype").to_s.downcase

    if INVESTMENT_ACCOUNT_TYPES.any? { |t| type.include?(t) || sub.include?(t) }
      upsert_brokerage_account(id, inst, name, type, sub, bal)
    else
      upsert_bank_account(id, inst, name, type, sub, bal, avail)
    end
  end

  def upsert_brokerage_account(id, inst, name, type, sub, cash)
    record = BrokerageAccount.find_or_initialize_by(truthifi_account_id: id)
    record.assign_attributes(
      institution_name: inst,
      account_name:     name,
      account_type:     sub.presence || type,
      cash_balance:     cash,
      last_synced_at:   Time.current
    )
    record.save!
  end

  def upsert_bank_account(id, inst, name, type, sub, current, available)
    record = BankAccount.find_or_initialize_by(truthifi_account_id: id)
    record.assign_attributes(
      institution_name:  inst,
      name:              name,
      account_type:      type,
      account_subtype:   sub,
      current_balance:   current,
      available_balance: available,
      iso_currency_code: "USD"
    )
    record.save!
  end

  def upsert_position(holding)
    account_id = str(holding, "account_id", "accountId")
    symbol     = str(holding, "symbol", "ticker")
    return if account_id.blank? || symbol.blank?

    account = BrokerageAccount.find_by(truthifi_account_id: account_id)
    return unless account

    qty    = dec(holding, "quantity", "units", "shares")
    cost   = dec(holding, "cost_basis", "average_cost", "average_purchase_price")
    price  = dec(holding, "market_price", "price", "current_price")
    value  = dec(holding, "total_value", "market_value", "current_value") ||
             (qty && price ? qty * price : nil)
    desc   = str(holding, "description", "name", "security_name")

    record = account.brokerage_positions.find_or_initialize_by(symbol: symbol)
    record.assign_attributes(
      description:           desc,
      quantity:              qty,
      average_purchase_price: cost,
      current_price:         price,
      current_value:         value,
      last_synced_at:        Time.current
    )
    record.save!
  end

  def upsert_transaction(txn)
    txn_id = str(txn, "id", "transaction_id", "transactionId")
    return unless txn_id.present?

    account_id = str(txn, "account_id", "accountId")
    account    = BankAccount.find_by(truthifi_account_id: account_id)
    return unless account

    date     = parse_date(str(txn, "date", "posted_date"))
    return unless date

    amount   = dec(txn, "amount")
    name     = str(txn, "name", "description")
    merchant = str(txn, "merchant", "merchant_name", "merchantName")
    category = str(txn, "category", "personal_finance_category")
    subcat   = str(txn, "subcategory", "detailed_category")
    pending  = txn["pending"] || txn[:pending] || false

    record = account.bank_transactions.find_or_initialize_by(truthifi_transaction_id: txn_id)
    record.assign_attributes(
      date:              date,
      name:              name,
      merchant_name:     merchant,
      amount:            amount,
      category:          category&.upcase,
      subcategory:       subcat,
      pending:           pending,
      iso_currency_code: "USD"
    )
    record.save!
  end

  # ── Field-extraction helpers ───────────────────────────────────────────────

  def str(hash, *keys)
    keys.each do |k|
      v = hash[k] || hash[k.to_sym]
      return v.to_s.strip if v.present?
    end
    nil
  end

  def dec(hash, *keys)
    keys.each do |k|
      v = hash[k] || hash[k.to_sym]
      return v.to_d if v.present?
    end
    nil
  end

  def dig_balance(acct, *balance_keys)
    # Balance may be a nested hash: { balance: { current: 1234 } }
    bal = acct["balance"] || acct[:balance]
    if bal.is_a?(Hash)
      balance_keys.each do |k|
        v = bal[k] || bal[k.to_sym]
        return v.to_d if v.present?
      end
    end
    # Or a flat field like current_balance, balance
    dec(acct, *balance_keys, "balance", "total_balance")
  end

  def parse_date(str)
    return nil unless str.present?
    Date.parse(str)
  rescue ArgumentError, TypeError
    nil
  end
end
