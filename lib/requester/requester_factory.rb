require File.expand_path(File.dirname(__FILE__) + "/base")

module Requester
  class RequesterFactory
    attr_reader :urls, :property_id, :secret_key
    def initialize(config_file,env, property_id, secret_key)
      request_urls = YAML.load_file(config_file)
      @urls = request_urls[env]
      @property_id = property_id
      @secret_key = secret_key
    end

    def get_wallet_requester
      get_requester('wallet')
    end

    def get_patron_requester
      get_requester('patron')
    end

    def get_wallet_requester
      get_requester('station')
    end

  protected
    def get_requester(type)
      request_class = eval("Requester::#{type.capitalize}")
      request_class.new(@property_id, @secret_key, @urls[type.to_sym])
    end
  end
end
