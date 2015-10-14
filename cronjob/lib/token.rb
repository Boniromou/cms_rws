module Cronjob
  class Token < ActiveRecord::Base
    class << self
      def clean_expired_tokens
        tokens = Token.where('expired_at < ?', Time.now)
        puts "#{tokens.length} tokens expired"
        tokens.delete_all        
      end
    end
  end
end
