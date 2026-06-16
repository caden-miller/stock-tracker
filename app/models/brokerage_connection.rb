class BrokerageConnection < ApplicationRecord
  has_many :brokerage_accounts, dependent: :destroy

  validates :snaptrade_user_id, :snaptrade_auth_token, presence: true
end
