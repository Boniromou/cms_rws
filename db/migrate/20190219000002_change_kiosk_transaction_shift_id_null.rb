class ChangeKioskTransactionShiftIdNull < ActiveRecord::Migration
  def up
    change_column_null :kiosk_transactions, :shift_id, true
  end

  def down
    change_column :kiosk_transactions, :shift_id, :integer, :null => false
  end
end
