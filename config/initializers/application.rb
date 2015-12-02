APP_NAME = 'cage'
PROPERTY_ID = 20000
MACHINE_TYPE = 'cage'

TRANS_HISTORY_SEARCH_RANGE = Configuration.retrieve_config('trans_history_search_range')
POLLING_TIME = Configuration.retrieve_config('polling_time') * 60000
AUDIT_LOG_SEARCH_RANGE = Configuration.retrieve_config('audit_log_search_range')
CHANGE_LOG_SEARCH_RANGE = Configuration.retrieve_config('change_log_search_range')
TOKEN_LIFE_TIME = Configuration.retrieve_config('token_life_time') * 60
SESSION_EXPIRATION_TIME = Configuration.retrieve_config('session_life_time') * 60
ROLL_SHIFT_TIME = Configuration.find_by_key_and_property_id('roll_shift_time', PROPERTY_ID).value
CREDIT_LIFE_TIME = Configuration.retrieve_config('credit_life_time', PROPERTY_ID) * 24 * 3600