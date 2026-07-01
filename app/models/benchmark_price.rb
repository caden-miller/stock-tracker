class BenchmarkPrice < ApplicationRecord
  # symbol => display label, shown on the performance chart legend
  BENCHMARKS = {
    "SPY" => "S&P 500",
    "QQQ" => "Nasdaq 100",
    "AGG" => "US Bonds",
    "VTI" => "Total US Stock Market"
  }.freeze

  validates :symbol, :date, :close_price, presence: true
  validates :symbol, inclusion: { in: BENCHMARKS.keys }
  validates :date, uniqueness: { scope: :symbol }
end
