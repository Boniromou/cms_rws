class CreateTokens < ActiveRecord::Migration
  def up
  	create_table :tokens do |t|
      t.string :session_token
      t.integer :player_id
      t.datetime :expired_at
      t.timestamps
    end
    execute "ALTER TABLE tokens ADD CONSTRAINT fk_tokens_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
  end

  def down
    execute "ALTER TABLE tokens DROP FOREIGN KEY fk_tokens_player_id;"
  	drop_table :tokens
  end
end
