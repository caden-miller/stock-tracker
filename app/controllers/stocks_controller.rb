class StocksController < ApplicationController
  before_action :set_stock, only: [:edit, :update, :destroy]

  def index
    @stocks = Stock.order(:symbol)
  end

  def new
    @stock = Stock.new
  end

  def create
    @stock = Stock.new(stock_params)
    if @stock.save
      redirect_to stocks_path, notice: "Stock added."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @stock.update(stock_params)
      redirect_to stocks_path, notice: "Stock updated."
    else
      render :edit
    end
  end

  def destroy
    @stock.destroy
    redirect_to stocks_path, notice: "Stock removed."
  end

  private

  def set_stock
    @stock = Stock.find(params[:id])
  end

  def stock_params
    params.require(:stock).permit(:symbol, :name)
  end
end
