#!/bin/sh
rspec -fh spec/features/audit_logs_controller_spec.rb -o at/report/audit_logs_controller_spec.html
rspec -fh spec/features/front_money_controller_spec.rb -o at/report/front_money_controller_spec.html
rspec -fh spec/features/fund_in_controller_spec.rb -o at/report/fund_in_controller_spec.html
rspec -fh spec/features/fund_out_controller_spec.rb -o at/report/fund_out_controller_spec.html
rspec -fh spec/features/locations_controller_spec.rb -o at/report/locations_controller_spec.html
rspec -fh spec/features/players_controller_spec.rb -o at/report/players_controller_spec.html
rspec -fh spec/features/player_transactions_controller_spec.rb -o at/report/player_transactions_controller_spec.html
rspec -fh spec/features/shifts_controller_spec.rb -o at/report/shifts_controller_spec.html
rspec -fh spec/features/stations_controller_spec.rb -o at/report/stations_controller_spec.html
rspec -fh spec/features/user_session_spec.rb -o at/report/user_session_spec.html



rspec -fh spec/controllers/tokens_controller_spec.rb -o at/report/tokens_controller_spec.html

rspec -fh spec/cronjob/clean_expired_token_spec.rb -o at/report/clean_expired_token_spec.html
