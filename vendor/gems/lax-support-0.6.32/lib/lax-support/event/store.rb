require 'forwardable'
require 'yaml'
require 'amf'

module LaxSupport
  module Event
    class Store
      extend Forwardable
      
      # Overload the getter and setter for 
      # instance variable, @_changed
      def changed; @_changed; end 
      def changed=(c); @_changed = c; end
      alias :changed? :changed

      # Takes an optional Hash of parameters
      def initialize(msg = {})
        @_store = {}
        @_protected = []
        @_changed = false
        configure(msg)
      end

      # Forward method calls to the actual  
      # hash-based data store (@_store)
      def_delegators :@_store, 
                     :[], :clear, :size, 
                     :keys, :has_key?, :key?, 
                     :values, :value?, :has_value?
   
      # Returns a Hash representing the event 
      def to_hash
        @_store
      end

      # Returns a YAML representing the event
      def to_yaml
        @_store.to_yaml
      end

      # Return a AMF representing the event
      def to_amf
        @_store.to_amf
      end

      # Returns a string representing the event
      def to_str
        v = []
        @_store.to_str.each_char { |c| v << c }
        v.sort.to_str
      end

      # Allows for the message of the event via either Hash or YAML
      def configure(msg)
        case msg
          when String then configure_from_yaml(msg)
          when Hash   then configure_from_hash(msg)
          else raise InvalidEventMessage
        end
      end
  
      # Allows for the message of the event via a Hash
      def configure_from_hash(msg)
        msg.keys.each do |name|
          raise ProtectedEventParameter.new(name) if @_protected.include?(name)
        end
        @_store.merge!(msg)
        self.changed = true
      end

      # Allows for the message of the event via YAML
      def configure_from_yaml(msg)
        configure_from_hash(YAML.load(msg))
      end

      # Assign value to event parameter
      def []=(name, value)
        raise ProtectedEventParameter.new(name) if @_protected.include?(name.to_sym)
        self.changed = true
        @_store[name.to_sym] = value
      end

      # Removes an event parameter 
      def delete(name)
        raise ProtectedEventParameter.new(name) if @_protected.include?(name.to_sym)
        self.changed = true
        @_store.delete(name.to_sym)
      end

      # Sets a 'default' value. If there is already a value specified
      # it won't set the value.
      def set_default(name, default_value)
        unless @_store[name.to_sym]
          self.changed = true
          @_store[name.to_sym] = default_value
        end
      end

      # Prevents a parameter from being reassigned. 
      def protect(name)
        @_protected << name.to_sym
      end
 
      # Removes the protection of a parameter.
      def unprotect(name)
        @_protected.reject! { |e| e == name.to_sym }
      end
    end
  end
end

