class BalancesController < ApplicationController
  before_action :set_balance, only: [:edit, :update, :destroy]

  def index
    @balances = Balance.order(date: :asc)
    @portfolio = PortfolioService.new
    @performance_series = build_performance_series
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
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@balance) }
      format.html { redirect_to balances_path, notice: "Balance removed." }
    end
  end

  private

  def set_balance
    @balance = Balance.find(params[:id])
  end

  def balance_params
    params.require(:balance).permit(:amount, :date)
  end

  # Builds an array of { name:, data: { date => pct_change_since_first_balance } }
  # series so the portfolio and each benchmark can be plotted on the same % return
  # scale, all rebased to 0% on the date of the earliest balance snapshot.
  #
  # chartkick.js v5 only recognizes multi-series data as an array of {name:, data:}
  # hashes — a plain { "Series" => {...} } Hash gets misread as a single series.
  def build_performance_series
    return [] if @balances.empty?

    baseline_date = @balances.first.date.to_date
    series = [{ name: "My Portfolio", data: indexed(@balances.map { |b| [b.date.to_date, b.amount] }) }]

    BenchmarkPrice::BENCHMARKS.each do |symbol, label|
      # Anchor on the most recent benchmark price on/before the balance baseline date
      # (markets may be closed, or price data may lag a day or two behind "today").
      anchor_date = BenchmarkPrice.where(symbol: symbol).where("date <= ?", baseline_date).maximum(:date)
      anchor_date ||= BenchmarkPrice.where(symbol: symbol).minimum(:date)
      next if anchor_date.nil?

      prices = BenchmarkPrice.where(symbol: symbol).where("date >= ?", anchor_date).order(:date)
      series << { name: label, data: indexed(prices.map { |p| [p.date, p.close_price] }) }
    end

    series
  end

  def indexed(date_value_pairs)
    baseline = date_value_pairs.first.last.to_f
    return {} if baseline.zero?

    date_value_pairs.each_with_object({}) do |(date, value), hash|
      hash[date] = ((value.to_f / baseline) - 1) * 100
    end
  end
end
