class CreateBalances < ActiveRecord::Migration[7.0]
  def change
    create_table :balances do |t|
      t.decimal :amount
      t.datetime :date

      t.timestamps
    end
  end
end
