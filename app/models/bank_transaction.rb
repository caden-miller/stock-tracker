class BankTransaction < ApplicationRecord
  belongs_to :bank_account

  validates :date, presence: true
  validates :plaid_transaction_id, uniqueness: true, allow_nil: true
  validates :truthifi_transaction_id, uniqueness: true, allow_nil: true
  validate :has_transaction_identifier

  private

  def has_transaction_identifier
    if plaid_transaction_id.blank? && truthifi_transaction_id.blank?
      errors.add(:base, "must have plaid_transaction_id or truthifi_transaction_id")
    end
  end
end
