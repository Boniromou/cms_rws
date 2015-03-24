class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :employee_id

      t.timestamps
    end
    execute "INSERT INTO users(employee_id,created_at,updated_at) values('10172','2015-03-24 00:00:00','2015-03-24 00:00:00');"
  end
end
