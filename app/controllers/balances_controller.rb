class BalancesController < ApplicationController
  def index
    @balances = Balance.order(date: :asc)
  end

  def new
    @balance = Balance.new
  end

  def create
    @balance = Balance.new(balance_params)
    if @balance.save
      redirect_to balances_path, notice: 'Balance added successfully.'
    else
      render :new
    end
  end

  private

  def balance_params
    params.require(:balance).permit(:amount, :date)
  end
end

