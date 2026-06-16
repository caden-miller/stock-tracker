class CreateBrokerageConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :brokerage_connections do |t|
      t.string  :snaptrade_user_id, null: false
      t.string  :snaptrade_auth_token, null: false
      t.string  :broker_name

      t.timestamps
    end
  end
end
