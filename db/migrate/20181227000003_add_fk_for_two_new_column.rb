class AddFkForTwoNewColumn < ActiveRecord::Migration
  def up
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_payment_method_id FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id);"
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_source_of_fund_id FOREIGN KEY (source_of_fund_id) REFERENCES source_of_funds(id);"  
  end

  def down
    execute "ALTER TABLE player_transactions FROP FOREIGN KEY fk_payment_method_id"
    execute "ALTER TABLE player_transactions FROP FOREIGN KEY fk_source_of_fund_id"
  end
end

