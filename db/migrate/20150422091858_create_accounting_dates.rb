class CreateAccountingDates < ActiveRecord::Migration
  def change
    create_table :accounting_dates do |t|
      t.string :accounting_date

      t.timestamps
    end
  end
end
