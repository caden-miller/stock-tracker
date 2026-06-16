class Balance < ApplicationRecord
  validates :amount, :date, presence: true

  def gains
    subsequent_balances = Balance.where('date > ?', date).order(date: :asc)
    end_date = subsequent_balances.first&.date || Time.current

    StockHolding.where(purchase_date: date..end_date).sum do |holding|
      query = BasicYahooFinance::Query.new
      data = query.quotes(holding.stock.symbol)
      current_price = data[holding.stock.symbol]["regularMarketPrice"]["raw"]
      (current_price - holding.purchase_price) * holding.quantity
    rescue StandardError => e
      Rails.logger.error "Price fetch failed for #{holding.stock.symbol}: #{e.message}"
      0
    end
  end
end

