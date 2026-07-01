class CreateBenchmarkPrices < ActiveRecord::Migration[7.0]
  def change
    create_table :benchmark_prices do |t|
      t.string  :symbol,       null: false
      t.date    :date,         null: false
      t.decimal :close_price,  precision: 15, scale: 4, null: false

      t.timestamps
    end

    add_index :benchmark_prices, [:symbol, :date], unique: true
  end
end
