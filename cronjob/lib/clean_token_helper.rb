module Cronjob
  class CleanTokenHelper
    def run
      Token.clean_expired_tokens
    end
  end
end
