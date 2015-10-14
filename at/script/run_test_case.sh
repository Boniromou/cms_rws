#!/bin/sh
rspec -cfd spec/features/audit_logs_controller_spec.rb 
rspec -cfd spec/features/front_money_controller_spec.rb
rspec -cfd spec/features/fund_in_controller_spec.rb 
rspec -cfd spec/features/fund_out_controller_spec.rb
rspec -cfd spec/features/locations_controller_spec.rb
rspec -cfd spec/features/players_controller_spec.rb
rspec -cfd spec/features/player_transactions_controller_spec.rb
rspec -cfd spec/features/shifts_controller_spec.rb
rspec -cfd spec/features/stations_controller_spec.rb
rspec -cfd spec/features/user_session_spec.rb



rspec -cfd spec/controllers/tokens_controller_spec.rb

rspec -cfd spec/cronjob/clean_expired_token_spec.rb
