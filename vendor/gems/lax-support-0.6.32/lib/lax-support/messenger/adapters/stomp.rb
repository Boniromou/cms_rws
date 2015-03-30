require 'stomp'

module LaxSupport
  module Messenger
    module Adapters
      module Stomp

        class Connection < ::Stomp::Connection
          include LaxSupport::Messenger::Adapter
          register :stomp
  
          def initialize(cfg)
            cfg[:username] ||= ''
            cfg[:password] ||= ''
            cfg[:host] ||= 'localhost'
            cfg[:port] ||= '61613'
            cfg[:reliable] = false # force to false
            cfg[:reconnect_delay] ||= 5
            cfg[:connect_headers] ||= {}
          
            super(cfg[:username], cfg[:password], 
                  cfg[:host],     cfg[:port].to_i, 
                  cfg[:reliable], cfg[:reconnect_delay], 
                  cfg[:connect_headers])
          end
        end
      end 
    end
  end
end
