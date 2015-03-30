require 'time'

module LaxSupport
  module Event
    class InboundEvent < Base
      def initialize(msg={}, opts={:check_signature => true})
        super(msg)
        @_check_signature = opts[:check_signature]

        # Check required event parameters
        raise MissingEventParameter.new(:_event_src) unless @_store[:_event_src]
        raise MissingEventParameter.new(:_event_name) unless @_store[:_event_name]
        raise MissingEventParameter.new(:_host) unless @_store[:_host]
        raise MissingEventParameter.new(:_created_at) unless @_store[:_created_at]
        raise MissingEventParameter.new(:_signature) unless !@_check_signature || @_store[:_signature]

        # Store event signature internally
        @_signature = @_store[:_signature]

        # Validate event signature  
        raise SignatureMismatched unless valid?

        # If _created_at is a string, use Time.parse to parse it into a Time object
        # Or leave it as it is.
        if @_store[:_created_at].kind_of?(String)
          @_store[:_created_at] = Time.parse(@_store[:_created_at])
        end
 
        # Make core parameters read-only
        @_store.protect(:_event_src)
        @_store.protect(:_event_name)
        @_store.protect(:_host)
        @_store.protect(:_created_at)

        # Switch off event changed flag
        @_store.changed = false
      end
  
      # Validate event signature
      def valid?
        return true unless @_check_signature
        @_store.delete(:_signature)
        v = @_signature == self.class.generate_signature(get_key, @_store.to_str)
        @_store[:_signature] = @_signature
        return v
      end
    end
  end
end 
