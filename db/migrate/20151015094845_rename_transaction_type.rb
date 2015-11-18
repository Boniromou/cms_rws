class RenameTransactionType < ActiveRecord::Migration
  def up
    execute "UPDATE transaction_types SET name = 'deposit' WHERE name ='Deposit';"
    execute "UPDATE transaction_types SET name = 'withdraw' WHERE name ='Withdrawal';"
  end

  def down
    execute "UPDATE transaction_types SET name = 'Deposit' WHERE name ='deposit';"
    execute "UPDATE transaction_types SET name = 'Withdrawal' WHERE name ='withdraw';"
  end
end
