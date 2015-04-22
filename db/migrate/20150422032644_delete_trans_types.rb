class DeleteTransTypes < ActiveRecord::Migration
  def up
    drop_table :transaction_types
  end

  def down
  end
end
