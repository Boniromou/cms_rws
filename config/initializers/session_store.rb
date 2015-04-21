# Be sure to restart your server when you modify this file.

#CmsRws::Application.config.session_store :cookie_store, key: '_cms_rws_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# CmsRws::Application.config.session_store :active_record_store

require 'action_dispatch/middleware/session/dalli_store'

filename = Rails.root.join('config', 'memcache.yml')
if File.file?(filename)
  mem_config = YAML::load_file(filename)

  if mem_config.is_a?(Hash) && mem_config.has_key?(Rails.env)
    mem_config = mem_config[Rails.env]
    mem_config.each do |k, v|
      v.symbolize_keys! if v.respond_to?(:symbolize_keys!)
    end

    CmsRws::Application.config.session_store :dalli_store,
                                             :key => '_cms_rws_session',
                                             #:domain => SITE_DOMAIN,
                                             :memcache_server => mem_config['servers'],
                                             :namespace => mem_config['namespace'],
                                             :expires_in => mem_config['expires'],
                                             :socket_timeout => mem_config['timeout'],
                                             :keepalive => true
  end
end
