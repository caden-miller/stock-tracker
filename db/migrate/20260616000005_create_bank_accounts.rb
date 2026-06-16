class CreateBankAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :bank_accounts do |t|
      t.references :plaid_item, null: false, foreign_key: true
      t.string  :plaid_account_id, null: false
      t.string  :name
      t.string  :official_name
      t.string  :account_type     # depository | credit | loan | investment
      t.string  :account_subtype  # checking | savings | credit card | etc.
      t.decimal :current_balance,   precision: 15, scale: 2
      t.decimal :available_balance, precision: 15, scale: 2
      t.string  :iso_currency_code, default: 'USD'

      t.timestamps
    end

    add_index :bank_accounts, :plaid_account_id, unique: true
  end
end
