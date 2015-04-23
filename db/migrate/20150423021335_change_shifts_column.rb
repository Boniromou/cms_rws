class ChangeShiftsColumn < ActiveRecord::Migration
  def up
    Shift.delete_all
    remove_column :shifts, :accounting_date
    add_column :shifts, :accounting_date_id, :int
    rename_column :shifts, :station, :roll_shift_on_station_id
    change_column :shifts, :roll_shift_on_station_id, :int
    add_column :shifts, :lock_version, :int
    
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_accounting_date_id FOREIGN KEY (accounting_date_id) REFERENCES accounting_dates(id);"
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_station_id FOREIGN KEY (roll_shift_on_station_id) REFERENCES stations(id);"
    
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_user_id;"
    rename_column :shifts, :user_id, :roll_shift_by_user_id
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_user_id FOREIGN KEY (roll_shift_by_user_id) REFERENCES users(id);"
  end

  def down
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_user_id;"
    rename_column :shifts, :roll_shift_by_user_id, :user_id
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id);"
    
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_accounting_date_id;"
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_station_id;"
    remove_column :shifts, :lock_version
    change_column :shifts, :roll_shift_on_station_id, :string
    rename_column :shifts, :roll_shift_on_station_id, :station
    remove_column :shifts, :accounting_date_id
    add_column :shifts, :accounting_date, :datetime
  end
end
