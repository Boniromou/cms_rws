ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment",__FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'phantomjs'
require 'capybara/rspec'
require 'phantomjs/poltergeist'
require 'database_cleaner'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, :phantomjs => Phantomjs.path, :js_errors => false, :default_wait_time => 5, :timeout => 90)
end

Capybara.javascript_driver = :poltergeist

Devise::TestHelpers
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/features/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("app/helpers/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("lib/**/*.rb")].each {|f| require f}

Capybara.ignore_hidden_elements = false
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

# Capybara.server do |app, port|
#   require 'rack/handler/thin'
#   Rack::Handler::Thin.run(app, :Port => port)
# end
