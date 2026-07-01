class BrokerageAccount < ApplicationRecord
  belongs_to :brokerage_connection, optional: true
  has_many :brokerage_positions, dependent: :destroy

  validates :snaptrade_account_id, uniqueness: true, allow_nil: true
  validates :truthifi_account_id, uniqueness: true, allow_nil: true
  validate :has_account_identifier

  def display_institution
    institution_name.presence ||
      brokerage_connection&.broker_name.presence ||
      account_type.presence ||
      "Brokerage"
  end

  private

  def has_account_identifier
    if snaptrade_account_id.blank? && truthifi_account_id.blank?
      errors.add(:base, "must have snaptrade_account_id or truthifi_account_id")
    end
  end
end
