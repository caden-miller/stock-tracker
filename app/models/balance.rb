class Balance < ApplicationRecord
  def gains
    # Calculate gains since this balance was added
    subsequent_balances = Balance.where('date > ?', date).order(date: :asc)
    end_date = subsequent_balances.first&.date || Time.current

    holdings = StockHolding.where(purchase_date: date..end_date)
    gains = holdings.sum do |holding|
      current_price = StockQuote::Stock.quote(holding.stock.symbol).latest_price
      (current_price - holding.purchase_price) * holding.quantity
    end
    gains
  end
end

