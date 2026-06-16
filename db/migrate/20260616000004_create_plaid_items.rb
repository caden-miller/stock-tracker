class CreatePlaidItems < ActiveRecord::Migration[7.0]
  def change
    create_table :plaid_items do |t|
      t.string :plaid_item_id,      null: false
      t.string :plaid_access_token, null: false  # encrypt at rest before going live
      t.string :institution_id
      t.string :institution_name
      t.string :webhook_url

      t.timestamps
    end

    add_index :plaid_items, :plaid_item_id, unique: true
  end
end
