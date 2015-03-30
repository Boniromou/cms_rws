require 'time'

module LaxSupport

  module AuthorizedRWS

    class InvalidPropertyID < LaxSupport::RWSError
      def initialize
        super(403, 'The Laxino Property ID you provided does not exist in our records.') 
      end
    end

    class InvalidServiceID < LaxSupport::RWSError
      def initialize
        super(403, 'The Laxino Service ID you provided does not exist in our records.')
      end
    end

    class MissingSecurityHeader < LaxSupport::RWSError
      def initialize
        super(400, 'Your request was missing a required header.')
      end
    end

    class MismatchedSignature < LaxSupport::RWSError
      def initialize
        super(401, 'The request signature we calculated does not match the signature you provided. Check your Secret Access Key and signing method.')
      end
    end

    class RequestTimeTooSkewed < LaxSupport::RWSError
      def initialize
        super(403, 'The difference between the request time and the server\'s time is too large')
      end
    end

    class Parser
      include Authentication

      # Contrust an instance of Authorized RWS Parser 
      # which is used to verify a request's authorization headers
      # properties and services are hash variables containing 
      # property ID/service ID and the corresponding secret access key:
      #     properties = { 1001 => 'secret key for property 1001',
      #                    1002 => 'secret key for property 1002'
      #                  }
      #     services   = { 1 => 'secret key for service 1',
      #                    2 => 'secret key for service 2'
      #                  }
      def initialize(properties={}, services={})
        @properties = properties
        @services   = services
      end

      # Verify whether the authorization headers for a given request is valid or not.
      # Once the request passes the authentication, the following info will be returned:
      #
      #     [ property_id, service_id ]
      #
      def verify(http_method, path, headers)
        raise MissingSecurityHeader unless headers['Authorization'] and headers['Date']
        property_id, service_id, signed, request_time = parse(headers) 
        raise RequestTimeTooSkewed if (Time.now - request_time).abs > 300 # 5 minutes
        secret_access_key = ''
        if service_id == 0
          secret_access_key = @properties[property_id]
          raise InvalidPropertyID unless secret_access_key
        else
          secret_access_key = @services[service_id]
          raise InvalidServiceID unless secret_access_key
        end
        raise MismatchedSignature unless signed == self.signature(secret_access_key, path, http_method, headers)
        [ property_id, service_id ]
      end
  
      protected

      # Parse security headers and return:
      #   property_id, service_id, signature, request_time
      def parse(headers)
        matched_data = /^LAXRWS (\d+):(.+)/.match(headers['Authorization'])
        request_time = headers['Date']
        request_time = if request_time.kind_of?(String)
                         Time.parse(request_time)
                       elsif request_time.kind_of?(Time)
                         request_time
                       else
                         Time.at(0)
                       end
        [ 
          matched_data[1].to_i,             # property ID
          headers['x-lax-service-id'].to_i, # service_id
          matched_data[2],                  # signature
          request_time                      # request_time
        ]
      end 
    end
  end
end
