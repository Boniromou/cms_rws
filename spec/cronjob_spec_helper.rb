ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment",__FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'phantomjs'
require 'capybara/rspec'
require 'phantomjs/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, :phantomjs => Phantomjs.path, :js_errors => false, :default_wait_time => 5, :timeout => 90)
end

Capybara.javascript_driver = :poltergeist

Devise::TestHelpers
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("app/helpers/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("lib/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("cronjob/lib/*.rb")].each {|f| require f}

Capybara.ignore_hidden_elements = false

  def create_shift_data
    @accounting_date = Time.now.strftime("%Y-%m-%d")
    @today = Date.parse(@accounting_date)

    @moring_shift_type = ShiftType.create!(:name => 'morning')
    @swing_shift_type = ShiftType.create!(:name => 'swing')
    @night_shift_type = ShiftType.create!(:name => 'night')

    @accounting_date_id = AccountingDate.create!(:accounting_date => @accounting_date).id
    create_moring_swing_night_shift_sequence

    # @station_id = Station.create!(:name => 'window#1').id
    # allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
  end

  def create_moring_swing_night_shift_sequence
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @moring_shift_type.id, :sequence => 1)
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @swing_shift_type.id, :sequence => 2)
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @night_shift_type.id, :sequence => 3)
    Shift.delete_all
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000)
  end
  
  def create_past_shift
    Shift.delete_all
    @past_accounting_date_id = AccountingDate.create!(:accounting_date => (Time.now - 5.day).strftime("%Y-%m-%d")).id
    @past_shift = Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @past_accounting_date_id)
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id)
  end

RSpec.configure do |config|
  config.include FundHelper, type: :feature
  config.include Devise::TestHelpers, :type => :controller
  config.extend ControllerHelpers, :type => :controller
  config.fixture_path = "#{::Rails.root}/spec/features/fixtures"
  config.use_transactional_fixtures = false

  config.before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:client_ip).and_return("192.1.1.1")
  end

  config.infer_spec_type_from_file_location!
end
