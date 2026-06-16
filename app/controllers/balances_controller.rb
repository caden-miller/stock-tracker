class BalancesController < ApplicationController
  before_action :set_balance, only: [:edit, :update, :destroy]

  def index
    @balances = Balance.order(date: :asc)
  end

  def new
    @balance = Balance.new
  end

  def create
    @balance = Balance.new(balance_params)
    if @balance.save
      redirect_to balances_path, notice: "Balance added successfully."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @balance.update(balance_params)
      redirect_to balances_path, notice: "Balance updated."
    else
      render :edit
    end
  end

  def destroy
    @balance.destroy
    redirect_to balances_path, notice: "Balance removed."
  end

  private

  def set_balance
    @balance = Balance.find(params[:id])
  end

  def balance_params
    params.require(:balance).permit(:amount, :date)
  end
end
