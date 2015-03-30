require 'openssl'
require 'base64'

module LaxSupport
  module Event
    class Base 
      def initialize(msg={}) # :nodoc:
        @_store = Store.new(msg)

        raise MissingEventParameter.new(:_env) unless @_store[:_env]

        # Make read-only parameters
        @_store.protect(:_env)
      end

      # Forwards the method call onto the Events::Store
      def method_missing(sym, *args)
        @_store.send(sym, *args)
      end

      def to_hash
        @_store.to_hash
      end

      def to_yaml
        @_store.to_yaml
      end

      def to_amf
        @_store.to_amf
      end

      protected

      # Class method to generate signature with given secret key and data
      def self.generate_signature(key, data)
        Base64.encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('md5'), key, data)).strip
      end

      # Default secret key
      def get_key
        "Lax -- #{@_store[:_env]} -- #{@_store[:_host]} -- #{@_store[:_event_src]} -- #{@_store[:_event_name]} -- #{@_store[:_created_at]}".reverse
      end
    end
  end
end
