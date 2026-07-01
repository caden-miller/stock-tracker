namespace :benchmarks do
  desc "Sync historical daily prices for benchmark tickers (SPY, QQQ, AGG, VTI)"
  task sync: :environment do
    BenchmarkPrice::BENCHMARKS.each_key do |symbol|
      begin
        BenchmarkPriceService.new(symbol).sync!
        puts "Synced #{symbol}"
      rescue BenchmarkPriceService::Error => e
        warn "Failed to sync #{symbol}: #{e.message}"
      end
    end
  end
end
