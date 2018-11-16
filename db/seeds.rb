# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Currency.where(:id => 2, :name => 'HKD').first_or_create

LockType.where(:id => 1, :name => 'cage_lock').first_or_create
LockType.where(:id => 2, :name => 'blacklist').first_or_create
LockType.where(:id => 3, :name => 'pending').first_or_create
LockType.where(:id => 4, :name => 'manual_lock').first_or_create
LockType.where(:id => 5, :name => 'deactivated').first_or_create

ShiftType.where(:id =>1, :name => 'morning').first_or_create
ShiftType.where(:id =>2, :name => 'swing').first_or_create
ShiftType.where(:id =>3, :name => 'night').first_or_create
ShiftType.where(:id =>4, :name => 'day').first_or_create

SlipType.where(:id => 1, :name => 'deposit').first_or_create
SlipType.where(:id => 2, :name => 'withdraw').first_or_create

TransactionType.where(:id => 1, :name => 'deposit').first_or_create
TransactionType.where(:id => 2, :name => 'withdraw').first_or_create
TransactionType.where(:id => 3, :name => 'void_deposit').first_or_create
TransactionType.where(:id => 4, :name => 'void_withdraw').first_or_create
TransactionType.where(:id => 5, :name => 'credit_deposit').first_or_create
TransactionType.where(:id => 6, :name => 'credit_expire').first_or_create
