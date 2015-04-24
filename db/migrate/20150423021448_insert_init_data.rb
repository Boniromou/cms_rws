class InsertInitData < ActiveRecord::Migration
  def up
    AccountingDate.delete_all
    t = Time.now - 60*60*24
    execute "INSERT INTO accounting_dates(id,accounting_date, created_at, updated_at) values(1,'#{t.utc}', '#{Time.now.utc}', '#{Time.now.utc}');"
    ShiftType.delete_all
    execute "INSERT INTO shift_types(id, name, created_at, updated_at) values(1,'morning', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO shift_types(id, name, created_at, updated_at) values(2,'swing', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO shift_types(id, name, created_at, updated_at) values(3,'night', '#{Time.now.utc}', '#{Time.now.utc}');"
    Shift.delete_all
    execute "INSERT INTO shifts(id,shift_type_id,accounting_date_id, lock_version, created_at, updated_at) values(1, 1, 1, 0, '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    Shift.delete_all
    ShiftType.delete_all
    AccountingDate.delete_all
  end
end
