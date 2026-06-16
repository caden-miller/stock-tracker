class Stock < ApplicationRecord
  has_many :stock_holdings, dependent: :destroy

  validates :symbol, :name, presence: true
  validates :symbol, uniqueness: { case_sensitive: false }

  before_save { symbol.upcase! }
end

