class ChangePropertyIdToCasinoId < ActiveRecord::Migration
  def up
    rename_property_id_to_casino_id(:player_transactions)
    rename_property_id_to_casino_id(:users)
    rename_property_id_to_casino_id(:configurations)
    rename_property_id_to_casino_id(:shifts)
    rename_property_id_to_casino_id(:properties_shift_types)
    rename_property_id_to_casino_id(:transaction_slips)
    rename_property_id_to_casino_id(:transaction_types_slip_types)
  end

  def down
    rename_casino_id_to_property_id(:player_transactions)
    rename_casino_id_to_property_id(:users)
    rename_casino_id_to_property_id(:configurations)
    rename_casino_id_to_property_id(:shifts)
    rename_casino_id_to_property_id(:properties_shift_types)
    rename_casino_id_to_property_id(:transaction_slips)
    rename_casino_id_to_property_id(:transaction_types_slip_types)
  end

  def rename_property_id_to_casino_id(table)
    execute "ALTER TABLE #{table.to_s} DROP FOREIGN KEY fk_#{table.to_s}_property_id;"
    rename_column table, :property_id, :casino_id
    execute "ALTER TABLE #{table.to_s} ADD CONSTRAINT fk_#{table.to_s}_casino_id FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end

  def rename_casino_id_to_property_id(table)
    execute "ALTER TABLE #{table.to_s} DROP FOREIGN KEY fk_#{table.to_s}_casino_id;"
    rename_column table, :casino_id, :property_id
    execute "ALTER TABLE #{table.to_s} ADD CONSTRAINT fk_#{table.to_s}_property_id FOREIGN KEY (property_id) REFERENCES casinos(id);"
  end
end
