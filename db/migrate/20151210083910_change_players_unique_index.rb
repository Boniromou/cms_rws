class ChangePlayersUniqueIndex < ActiveRecord::Migration
  def up
    remove_index :players, :card_id
    remove_index :players, :name => 'by_member_id'
    add_index :players, [:member_id, :property_id], :unique => true
    add_index :players, [:card_id, :property_id], :unique => true
  end

  def down
    remove_index :players, [:card_id, :property_id]
    remove_index :players, [:member_id, :property_id]
    add_index :players, :member_id, unique:true, :name => 'by_member_id'
    add_index :players, :card_id
  end
end
