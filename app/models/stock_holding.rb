class StockHolding < ApplicationRecord
  belongs_to :stock
  attr_accessor :current_price, :current_value

  validates :quantity, :purchase_price, :purchase_date, presence: true
end
