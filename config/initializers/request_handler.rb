service_config_file = "#{Rails.root}/config/service_config.yml"
Hood::CONFIG.load_service_config(service_config_file,Rails.env)
#Hood::CONFIG.property_keys = Property.get_property_keys
