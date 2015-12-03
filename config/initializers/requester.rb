Dir[Rails.root.join 'lib/requester/*.rb'].each {|file| require file }
requester_config_file = "#{Rails.root}/config/requester_config.yml"
REQUESTER_FACTORY = Requester::RequesterFactory.new(requester_config_file, Rails.env, nil, nil)
