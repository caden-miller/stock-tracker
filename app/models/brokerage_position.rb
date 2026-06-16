class BrokeragePosition < ApplicationRecord
  belongs_to :brokerage_account

  validates :symbol, presence: true
end
