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

  task :testing do
    create_test_data
  end


  def create_20000_data
    create_property_data(:property_id => 20000, :property_name => 'MockUp', :casino_id => 20000, :casino_name => 'MockUp', :licensee_id => 20000, :licensee_name => 'MockUp')
  end

  def create_20001_data
    create_property_data(:property_id => 20001, :property_name => 'property1', :casino_id => 20000, :casino_name => 'MockUp', :licensee_id => 20000, :licensee_name => 'MockUp')
  end

  def create_20002_data
    create_property_data(:property_id => 20002, :property_name => 'property2', :casino_id => 20001, :casino_name => 'casino1', :licensee_id => 20000, :licensee_name => 'MockUp')
  end

  def create_20003_data
    create_property_data(:property_id => 20003, :property_name => 'property3', :casino_id => 20002, :casino_name => 'casino2', :licensee_id => 20001, :licensee_name => 'Licensee1')
  end
  
  def create_40000_data
    create_property_data(:property_id => 40000, :property_name => 'MockUp', :casino_id => 40000, :casino_name => 'Mgm testing', :licensee_id => 40000, :licensee_name => 'Mgm testing')
  end


  
  
  
  def create_10000_data
    create_property_data(:property_id => 10000, :property_name => 'RUBY_VIP01', :casino_id => 10000, :casino_name => 'Casino Ruby', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10001_data
    create_property_data(:property_id => 10001, :property_name => 'RUBY_TOUR', :casino_id => 10000, :casino_name => 'Casino Ruby', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10002_data
    create_property_data(:property_id => 10002, :property_name => 'DIAMOND_MASS01', :casino_id => 10001, :casino_name => 'Casino Diamond', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10003_data
    create_property_data(:property_id => 10003, :property_name => '10003', :casino_id => 10000, :casino_name => 'Casino Diamond', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10004_data
    create_property_data(:property_id => 10004, :property_name => '10004', :casino_id => 10000, :casino_name => 'Casino Diamond', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10005_data
    create_property_data(:property_id => 10005, :property_name => '10005', :casino_id => 10001, :casino_name => 'Casino Diamond', :licensee_id => 10000, :licensee_name => 'Alpha Group Limited')
  end

  def create_10006_data
    create_property_data(:property_id => 10006, :property_name => 'Demo Config. 1', :casino_id => 10006, :casino_name => 'PIA Demo Macau', :licensee_id => 10006, :licensee_name => 'PIA Demo')
  end

  def create_10010_data
    create_day_shift_property_data(:property_id => 10010, :property_name => 'MGM Macau Config.Grp.1', :casino_id => 10010, :casino_name => 'MGM Macau', :licensee_id => 10010, :licensee_name => 'MGM Grand Paradise Limited')
  end
  
  
  
  
  
  def create_9000_data
    create_property_data(:property_id => 9000, :property_name => 'DS1-Config1', :casino_id => 9000, :casino_name => 'DemoSite1', :licensee_id => 9000, :licensee_name => 'Demo')
  end
  
  
  
  
  
  def create_test_data
    Licensee.where(:id => 1003, :name => 'test').first_or_create
    Casino.where(:id => 1003, :name => 'test', :licensee_id => 1003).first_or_create

    property_id = 20000
    property_name = 'MockUp'
    casino_id = property_id
    casino_name = property_name
    licensee_id = property_id
    licensee_name = property_name
    
    licensee = Licensee.where(:id => licensee_id, :name => licensee_name).first_or_create
    casino = Casino.where(:id => casino_id, :name => casino_name, :licensee_id => licensee.id).first_or_create
    Property.where(:id => property_id, :name => property_name, :secret_key => 'test_key', :casino_id => casino.id).first_or_create
    
    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 1, :next_number => 10001).first_or_create
    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 2, :next_number => 10001).first_or_create
    
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 1, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 2, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 3, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 4, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 8, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 9, :slip_type_id => 2).first_or_create
  
    ruby "#{File.expand_path("../../../script/init_scripts/sync_configs.rb", __FILE__)} test 20000"
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
    Property.where(:id => property_id, :name => property_name, :casino_id => casino.id).first_or_create

    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 1, :sequence => 1).first_or_create
    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 2, :sequence => 2).first_or_create
    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 3, :sequence => 3).first_or_create

    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 1, :next_number => 10001).first_or_create
    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 2, :next_number => 10001).first_or_create

    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 1, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 2, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 3, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 4, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 8, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 9, :slip_type_id => 2).first_or_create

    shift = Shift.where(:roll_shift_at => nil, :casino_id => casino.id).first
    unless shift
      ac_date = AccountingDate.where(:accounting_date => Time.now.utc.to_date).first_or_create
      shift = Shift.create!(:shift_type_id => 1, :accounting_date_id => ac_date.id, :casino_id => casino.id)
    end
  end
  
  def create_day_shift_property_data(params)
    property_id = params[:property_id]
    property_name = params[:property_name]
    casino_id = params[:casino_id]
    casino_name = params[:casino_name]
    licensee_id = params[:licensee_id]
    licensee_name = params[:licensee_name]

    licensee = Licensee.where(:id => licensee_id, :name => licensee_name).first_or_create
    casino = Casino.where(:id => casino_id, :name => casino_name, :licensee_id => licensee.id).first_or_create
    Property.where(:id => property_id, :name => property_name, :casino_id => casino.id).first_or_create

    CasinosShiftType.where(:casino_id => casino_id, :shift_type_id => 4, :sequence => 1).first_or_create

    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 1, :next_number => 10001).first_or_create
    TransactionSlip.where(:casino_id => casino_id, :slip_type_id => 2, :next_number => 10001).first_or_create

    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 1, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 2, :slip_type_id => 2).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 3, :slip_type_id => 1).first_or_create
    TransactionTypesSlipType.where(:casino_id => casino_id, :transaction_type_id => 4, :slip_type_id => 2).first_or_create

    shift = Shift.where(:roll_shift_at => nil, :casino_id => casino.id).first
    unless shift
      ac_date = AccountingDate.where(:accounting_date => Time.now.utc.to_date).first_or_create
      shift = Shift.create!(:shift_type_id => 4, :accounting_date_id => ac_date.id, :casino_id => casino.id)
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
