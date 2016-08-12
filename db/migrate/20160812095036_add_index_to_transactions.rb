class AddIndexToTransactions < ActiveRecord::Migration
  def change
    add_index :player_transactions, :slip_number
    add_index :kiosk_transactions, :ref_trans_id
  end
end
