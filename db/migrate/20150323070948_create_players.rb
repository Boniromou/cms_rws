class CreatePlayers < ActiveRecord::Migration
  def up
    create_table :players do |t|
      t.string :player_name
      t.string :member_id
      t.string :card_id
      t.integer :currency_id
      t.integer :balance
      t.string :status

      t.timestamps
    end

    execute "ALTER TABLE players ADD CONSTRAINT fk_currency_id FOREIGN KEY (currency_id) REFERENCES currencies(id);"
  end

  def down
    execute "ALTER TABLE players DROP FOREIGN KEY fk_currency_id;"
    drop_table :players
  end
end
