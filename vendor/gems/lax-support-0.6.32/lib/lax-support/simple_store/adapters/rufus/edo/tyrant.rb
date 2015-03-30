require "rufus/tokyo/tyrant"

module LaxSupport
  module SimpleStore
    module Adapters
      module Rufus
        module Edo
          class Tyrant < ::Rufus::Edo::Tyrant
            module Implementation
              def initialize(options = {})
                host = options[:host]
                port = options[:port]
                super(host, port)
              end      
      
              def key?(key)
                !!self[key]
              end
    
              def [](key)
                if val = super
                  Marshal.load(val)
                end
              end
    
              def []=(key, value)
                super(key, Marshal.dump(value))
              end
    
              def fetch(key, default)
                self[key] || default
              end
    
              def store(key, value, options = {})
                self[key] = value
              end
            end
            include Implementation
            include Expiration
    
            def initialize(options = {})
              super
              @expiration = Expiry.new(options)
            end
    
            class Expiry < ::Rufus::Edo::Tyrant
              include Implementation
        
              def [](key)
                super("#{key}__expiration")
              end
          
              def []=(key, value)
                super("#{key}__expiration", value)
              end
        
              def delete(key)
                super("#{key}__expiration")
              end
            end
          end
        end
      end  
    end
  end
end
