namespace :portfolio do
  desc "Record today's total net worth (brokerage + bank balances) as a Balance snapshot"
  task snapshot: :environment do
    balance = Balance.where(date: Date.current.all_day).first_or_initialize
    balance.date = Time.current
    balance.amount = PortfolioService.net_worth
    balance.save!
    puts "Recorded balance snapshot for #{Date.current}: #{balance.amount}"
  end
end
