require "memcache"

module LaxSupport
  module SimpleStore
    module Adapters  
      class Memcache
        def initialize(options = {})
          @lock = options.delete(:lock)
          @server = options.delete(:server)
          @store = MemCache.new(@server, options)
          @lock = @store if @lock.nil?
        end
    
        def key?(key)
          !self[key].nil?
        end
    
        alias has_key? key?
    
        def [](key)
          @store.get(key)
        end
     
        def []=(key, value)
          store(key, value)
        end
    
        def fetch(key, default)
          self[key] || default
        end
      
        def delete(key)
          value = self[key]
          @store.delete(key) if value
          value
        end
      
        def store(key, value, options = {})
          args = [key, value, options[:expires_in]].compact
          @store.set(*args)
        end

        def add(key, value, options = {})
          args = [key, value, options[:expires_in]].compact
          @store.add(*args)
        end
      
        def update_key(key, options = {})
          val = self[key]
          self.store(key, val, options)
        end
      
        def clear
          @store.flush_all
        end
      end
    end
  end
end
