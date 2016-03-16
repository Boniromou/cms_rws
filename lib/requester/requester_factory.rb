require File.expand_path(File.dirname(__FILE__) + "/base")

module Requester
  class RequesterFactory
    attr_reader :urls, :casino_id, :secret_key
    def initialize(config_file,env, casino_id, licensee_id, secret_key)
      request_urls = YAML.load_file(config_file)
      @urls = request_urls[env]
      @casino_id = casino_id
      @licensee_id = licensee_id
      @secret_key = secret_key
    end

    def get_wallet_requester
      create_external_requester('wallet')
    end

    def get_patron_requester
      create_external_requester('patron')
    end

    def get_station_requester
      create_internal_requester('station')
    end

  protected
    def create_external_requester(type)
      requester_class = eval("Requester::#{type.capitalize}")
      requester_class.new(@casino_id, @licensee_id, @secret_key, @urls[type.to_sym])
    end

    def create_internal_requester(type)
      config = Hood::CONFIG
      requester_class = eval("Requester::#{type.capitalize}")
      requester_class.new(config.internal_property_id, config.service_key, @urls[type.to_sym], config.service_id)
    end
  end
end
