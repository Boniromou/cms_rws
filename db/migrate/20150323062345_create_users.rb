class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :employee_id
      t.string :uid

      t.timestamps
    end
  end
end
