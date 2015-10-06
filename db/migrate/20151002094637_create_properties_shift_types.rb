class CreatePropertiesShiftTypes < ActiveRecord::Migration
  def up
    create_table :properties_shift_types do |t|
      t.integer :property_id, :null => false
      t.integer :shift_type_id, :null => false
      t.integer :sequence, :null => false

      t.timestamps
    end
    execute "ALTER TABLE properties_shift_types ADD CONSTRAINT fk_properties_shift_types_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    execute "ALTER TABLE properties_shift_types ADD CONSTRAINT fk_properties_shift_types_shift_type_id FOREIGN KEY (shift_type_id) REFERENCES shift_types(id);"
  end

  def down
    drop_table :properties_shift_types
  end
end
