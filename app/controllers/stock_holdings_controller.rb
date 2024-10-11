class StockHoldingsController < ApplicationController
  def index
    @stock_holdings = StockHolding.includes(:stock).order(purchase_date: :asc)
    puts "Stock holdings count: #{@stock_holdings.size}"
    @total_current_value = 0
    @stock_holdings.each do |holding|
      query = BasicYahooFinance::Query.new
      data = query.quotes(holding.stock.symbol)
      puts "putting data"
      puts data
      puts "done putting data"
      latest_price = data[holding.stock.symbol]["regularMarketPrice"]["raw"]
      holding.current_price = latest_price
      holding.current_value = holding.quantity * holding.current_price
      @total_current_value += holding.current_value
    end
  end

  def new
    @stock_holding = StockHolding.new
    @stocks = Stock.all
  end

  def create
    @stock_holding = StockHolding.new(stock_holding_params)
    if @stock_holding.save
      redirect_to stock_holdings_path, notice: 'Stock purchase recorded.'
    else
      render :new
    end
  end

  private

  def stock_holding_params
    params.require(:stock_holding).permit(:stock_id, :quantity, :purchase_price, :purchase_date)
  end
end

