class BankAccount < ApplicationRecord
  belongs_to :plaid_item, optional: true
  has_many :bank_transactions, dependent: :destroy

  validates :plaid_account_id, uniqueness: true, allow_nil: true
  validates :truthifi_account_id, uniqueness: true, allow_nil: true
  validate :has_account_identifier

  def display_institution
    institution_name.presence || plaid_item&.institution_name.presence || "Bank"
  end

  private

  def has_account_identifier
    if plaid_account_id.blank? && truthifi_account_id.blank?
      errors.add(:base, "must have plaid_account_id or truthifi_account_id")
    end
  end
end
