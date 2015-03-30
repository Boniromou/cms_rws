ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment",__FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:client_ip).and_return("192.1.1.1")
  end
end
