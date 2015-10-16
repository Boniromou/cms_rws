class CreateTransactionSlips < ActiveRecord::Migration
  def up
    create_table :transaction_slips do |t|
      t.integer :property_id, :null => false
      t.integer :slip_type_id, :null => false
      t.integer :next_number, :null => false

      t.timestamps
    end
    execute "ALTER TABLE transaction_slips ADD CONSTRAINT fk_transaction_slips_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    execute "ALTER TABLE transaction_slips ADD CONSTRAINT fk_transaction_slips_slip_type_id FOREIGN KEY (slip_type_id) REFERENCES slip_types(id);"
    add_index :transaction_slips, [:property_id, :slip_type_id], :unique => true
  end

  def down
    drop_table :transaction_slips
  end
end
