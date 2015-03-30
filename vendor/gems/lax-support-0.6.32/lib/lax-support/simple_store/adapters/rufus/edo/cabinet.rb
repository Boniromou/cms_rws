require "rufus/tokyo"

module LaxSupport
  module SimpleStore
    module Adapters
      module Rufus
        module Edo 
          class Base < ::Rufus::Edo::Cabinet    
            def initialize(options = {})
              file = options[:file]
              super("#{file}.tch")
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
  
          class Cabinet < Base
            include Expiration
    
            def initialize(options = {})
              file = options[:file]
              @expiration = Base.new(:file => "#{file}_expires")
              super
            end
          end
        end
      end
    end
  end
end
