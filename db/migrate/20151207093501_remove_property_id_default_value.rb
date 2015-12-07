class RemovePropertyIdDefaultValue < ActiveRecord::Migration
  def up
    change_column_default :players, :property_id, nil
    change_column_default :player_transactions, :property_id, nil
    change_column_default :users, :property_id, nil
    change_column_default :shifts, :property_id, nil
  end

  def down
    change_column_default :players, :property_id, 20000
    change_column_default :player_transactions, :property_id, 20000
    change_column_default :users, :property_id, 20000
    change_column_default :shifts, :property_id, 20000
  end
end
