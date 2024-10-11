class CreateStockHoldings < ActiveRecord::Migration[7.0]
  def change
    create_table :stock_holdings do |t|
      t.references :stock, null: false, foreign_key: true
      t.decimal :quantity
      t.decimal :purchase_price
      t.datetime :purchase_date

      t.timestamps
    end
  end
end
