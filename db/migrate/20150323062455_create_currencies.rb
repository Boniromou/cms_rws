class CreateCurrencies < ActiveRecord::Migration
  def change
    create_table :currencies do |t|
      t.string :name

      t.timestamps
    end
    execute "INSERT INTO currencies(id, name,created_at,updated_at) values(2, 'HKD','2015-03-24 00:00:00','2015-03-24 00:00:00');"
  end
end
