class StockHoldingsController < ApplicationController
  before_action :set_holding, only: [:edit, :update, :destroy]

  def index
    @stock_holdings = StockHolding.includes(:stock).order(purchase_date: :asc)
    @total_current_value = 0
    @stock_holdings.each do |holding|
      query = BasicYahooFinance::Query.new
      data = query.quotes(holding.stock.symbol)
      holding.current_price = data[holding.stock.symbol]["regularMarketPrice"]["raw"]
      holding.current_value = holding.quantity * holding.current_price
      @total_current_value += holding.current_value
    rescue StandardError => e
      Rails.logger.error "Price fetch failed for #{holding.stock.symbol}: #{e.message}"
      holding.current_price = nil
      holding.current_value = nil
    end
  end

  def new
    @stock_holding = StockHolding.new
    @stocks = Stock.order(:symbol)
  end

  def create
    @stock_holding = StockHolding.new(stock_holding_params)
    if @stock_holding.save
      redirect_to stock_holdings_path, notice: "Stock purchase recorded."
    else
      @stocks = Stock.order(:symbol)
      render :new
    end
  end

  def edit
    @stocks = Stock.order(:symbol)
  end

  def update
    if @holding.update(stock_holding_params)
      redirect_to stock_holdings_path, notice: "Stock holding updated."
    else
      @stocks = Stock.order(:symbol)
      render :edit
    end
  end

  def destroy
    @holding.destroy
    redirect_to stock_holdings_path, notice: "Stock holding removed."
  end

  private

  def set_holding
    @holding = StockHolding.find(params[:id])
  end

  def stock_holding_params
    params.require(:stock_holding).permit(:stock_id, :quantity, :purchase_price, :purchase_date)
  end
end
