class AddTablePaymentMethodTypeAndSourceOfFunds < ActiveRecord::Migration
  def up
    create_table :payment_method_type do |t|
      t.string :name

      t.timestamps
    end
    
    create_table :source_of_funds do |t|
      t.string :name

      t.timestamps
    end
  end
  def down
    drop_table :payment_method_type
    drop_table :source_of_funds
  end
end
