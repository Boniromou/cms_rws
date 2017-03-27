CmsRws::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  #SITE_DOMAIN = 'laxino.com'
  config.cache_store = :dalli_store,
                       'hq-int-s3-app01.laxino.local:11211', 'hq-int-s3-app01.laxino.local:11212',
                        {:namespace => 'cirrus_dev',
                         :expires_in => 1.day,
                         :socket_timeout => 3,
                         :compress => true }
end

SSO_URL = 'http://mingwong01.rnd.laxino.com:3333'
REGISTRATION_PATH = '/register'
RESET_PASSWORD_PATH = '/passwords'
WALLET_URL = 'http://mingwong01.rnd.laxino.com:5555'
WALLET_PATH = '/cwms'
PATRON_URL = 'http://mingwong01.rnd.laxino.com:6666'
PATRON_PATH = '/pis'
STATION_URL = 'http://marcusao01.rnd.laxino.com:5000'
