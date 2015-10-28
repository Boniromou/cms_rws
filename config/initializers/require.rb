require 'errors'
Dir[Rails.root.join 'lib/requester/*.rb'].each {|file| require file }
