class CreateAccountingDates < ActiveRecord::Migration
  def change
    create_table :accounting_dates do |t|
      t.date :accounting_date

      t.timestamps
    end
  end
end
