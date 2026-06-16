# SnapTrade integration service — Phase 2
#
# Connects brokerage accounts via SnapTrade's hosted OAuth Connection Portal and
# syncs accounts/positions into the local brokerage_accounts/brokerage_positions tables.
class SnaptradeService
  class Error < StandardError; end

  def self.client
    configuration = SnapTrade::Configuration.new
    configuration.client_id = ENV.fetch("SNAPTRADE_CLIENT_ID")
    configuration.consumer_key = ENV.fetch("SNAPTRADE_CONSUMER_KEY")
    SnapTrade::Client.new(configuration)
  end

  # Registers a SnapTrade user and persists the returned user_id/user_secret
  # as a BrokerageConnection.
  #
  # Personal-tier SnapTrade keys auto-provision exactly one user (the account
  # owner) at signup and reject `registerUser`. When that's the case, reuse
  # the existing auto-provisioned user and obtain a fresh secret via
  # `resetUserSecret` instead. Business-tier keys (which support arbitrary
  # multi-user registration) fall through to normal registration.
  def self.register!(user_id:, broker_name: nil)
    existing_user_id = client.authentication.list_snap_trade_users.first

    result = if existing_user_id
      client.authentication.reset_snap_trade_user_secret(user_id: existing_user_id)
    else
      client.authentication.register_snap_trade_user(user_id: user_id)
    end

    BrokerageConnection.create!(
      snaptrade_user_id: result.user_id,
      snaptrade_auth_token: result.user_secret,
      broker_name: broker_name
    )
  rescue SnapTrade::ApiError => e
    raise Error, "SnapTrade registration failed: #{e.message}"
  end

  def initialize(connection)
    @connection = connection
    @client = self.class.client
  end

  # Returns the SnapTrade Connection Portal URL the user should be redirected
  # to in order to link a brokerage account. The URL expires in 5 minutes.
  def auth_url(custom_redirect:)
    response = @client.authentication.login_snap_trade_user(
      user_id: @connection.snaptrade_user_id,
      user_secret: @connection.snaptrade_auth_token,
      custom_redirect: custom_redirect
    )
    response.redirect_uri
  rescue SnapTrade::ApiError => e
    raise Error, "SnapTrade login failed: #{e.message}"
  end

  # Pulls all accounts and positions for this connection's user from SnapTrade
  # and upserts them into brokerage_accounts/brokerage_positions.
  def sync_accounts!
    accounts = @client.account_information.list_user_accounts(
      user_id: @connection.snaptrade_user_id,
      user_secret: @connection.snaptrade_auth_token
    )

    accounts.each { |account| sync_account(account) }
  rescue SnapTrade::ApiError => e
    raise Error, "SnapTrade sync failed: #{e.message}"
  end

  private

  def sync_account(account)
    local_account = @connection.brokerage_accounts.find_or_initialize_by(snaptrade_account_id: account.id)
    local_account.update!(
      account_name: account.name,
      account_number: account.number,
      account_type: account.raw_type,
      cash_balance: account.balance&.total&.amount,
      last_synced_at: Time.current
    )

    positions = @client.account_information.get_user_account_positions(
      user_id: @connection.snaptrade_user_id,
      user_secret: @connection.snaptrade_auth_token,
      account_id: account.id
    )

    positions.each { |position| sync_position(local_account, position) }
  end

  def sync_position(local_account, position)
    universal_symbol = position.symbol&.symbol
    ticker = universal_symbol&.symbol || universal_symbol&.raw_symbol
    return if ticker.blank?

    local_position = local_account.brokerage_positions.find_or_initialize_by(symbol: ticker)
    local_position.update!(
      description: universal_symbol&.description,
      quantity: position.units,
      average_purchase_price: position.average_purchase_price,
      current_price: position.price,
      current_value: position.units.to_f * position.price.to_f,
      last_synced_at: Time.current
    )
  end
end
