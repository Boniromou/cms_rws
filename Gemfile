source 'https://rubygems.org'

gem 'rails', '3.2.19'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'
gem 'lax-support', '0.6.32', :path => "vendor/gems/lax-support-0.6.32"
gem 'hood', :path=>"vendor/gems/hood-1.0.0"
gem 'sequel'
gem 'httparty'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

gem 'devise', '3.2.4'
gem 'pundit'

group :ldap do
  gem "net-ldap", "~> 0.3.1"
end

gem 'dalli', "~> 2.0.3"

gem 'thin', '1.6.2'

group :development, :test do
  gem 'rspec-rails', '~> 3.0.0'
end

group :test do
  gem 'capybara', '2.4.3'
  gem 'poltergeist'
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
  gem 'simplecov'
  #gem 'capybara-webkit'
end

