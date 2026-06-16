class CreateBankTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :bank_transactions do |t|
      t.references :bank_account, null: false, foreign_key: true
      t.string  :plaid_transaction_id, null: false
      t.date    :date,                 null: false
      t.string  :name
      t.string  :merchant_name
      t.decimal :amount,   precision: 15, scale: 2  # positive = debit, negative = credit
      t.string  :category
      t.string  :subcategory
      t.boolean :pending, default: false
      t.string  :iso_currency_code, default: 'USD'

      t.timestamps
    end

    add_index :bank_transactions, :plaid_transaction_id, unique: true
    add_index :bank_transactions, [:bank_account_id, :date]
  end
end
