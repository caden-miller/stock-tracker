require "net/http"
require "json"

# Fetches historical daily closing prices for benchmark tickers (SPY, QQQ, AGG, VTI)
# from Yahoo Finance's unofficial chart endpoint and stores them in benchmark_prices.
#
# This is a different endpoint than the `basic_yahoo_finance` gem (which only returns
# a live quote) — it serves historical OHLC series and has been more reliable in
# practice, but it's still an unofficial API and can fail; callers should handle Error.
class BenchmarkPriceService
  class Error < StandardError; end

  CHART_URL = "https://query1.finance.yahoo.com/v8/finance/chart/%s"
  USER_AGENT = "Mozilla/5.0 (compatible; stock-tracker/1.0)"

  # Syncs all configured benchmarks. For each symbol, fetches from the day after
  # the most recent stored price (or 5 years back if none stored) through today.
  def self.sync_all!
    BenchmarkPrice::BENCHMARKS.keys.each do |symbol|
      new(symbol).sync!
    end
  end

  def initialize(symbol)
    raise Error, "Unknown benchmark symbol: #{symbol}" unless BenchmarkPrice::BENCHMARKS.key?(symbol)

    @symbol = symbol
  end

  def sync!
    last_date = BenchmarkPrice.where(symbol: @symbol).maximum(:date)
    period1 = last_date ? (last_date + 1.day).to_time.to_i : 5.years.ago.to_i
    period2 = Time.current.to_i
    return if last_date && period1 >= period2

    fetch_and_store(period1, period2)
  end

  private

  def fetch_and_store(period1, period2)
    uri = URI(format(CHART_URL, @symbol))
    uri.query = URI.encode_www_form(period1: period1, period2: period2, interval: "1d")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      http.request(request)
    end

    raise Error, "Yahoo chart request failed for #{@symbol}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    store_quotes(JSON.parse(response.body))
  rescue StandardError => e
    raise Error, "Failed to fetch/store benchmark prices for #{@symbol}: #{e.message}"
  end

  def store_quotes(payload)
    result = payload.dig("chart", "result", 0)
    return if result.nil?

    timestamps = result["timestamp"] || []
    closes = result.dig("indicators", "adjclose", 0, "adjclose") ||
             result.dig("indicators", "quote", 0, "close") || []

    timestamps.each_with_index do |ts, i|
      close = closes[i]
      next if close.nil?

      BenchmarkPrice.find_or_initialize_by(symbol: @symbol, date: Time.at(ts).utc.to_date)
                    .update!(close_price: close)
    end
  end
end
