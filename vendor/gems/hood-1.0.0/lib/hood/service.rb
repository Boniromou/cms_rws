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
end
