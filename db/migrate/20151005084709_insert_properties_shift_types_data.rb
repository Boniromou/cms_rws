class InsertPropertiesShiftTypesData < ActiveRecord::Migration
  def up
    execute "INSERT INTO shift_types(id,name, created_at, updated_at) values(4, 'day', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO properties_shift_types(id, property_id, shift_type_id, sequence, created_at, updated_at) values(1, 20000, 4, 1, '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM properties_shift_types WHERE id = 1"    
    execute "DELETE FROM shift_types WHERE id = 4"
  end
end
