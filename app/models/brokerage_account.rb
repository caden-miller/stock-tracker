class BrokerageAccount < ApplicationRecord
  belongs_to :brokerage_connection
  has_many :brokerage_positions, dependent: :destroy

  validates :snaptrade_account_id, presence: true
  validates :snaptrade_account_id, uniqueness: true
end
