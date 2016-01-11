require 'active_support/all'
module Hood

  class RwsService
    include Hood::Loggable

    def initialize(base_uri)
      config = Hood::CONFIG
      @requester = Hood::LaxRequester.get_internal_requester(config.internal_property_id,config.service_id,
                                                       config.service_key,base_uri)
    end

    def send_request(method,path,msg={},opts={})
      @requester.send_request(method,path,msg,opts)
    end
  end

  class AmsService < RwsService
    
    def initialize
      super(Hood::CONFIG.ams_uri)
    end

    def create_player(property_id,login_name,currency)
      msg = {:property_id=>property_id,:login_name=>login_name,:currency=>currency}
      response = send_request(:post,'create_player',msg)
      raise Hood::InternalError.new('call ams failed') unless response
      res = YAML.load(response)
      case res[:error_code]
      when 'OK'
        return {:id=>res[:id],:login_name=>res[:login_name],:currency=>res[:currency],:currency_id=>res[:currency_id]}
      when 'CurrencyNotSupport'
        raise Hood::CurrencyNotSupport
      when 'CurrencyNotMatch'
        raise Hood::CurrencyNotMatch
      end
      raise Hood::InternalError.new('call ams failed')
    end

  end

  class ValidateTokenService < RwsService
    def initialize
    end

    def validate_token(property_id, login_name, session_token)
      config = Hood::CONFIG
      return true unless config.is_validate_token
      @requester = Hood::LaxRequester.get_external_requester(property_id,config.property_keys[property_id],config.validate_token_uri)
      msg = {:login_name => login_name, :session_token => session_token}
      response = send_request(:get, 'validate_token', msg)
      raise Hood::InternalError.new('call cms failed') unless response
      res = YAML.load(response).symbolize_keys
      case res[:error_code]
      when 'OK'
        return true
      when 'InvalidSessionToken'
        raise Hood::InvalidSessionToken.new(res[:error_msg])
      end
      raise Hood::InternalError.new('call cms failed')
    end

    def lock_player(property_id, login_name)
      config = Hood::CONFIG
      @requester = Hood::LaxRequester.get_external_requester(property_id,config.property_keys[property_id],config.validate_token_uri)
      msg = {:login_name=>login_name}
      response = send_request(:post,'lock_player',msg)
      raise Hood::InternalError.new('call cms failed') unless response
      res = YAML.load(response).symbolize_keys
      case res[:error_code]
      when 'OK'
        return true
      end
      raise Hood::InternalError.new('call cms failed')
    end

  end
end
