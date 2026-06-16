# SnapTrade integration service — Phase 2
#
# Setup:
#   1. Sign up at https://snaptrade.com/developers
#   2. Set SNAPTRADE_CLIENT_ID and SNAPTRADE_CONSUMER_KEY in credentials or .env
#   3. Uncomment `gem 'snaptrade-ruby'` in Gemfile and run `bundle install`
#   4. Replace stubs below with real SnapTrade SDK calls
#
# SnapTrade supports 50+ brokerages including Fidelity, Schwab, TD Ameritrade,
# Robinhood, Webull, IBKR, and more. Authentication is OAuth-based — users
# connect through SnapTrade's hosted UI, so we never handle brokerage credentials.
class SnaptradeService
  # def initialize(user)
  #   @client = SnapTrade::Client.new(
  #     client_id: ENV['SNAPTRADE_CLIENT_ID'],
  #     consumer_key: ENV['SNAPTRADE_CONSUMER_KEY']
  #   )
  #   @snaptrade_user_id = user.snaptrade_user_id
  # end

  # Returns the URL to redirect the user to for brokerage OAuth.
  # def auth_url(broker_slug:, redirect_uri:)
  #   @client.authentication.login_snap_trade_user(
  #     user_id: @snaptrade_user_id,
  #     broker: broker_slug,
  #     redirect_uri: redirect_uri
  #   ).redirect_uri
  # end

  # Fetches all accounts for the linked brokerage user and returns balances/positions.
  # def sync_accounts
  #   accounts = @client.accounts.list_user_accounts(user_id: @snaptrade_user_id)
  #   accounts.map do |account|
  #     positions = @client.account_information.get_user_holdings(
  #       user_id: @snaptrade_user_id,
  #       account_id: account.id
  #     )
  #     { account: account, positions: positions }
  #   end
  # end
end
