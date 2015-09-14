class CreateTokens < ActiveRecord::Migration
  def up
  	create_table :tokens do |t|
      t.string :session_token
      t.string :terminal_id
      t.integer :player_id
      t.datetime :expired_at
      t.timestamps
    end
  end

  def down
  	drop_table :tokens
  end
end
