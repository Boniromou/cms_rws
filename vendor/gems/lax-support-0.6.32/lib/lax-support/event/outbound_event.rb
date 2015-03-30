require 'socket'

module LaxSupport
  module Event
    class OutboundEvent < Base
      def initialize(msg={})
        # Signature should be generated ONLY internally
        raise ProtectedEventParameter.new(:_signature) if msg[:_signature]

        super

        # Initialize core parameters
        @_store[:_host]       = Socket.gethostname
        # Populate the creation timestamp with precision of microsecond
        _now = Time.now.utc
        @_store[:_created_at] = _now.strftime("%Y-%m-%d %H:%M:%S.#{_now.usec} UTC")

        # Make core parameters read-only
        @_store.protect(:_host)
        @_store.protect(:_created_at)

        # Switch on event changed flag
        @_store.changed = true
      end      

      # Generate event signature
      def sign
        # Sign again only when event paramters were changed
        if @_store.changed?
          @_store.delete(:_signature)
          @_store[:_signature] = self.class.generate_signature(get_key, @_store.to_str)
          # Once the event is signed, switch off the event changed flag
          @_store.changed = false
        end
      end    
      
      def to_yaml
        check_required_parameters
        sign 
        @_store.to_yaml
      end

      def to_hash
        check_required_parameters
        sign
        @_store.to_hash
      end

      def to_amf
        check_required_parameters
        sign
        @_store.to_amf
      end

      protected
      
      def check_required_parameters
        raise MissingEventParameter.new(:_event_src) unless @_store[:_event_src]
        raise MissingEventParameter.new(:_event_name) unless @_store[:_event_name]
      end

    end
  end
end 
