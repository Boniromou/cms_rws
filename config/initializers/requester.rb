Dir[Rails.root.join 'lib/requester/*.rb'].each {|file| require file }
request_config_file = "#{Rails.root}/config/request_config.yml"
REQUESTER_FACTORY = Requester::RequesterFactory.new(request_config_file, Rails.env, PROPERTY_ID,Property.get_property_keys[PROPERTY_ID])
