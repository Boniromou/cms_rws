class AddNameNotNullInSourceOfFundsTable < ActiveRecord::Migration
   def up 
    change_column_null :source_of_funds, :name, false
   end

   def down
    change_column :source_of_funds, :name, true
   end
end

