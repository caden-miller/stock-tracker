class AddTruthifiSupport < ActiveRecord::Migration[7.0]
  def change
    # Brokerage accounts: allow Truthifi-sourced records without SnapTrade
    change_column_null :brokerage_accounts, :brokerage_connection_id, true
    change_column_null :brokerage_accounts, :snaptrade_account_id, true
    add_column :brokerage_accounts, :institution_name, :string
    add_column :brokerage_accounts, :truthifi_account_id, :string
    add_index :brokerage_accounts, :truthifi_account_id, unique: true, where: "truthifi_account_id IS NOT NULL"

    # Bank accounts: allow Truthifi-sourced records without Plaid
    change_column_null :bank_accounts, :plaid_item_id, true
    change_column_null :bank_accounts, :plaid_account_id, true
    add_column :bank_accounts, :institution_name, :string
    add_column :bank_accounts, :truthifi_account_id, :string
    add_index :bank_accounts, :truthifi_account_id, unique: true, where: "truthifi_account_id IS NOT NULL"

    # Bank transactions: allow Truthifi-sourced records without Plaid
    change_column_null :bank_transactions, :plaid_transaction_id, true
    add_column :bank_transactions, :truthifi_transaction_id, :string
    add_index :bank_transactions, :truthifi_transaction_id, unique: true, where: "truthifi_transaction_id IS NOT NULL"
  end
end
