module Hood
  class LaxRequester
    include Hood::Loggable

    private_class_method :new
    class << self
      def get_external_requester(property_id,secret_access_key,base_uri,raise_on_failure=false)
        requester = LaxSupport::AuthorizedRWS::Base.new(property_id,secret_access_key)
        new(requester,base_uri,raise_on_failure)
      end

      def get_internal_requester(property_id,service_id,secret_access_key,base_uri,raise_on_failure=false)
        requester = LaxSupport::AuthorizedRWS::LaxRWS.new(property_id,service_id,secret_access_key)
        new(requester,base_uri,raise_on_failure)
      end
    end

    def initialize(requester,base_uri,raise_on_failure=false)
      @requester = requester
      @base_uri = base_uri
      @raise_on_failure = raise_on_failure
    end

    def send_request(method,path,msg={},opts={})
      timeout = opts[:timeout] || 5
      base_uri = opts[:base_uri] || @base_uri
      uri = "#{base_uri}/#{path}"
      if method == :get
        options = {:query=>msg}
      else
        options = {:body=>msg}
      end
      logger.info "remote call: #{method} #{uri} with options #{options.inspect} at #{Time.now.to_f}"
      begin
        @requester.timeout = timeout
        response = @requester.__send__(method,uri,options).body
        logger.info "receive response at #{Time.now.to_f}:"
        logger.info response
        return response
      rescue Exception => e
        logger.error "remote call exception: #{e.message} at #{Time.now.to_f}"
        logger.error e.backtrace.join("\n")
        if @raise_on_failure
          raise Hood::InternalError.new
        else
          return nil
        end
      end
    end
  end
end
