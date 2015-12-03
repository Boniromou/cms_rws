class AddUniqueConstraintForAccountingDates < ActiveRecord::Migration
  def up
  	add_index :accounting_dates, [:accounting_date], unique: true
  end

  def down
  	remove_index :accounting_dates, [:accounting_date]
  end
end
