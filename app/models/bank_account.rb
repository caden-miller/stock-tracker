class BankAccount < ApplicationRecord
  belongs_to :plaid_item, optional: true
  has_many :bank_transactions, dependent: :destroy

  validates :plaid_account_id, uniqueness: true, allow_nil: true
  validates :truthifi_account_id, uniqueness: true, allow_nil: true
  validates :truthifi_account_id, presence: true

  def display_institution
    institution_name.presence || "Bank"
  end
end
