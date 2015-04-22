class ChangeShiftsColumn < ActiveRecord::Migration
  def up
    Shift.delete_all
    remove_column :shifts, :accounting_date
    add_column :shifts, :accounting_date_id, :int
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_accounting_date_id FOREIGN KEY (accounting_date_id) REFERENCES accounting_dates(id);"
  end

  def down
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_accounting_date_id;"
    remove_column :shifts, :accounting_date_id
    add_column :shifts, :accounting_date, :datetime
  end
end
