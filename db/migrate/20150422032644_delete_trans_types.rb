class DeleteTransTypes < ActiveRecord::Migration
  def up
    drop_table :transaction_types
  end

  def down
    create_table :transaction_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
