class PlaidItem < ApplicationRecord
  has_many :bank_accounts, dependent: :destroy

  encrypts :plaid_access_token

  validates :plaid_item_id, :plaid_access_token, presence: true
end
