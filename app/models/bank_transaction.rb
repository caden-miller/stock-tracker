class BankTransaction < ApplicationRecord
  belongs_to :bank_account

  validates :date, presence: true
  validates :plaid_transaction_id, uniqueness: true, allow_nil: true
  validates :truthifi_transaction_id, uniqueness: true, allow_nil: true
  validates :truthifi_transaction_id, presence: true
end
