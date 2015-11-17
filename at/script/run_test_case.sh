#!/bin/sh
rspec -cfd spec/features/audit_logs_controller_spec.rb 
rspec -cfd spec/features/front_money_controller_spec.rb
rspec -cfd spec/features/fund_controller_spec.rb
rspec -cfd spec/features/fund_in_controller_spec.rb 
rspec -cfd spec/features/fund_out_controller_spec.rb
rspec -cfd spec/features/void_controller_spec.rb
rspec -cfd spec/features/players_controller_spec.rb
rspec -cfd spec/features/player_transactions_controller_spec.rb
rspec -cfd spec/features/shifts_controller_spec.rb
rspec -cfd spec/features/user_session_spec.rb
rspec -cfd spec/features/machines_controller_spec.rb
rspec -cfd spec/features/pin_histories_controller_spec.rb
rspec -cfd spec/features/lock_histories_controller_spec.rb

rspec -cfd spec/controllers/tokens_controller_spec.rb
rspec -cfd spec/controllers/machines_controller_spec.rb

rspec -cfd spec/cronjob/clean_expired_token_spec.rb
rspec -cfd spec/cronjob/update_player_spec.rb
rspec -cfd spec/cronjob/roll_shift_spec.rb
