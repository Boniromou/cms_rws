class ChangePropertyIdToLicenseeId < ActiveRecord::Migration
  def up
    rename_property_id_to_licensee_id(:players)
    rename_property_id_to_licensee_id(:change_histories)
  end

  def down
    rename_licensee_id_to_property_id(:players)
    rename_licensee_id_to_property_id(:change_histories)
  end

  def rename_property_id_to_licensee_id(table)
    execute "ALTER TABLE #{table.to_s} DROP FOREIGN KEY fk_#{table.to_s}_property_id;"
    rename_column table, :property_id, :licensee_id
    execute "ALTER TABLE #{table.to_s} ADD CONSTRAINT fk_#{table.to_s}_licensee_id FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
  end

  def rename_licensee_id_to_property_id(table)
    execute "ALTER TABLE #{table.to_s} DROP FOREIGN KEY fk_#{table.to_s}_licensee_id;"
    rename_column table, :licensee_id, :property_id
    execute "ALTER TABLE #{table.to_s} ADD CONSTRAINT fk_#{table.to_s}_property_id FOREIGN KEY (property_id) REFERENCES casinos(id);"
  end
end
