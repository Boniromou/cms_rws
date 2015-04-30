class AddUniqueIndexToPlayersCardId < ActiveRecord::Migration
  def change
    add_index :players, :card_id, :unique => true
  end
end
