module LaxSupport
  module SimpleStore
    module Adapters
      class Memory < Hash
        include Expiration
  
        def initialize(*args)
          @expiration = {}
          super
        end

      end
    end
  end
end
