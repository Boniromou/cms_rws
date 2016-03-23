require File.expand_path("../../../config/environment", __FILE__)
namespace :property do
  task :create do
    property_id = ENV['property_id']
    init_20000_data
  end

  def init_20000_data
    licensee = Licensee.where(:id => 20000, :name => 'MockUp').first_or_create
    casino = Casino.where(:id => 20000, :name => 'MockUp', :licensee_id => licensee.id).first_or_create
    Property.where(:id => 20000, :name => 'test', :secret_key => 'test_key', :casino_id => casino.id).first_or_create

    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => 1, :sequence => 1).first_or_create
    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => 2, :sequence => 2).first_or_create
    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => 3, :sequence => 3).first_or_create

    TransactionSlip.where(:casino_id => 20000, :slip_type_id => 1, :next_number => 10001).first_or_create
    TransactionSlip.where(:casino_id => 20000, :slip_type_id => 2, :next_number => 10001).first_or_create

    TransactionTypesSlipType.where(:casino_id => 20000, :transaction_type_id => 1, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => 20000, :transaction_type_id => 2, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => 20000, :transaction_type_id => 3, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => 20000, :transaction_type_id => 4, :slip_type_id => 2).first_or_create

    shift = Shift.where(:roll_shift_at => nil, :casino_id => casino.id).first
    unless shift
      ac_date = AccountingDate.where(:accounting_date => Time.now.utc).first_or_create
      shift = Shift.create!(:shift_type_id => 1, :accounting_date_id => ac_date.id, :casino_id => casino.id)
    end
  end
end
