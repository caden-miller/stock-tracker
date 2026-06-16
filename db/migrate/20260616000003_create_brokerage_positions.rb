class CreateBrokeragePositions < ActiveRecord::Migration[7.0]
  def change
    create_table :brokerage_positions do |t|
      t.references :brokerage_account, null: false, foreign_key: true
      t.string  :symbol,               null: false
      t.string  :description
      t.decimal :quantity,             precision: 15, scale: 6
      t.decimal :average_purchase_price, precision: 15, scale: 4
      t.decimal :current_price,        precision: 15, scale: 4
      t.decimal :current_value,        precision: 15, scale: 2
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :brokerage_positions, [:brokerage_account_id, :symbol], unique: true
  end
end
