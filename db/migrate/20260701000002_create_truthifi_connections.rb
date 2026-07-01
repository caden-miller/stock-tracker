class CreateTruthifiConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :truthifi_connections do |t|
      t.string :client_id,        null: false
      t.string :access_token,     null: false
      t.string :refresh_token
      t.datetime :token_expires_at
      t.string :redirect_uri,     null: false
      t.timestamps
    end
  end
end
