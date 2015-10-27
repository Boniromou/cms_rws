APP_NAME = 'cage'
PROPERTY_ID = 20000

TRANS_HISTORY_SEARCH_RANGE = Configuration.retrieve_config('trans_history_search_range')
POLLING_TIME = Configuration.retrieve_config('polling_time') * 60000
AUDIT_LOG_SEARCH_RANGE = Configuration.retrieve_config('audit_log_search_range')
CHANGE_LOG_SEARCH_RANGE = Configuration.retrieve_config('change_log_search_range')
TOKEN_LIFE_TIME = Configuration.retrieve_config('token_life_time') * 60
SESSION_EXPIRATION_TIME = Configuration.retrieve_config('session_life_time') * 60