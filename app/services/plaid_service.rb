# Plaid integration service — Phase 3
#
# Setup:
#   1. Sign up at https://dashboard.plaid.com/signup
#   2. Set PLAID_CLIENT_ID, PLAID_SECRET, and PLAID_ENV in credentials or .env
#      PLAID_ENV should be 'sandbox' for testing, 'development' or 'production' for live
#   3. Uncomment `gem 'plaid', '~> 19.0'` in Gemfile and run `bundle install`
#   4. Replace stubs below with real Plaid SDK calls
#
# Plaid supports Capital One, Bank of America, Wells Fargo, Chase, Citi, and thousands
# more. Users connect via the Plaid Link JS widget — we never handle bank credentials.
# Access tokens must be encrypted at rest (use Rails 7.1+ `encrypts` on PlaidItem).
class PlaidService
  # def initialize(access_token)
  #   configuration = Plaid::Configuration.new
  #   configuration.server_index = Plaid::Configuration::Environment[ENV['PLAID_ENV']]
  #   configuration.api_key['PLAID-CLIENT-ID'] = ENV['PLAID_CLIENT_ID']
  #   configuration.api_key['PLAID-SECRET'] = ENV['PLAID_SECRET']
  #   api_client = Plaid::ApiClient.new(configuration)
  #   @client = Plaid::PlaidApi.new(api_client)
  #   @access_token = access_token
  # end

  # Creates a Link token to initialize the Plaid Link widget on the frontend.
  # def self.create_link_token(user_id)
  #   request = Plaid::LinkTokenCreateRequest.new(
  #     user: { client_user_id: user_id.to_s },
  #     client_name: 'Stock Tracker',
  #     products: ['transactions'],
  #     country_codes: ['US'],
  #     language: 'en'
  #   )
  #   @client.link_token_create(request).link_token
  # end

  # Exchanges a public token (from Plaid Link callback) for a permanent access token.
  # def self.exchange_public_token(public_token)
  #   request = Plaid::ItemPublicTokenExchangeRequest.new(public_token: public_token)
  #   @client.item_public_token_exchange(request).access_token
  # end

  # Fetches recent transactions for the linked item.
  # def transactions(start_date:, end_date:)
  #   request = Plaid::TransactionsGetRequest.new(
  #     access_token: @access_token,
  #     start_date: start_date,
  #     end_date: end_date
  #   )
  #   @client.transactions_get(request).transactions
  # end

  # Fetches current balances for all accounts under this item.
  # def balances
  #   request = Plaid::AccountsBalanceGetRequest.new(access_token: @access_token)
  #   @client.accounts_balance_get(request).accounts
  # end
end
