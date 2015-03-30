module LaxSupport

  # SimpleStore provides a generic/unified API for interacting with the following key/value stores:
  # 
  # * Memcache store
  # * In-memory store
  # * Tokyo Cabinet (via Rufus)
  # * Tokyo Tyrant  (via Rufus)
  #
  # You can specify the store adapter during the object construction time. 
  #
  # Example:
  #
  #    require 'lax-support'
  #    store = LaxSupport::SimpleStore::Base.new(
  #                       :adapter => 'Memcache', 
  #                       :server => "localhost:11211", 
  #                       :namespace => "my_store")
  #
  # == API
  #
  # The simple store provides the following generic API similar to Hash.
  # 
  #
  #   initialize(options)            options differs per-store, and is used to set up the store
  #
  #   [](key)                        retrieve a key. if the key is not available, return nil
  #
  #   []=(key, value)                set a value for a key. if the key is already used, clobber it.
  #                                  keys set using []= will never expire
  #
  #   delete(key)                    delete the key from the store and return the current value
  # 
  #   key?(key)                      true if the key exists, false if it does not
  #
  #   has_key?(key)                  alias for key?
  #
  #   store(key, value, options)     same as []=, but you can supply an :expires_in option, 
  #                                  which will specify a number of seconds before the key
  #                                  should expire. In order to support the same features
  #                                  across all stores, only full seconds are supported
  #
  #   add(key, value, options)       similar to store. it sets a value for a key only if 
  #                                  the key does not already exist in the store.
  #
  #   update_key(key, options)       updates an existing key with a new :expires_in option.
  #                                  if the key has already expired, it will not be updated.
  #
  #   clear                          clear all keys in this store
  # 
  # == Locks
  # 
  # Shared locks are built-in for SimpleStore
  #  
  # Example:
  # 
  #    store.synchronize('lock_name') do
  #      store["key"] = "value"
  #      # do whatever is supposed to do within this synchronized area
  #    end
  #
  module SimpleStore
    class AdapterNotFound < StandardError; end

    class Base
      include LockMixin

      def initialize(options = {})
        @adapter = options.delete(:adapter)
        unless LaxSupport::SimpleStore::Adapters.const_defined?(@adapter)
          raise AdapterNotFound, "Can NOT find adapter #{@adapter.inspect}"
        end
        if options.empty?
          @store = LaxSupport::SimpleStore::Adapters.const_get(@adapter).new
        else 
          @store = LaxSupport::SimpleStore::Adapters.const_get(@adapter).new(options)
        end
     
        @lock = options.delete(:lock)
        @lock = @store if @lock.nil?
      end     

      def method_missing(sym, *args, &block)
        @store.send(sym, *args, &block)
      end
    end
  end
end
