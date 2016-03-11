class RenamePropertiesShiftTypesToCasinosShiftTypes < ActiveRecord::Migration
  def up
    rename_table :properties_shift_types, :casinos_shift_types
  end

  def down
    rename_table :casinos_shift_types, :properties_shift_types
  end
end
