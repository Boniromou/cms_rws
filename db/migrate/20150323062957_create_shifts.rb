class CreateShifts < ActiveRecord::Migration
  def up
    create_table :shifts do |t|
      t.integer :shift_type_id 
      t.integer :user_id
      t.datetime :accounting_date
      t.datetime :roll_shift_at
      t.string :station

      t.timestamps
    end
    
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_shift_type_id FOREIGN KEY (shift_type_id) REFERENCES shift_types(id);"
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id);"
  end

  def down
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_shift_type_id;"
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_user_id;"
    drop_table :shifts
  end
end
