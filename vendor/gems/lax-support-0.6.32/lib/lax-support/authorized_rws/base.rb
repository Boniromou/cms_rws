require 'httparty'
if RUBY_VERSION =~ /1.8/
  require 'system_timer'
else
  require 'timeout'
end

module LaxSupport

  module AuthorizedRWS

    # AuthorizedRWS is a wrapper class on top of HTTParty
    class Base
      include HTTParty
      include Authentication

      # Make defult_options as a class instance varaible
      # This is to override the module inheritable attribute
      # default_options from HTTParty
      def self.inherited(subclass)
        subclass.instance_variable_set("@default_options", {})
      end

      # The ID for a given property (mandatory)
      attr_accessor :property_id

      # The secret access key for a given property (mandatory)
      attr_accessor :secret_access_key

      # The prefix for property service. (optional; default: LAXRWS)
      attr_accessor :property_service_prefix

      # The timeout threshold for all HTTP method calls (optional; default: nil)
      attr_accessor :timeout 

      # Contruct a new instance of Authorized RWS client 
      # with the given property ID, secret access key and 
      # property service prefix (optional; default: LAXRWS) 
      def initialize(property_id, secret_access_key, property_service_prefix='LAXRWS')
        @property_id = property_id
        @secret_access_key = secret_access_key
        @property_service_prefix = property_service_prefix
        @timeout = nil
      end
 
      # HTTP GET implementation. 
      # You can specify :headers as part of the options hash. 
      # You can also specify :timeout as part of the optinos hash to 
      # specify the timeout threshold for the given HTTP method call. 
      # :timeout will take precedence over instance attribute, @timeout, if given. 
      def get(path, options={})
        headers = prepare_headers(:get, path, options[:headers])
        timeout = options[:timeout] || @timeout
        if timeout.nil? 
          self.class.get(path, options.merge(:headers => headers))
        else
          if RUBY_VERSION =~ /1.8/
            SystemTimer.timeout(timeout.to_f) do
              self.class.get(path, options.merge(:headers => headers))
            end
          else
            Timeout.timeout(timeout.to_f) do
              self.class.get(path, options.merge(:headers => headers))
            end
          end
        end
      end
 
      # HTTP POST implementation. 
      # You can specify :headers as part of the options hash. 
      # You can also specify :timeout as part of the optinos hash to
      # specify the timeout threshold for the given HTTP method call.
      # :timeout will take precedence over instance attribute, @timeout, if given.
      def post(path, options={})
        headers = prepare_headers(:post, path, options[:headers])
        timeout = options[:timeout] || @timeout
        if timeout.nil?
          self.class.post(path, options.merge(:headers => headers))
        else
          if RUBY_VERSION =~ /1.8/
            SystemTimer.timeout(timeout.to_f) do
              self.class.post(path, options.merge(:headers => headers))
            end
          else
            Timeout.timeout(timeout.to_f) do
              self.class.post(path, options.merge(:headers => headers))
            end
          end
        end
      end
  
      # HTTP PUT implementation.
      # You can specify :headers as part of the options hash.
      # You can also specify :timeout as part of the optinos hash to
      # specify the timeout threshold for the given HTTP method call.
      # :timeout will take precedence over instance attribute, @timeout, if given.
      def put(path, options={})
        headers = prepare_headers(:put, path, options[:headers])
        timeout = options[:timeout] || @timeout
        if timeout.nil?
          self.class.put(path, options.merge(:headers => headers))
        else
          if RUBY_VERSION =~ /1.8/
            SystemTimer.timeout(timeout.to_f) do
              self.class.put(path, options.merge(:headers => headers))
            end
          else
            Timeout.timeout(timeout.to_f) do
              self.class.put(path, options.merge(:headers => headers))
            end
          end
        end
      end
  
      # HTTP DELETE implementation.
      # You can specify :headers as part of the options hash.
      # You can also specify :timeout as part of the optinos hash to
      # specify the timeout threshold for the given HTTP method call.
      # :timeout will take precedence over instance attribute, @timeout, if given.
      def delete(path, options={})
        headers = prepare_headers(:delete, path, options[:headers])
        timeout = options[:timeout] || @timeout
        if timeout.nil?
          self.class.delete(path, options.merge(:headers => headers))
        else
          if RUBY_VERSION =~ /1.8/
            SystemTimer.timeout(timeout.to_f) do
              self.class.delete(path, options.merge(:headers => headers))
            end
          else
            Timeout.timeout(timeout.to_f) do
              self.class.delete(path, options.merge(:headers => headers))
            end
          end
        end
      end
  
      protected

      # Prepare the HTTP authorization headers
      def prepare_headers(http_method, path, headers)
        headers = {} if headers.nil?
        if [:post, :put, :delete].include?(http_method)
          headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }.merge(headers) 
        end
        # Stringify keys in headers
        headers.keys.each { |k| headers[k.to_s] = headers.delete(k) }
        headers['Date'] ||= Time.now.httpdate
        signed = signature(@secret_access_key, URI.parse(path).path, http_method, headers)
        headers['Authorization'] = "#{@property_service_prefix} #{@property_id}:#{signed}"
        headers
      end
    end
 
    class LaxRWS < Base
      attr_accessor :service_id

      # Contruct a new instance of Authorized RWS client used in Laxino
      # with the given property ID, service ID, secret access key and
      # property service prefix (optional; default: LAXRWS)
      def initialize(property_id, service_id, secret_access_key, property_service_prefix='LAXRWS')
        @service_id = service_id
        super(property_id, secret_access_key, property_service_prefix)
      end

      protected
      
      # Prepare the HTTP authorization headers
      # A customized header is added: 
      #   x-lax-service-id
      # which contains the service ID
      def prepare_headers(http_method, path, headers) 
        headers = {} if headers.nil?
        # Add service ID to HTTP header
        super(http_method, path, headers.merge('x-lax-service-id' => @service_id.to_s))
      end
    end
   
  end
end
