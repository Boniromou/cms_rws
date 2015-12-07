require File.expand_path("../../../app/models/config_helper", __FILE__)

APP_NAME = 'cage'
MACHINE_TYPE = 'cage'
REQUESTER_CONFIG_FILE = "#{Rails.root}/config/requester_config.yml"
#PROPERTY_ID= 20000

ROLL_SHIFT_TIME = ConfigHelper.new(20000).roll_shift_time
