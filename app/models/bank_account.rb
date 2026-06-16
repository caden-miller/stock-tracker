class BankAccount < ApplicationRecord
  belongs_to :plaid_item
  has_many :bank_transactions, dependent: :destroy

  validates :plaid_account_id, presence: true
  validates :plaid_account_id, uniqueness: true
end
