class BankTransaction < ApplicationRecord
  belongs_to :bank_account

  validates :plaid_transaction_id, :date, presence: true
  validates :plaid_transaction_id, uniqueness: true
end
