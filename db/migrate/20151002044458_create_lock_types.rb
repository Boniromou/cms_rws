class CreateLockTypes < ActiveRecord::Migration
  def change
    create_table :lock_types do |t|
      t.string :name, :null => false, :limit => 45
      
      t.timestamps
    end
  end
end
