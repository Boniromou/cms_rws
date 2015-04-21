$:.unshift(File.expand_path(File.dirname(__FILE__))) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "yaml"
require "time"
require "lax-support"
require "sequel"
require "hood/version"
require "hood/util/loggable"
require "hood/util/utilities"
require "hood/util/lax_requester"
require "hood/util/rws_handler"
require "hood/errors"
require "hood/cashier"
require "hood/service"

Sequel.default_timezone = :utc
Sequel::Model.plugin :timestamps, :update_on_create=>true

module Hood
  #ROOT = File.expand_path(File.dirname(__FILE__))
  #autoload :Player, "#{ROOT}/hood/model/player"
  class << self
    def connect_db(conn_string, opts=nil)
      if opts
        Sequel.connect(conn_string,opts)
      else
        Sequel.connect(conn_string)
      end
      require "hood/model/currency"
      require "hood/model/property"
      require "hood/model/player"
      require "hood/model/wallet_transaction"
      require "hood/model/deposit_transaction"
      require "hood/model/withdraw_transaction"
      require "hood/model/round_transaction"
      require "hood/model/bet_transaction"
      require "hood/model/cancel_bet_transaction"
      require "hood/model/result_transaction"
    end
  end

  module CONFIG
    class << self
      #TODO raise error for attr_reader
      attr_accessor :service_id, :service_key, :internal_property_id ,:ams_uri, :service_keys, :property_keys

      def load_service_config(file,env)
        service_config = YAML.load_file(file)[env]
        self.internal_property_id = service_config[:internal_property_id]
        self.service_id = service_config[:service_id]
        self.service_key = service_config[:service_key]
        self.ams_uri = service_config[:ams_uri]
        self.service_keys = service_config[:service_keys]
      end
    end
  end

end
