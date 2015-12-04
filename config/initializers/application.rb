require File.expand_path("../../app/models/config_helper", __FILE__)

APP_NAME = 'cage'
MACHINE_TYPE = 'cage'
#PROPERTY_ID= 20000

ROLL_SHIFT_TIME = ConfigHelper.new(20000).roll_shift_time