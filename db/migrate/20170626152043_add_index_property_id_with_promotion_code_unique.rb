class AddIndexPropertyIdWithPromotionCodeUnique < ActiveRecord::Migration
  def change
      add_index :player_transactions, [:player_id, :promotion_code], :name => 'index_player_id_promotion_code', :unique => true
  end
end

