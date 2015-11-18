class AddMachineTokenToShifts < ActiveRecord::Migration
  def up
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_station_id;"
    remove_column :shifts, :roll_shift_on_station_id
    add_column :shifts, :machine_token, :string
  end

  def down
    remove_column :shifts, :machine_token
    add_column :shifts, :roll_shift_on_station_id, :int
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_station_id FOREIGN KEY (roll_shift_on_station_id) REFERENCES stations(id);"
  end
end
