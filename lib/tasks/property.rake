require File.expand_path("../../../config/environment", __FILE__)
namespace :property do
  task :create do
    property_id = ENV['property_id']
    send "create_#{property_id}_data"
  end

  task :remove do
    property_id = ENV['property_id']
    casino_id = ENV['casino_id']
    licensee_id = ENV['licensee_id']
    remove_data(:property_id => property_id, :casino_id => casino_id, :licensee_id => licensee_id)
  end


  def create_20000_data
    create_property_data(:property_id => 20000, :property_name => 'MockUp', :casino_id => 20000, :casino_name => 'MockUp', :licensee_id => 20000, :licensee_name => 'MockUp')
  end

  def create_40000_data
    create_property_data(:property_id => 40000, :property_name => 'MockUp', :casino_id => 40000, :casino_name => 'Mgm testing', :licensee_id => 40000, :licensee_name => 'Mgm testing')
  end

  def create_property_data(params)
    property_id = params[:property_id]
    property_name = params[:property_name]
    casino_id = params[:casino_id]
    casino_name = params[:casino_name]
    licensee_id = params[:licensee_id]
    licensee_name = params[:licensee_name]

    licensee = Licensee.where(:id => licensee_id, :name => licensee_name).first_or_create
    casino = Casino.where(:id => casino_id, :name => casino_name, :licensee_id => licensee.id).first_or_create
    Property.where(:id => property_id, :name => property_name, :secret_key => 'test_key', :casino_id => casino.id).first_or_create

    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 1, :sequence => 1).first_or_create
    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 2, :sequence => 2).first_or_create
    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 3, :sequence => 3).first_or_create

    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 1, :next_number => 10001).first_or_create
    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 2, :next_number => 10001).first_or_create

    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 1, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 2, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 3, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 4, :slip_type_id => 2).first_or_create

    shift = Shift.where(:roll_shift_at => nil, :casino_id => casino.id).first
    unless shift
      ac_date = AccountingDate.where(:accounting_date => Time.now.utc).first_or_create
      shift = Shift.create!(:shift_type_id => 1, :accounting_date_id => ac_date.id, :casino_id => casino.id)
    end
  end

  def remove_data(params)
    property_id = params[:property_id]
    casino_id = params[:casino_id]
    licensee_id = params[:licensee_id]

    Shift.where(:casino_id => casino_id).delete_all
    TransactionTypesSlipType.where(:casino_id => casino_id).delete_all
    TransactionSlip.where(:casino_id => casino_id).delete_all
    CasinosShiftType.where(:casino_id => casino_id).delete_all

    Property.where(:id => property_id).delete_all
    Casino.where(:id => casino_id).delete_all
    Licensee.where(:id => licensee_id).delete_all
  end
end
