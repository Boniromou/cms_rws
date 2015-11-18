class CreateTransactionTypesSlipTypes < ActiveRecord::Migration
  def up
    create_table :transaction_types_slip_types do |t|
      t.integer :property_id, :null => false
      t.integer :transaction_type_id, :null => false
      t.integer :slip_type_id, :null => false
      t.datetime :purge_at

      t.timestamps
    end
    execute "ALTER TABLE transaction_types_slip_types ADD CONSTRAINT fk_transaction_types_slip_types_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    execute "ALTER TABLE transaction_types_slip_types ADD CONSTRAINT fk_transaction_types_slip_types_transaction_type_id FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(id);"
    execute "ALTER TABLE transaction_types_slip_types ADD CONSTRAINT fk_transaction_types_slip_types_slip_type_id FOREIGN KEY (slip_type_id) REFERENCES slip_types(id);"
    add_index :transaction_types_slip_types, [:property_id, :transaction_type_id], :unique => true, :name => 'index_trans_types_slip_types_on_property_id_and_trans_type_id'
  end

  def down
    drop_table :transaction_types_slip_types
  end
end
