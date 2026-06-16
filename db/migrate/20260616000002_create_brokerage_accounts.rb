class CreateBrokerageAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :brokerage_accounts do |t|
      t.references :brokerage_connection, null: false, foreign_key: true
      t.string  :snaptrade_account_id, null: false
      t.string  :account_name
      t.string  :account_number
      t.string  :account_type
      t.decimal :cash_balance, precision: 15, scale: 2
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
