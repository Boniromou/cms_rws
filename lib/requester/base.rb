require File.expand_path(File.dirname(__FILE__) + "/response")
require 'lax-support'

module Requester
  class Base
    RETRY_TIMES = 3

#    def initialize(casino_id, licensee_id, secret_access_key, base_path)
#      @casino_id = casino_id
#      @licensee_id = licensee_id
#      @secret_access_key = secret_access_key
#      
#      @lax_requester = LaxSupport::AuthorizedRWS::Base.new(casino_id, secret_access_key)
#      @lax_requester.timeout = 5
#      @path = base_path
#    end
    def initialize(property_id, secret_access_key, base_path, servicd_id, casino_id, licensee_id)
      @casino_id = casino_id
      @licensee_id = licensee_id

      @lax_requester = LaxSupport::AuthorizedRWS::LaxRWS.new(property_id, servicd_id, secret_access_key)
      @lax_requester.timeout = 5
      @path = base_path
    end

    protected

    def remote_rws_call(method, path, params)
      begin
        output_log "----remote call #{path}, #{params.inspect}-------"
        response = @lax_requester.send(method.to_sym, path, params)
        output_log "--------#{self.class.name} method #{method}, got respnose------"
        output_log response
        return response
      rescue Exception => e
        output_log e
        output_log e.backtrace.join("\n")
        output_log "service call/third party call #{self.class.name} unavailable"
	      return
      end
    end

    def remote_response_checking(result, *arg)
      if result.body && result_hash = YAML.load(result.body).symbolize_keys
        arg.each do |tag|
          raise Remote::UnexpectedResponseFormat.new("#{self.class.name} expected result has tag #{tag}, but got #{result_hash}") unless result_hash[tag.to_sym]
        end
        return result_hash
      else
        raise Remote::UnexpectedResponseFormat.new("#{self.class.name} got invalid result: #{result}")
      end
      rescue Exception => e
        raise Remote::UnexpectedResponseFormat.new("#{self.class.name} got invalid result: #{result}")
    end
    
    def retry_call(retry_times, &block)
      begin
        output_log "***************retry_times: #{RETRY_TIMES - retry_times}***************"
        return block.call
      rescue Remote::ReturnError => e
        return e.result
      rescue Remote::RaiseError => e
        raise e
      rescue Remote::RetryError => e
        if retry_times > 0
          return retry_call(retry_times - 1, &block)
        else
          return Response.new({:error_code => "Fail: #{e.class}", :error_msg => e.result})
        end
      rescue Exception => e
        if retry_times > 0
          return retry_call(retry_times - 1, &block)
        else
          return Response.new({:error_code => "Fail: #{e.class}", :error_msg => e.message})
        end
      ensure
        if e
          output_log "======== raise error when retry ============"
          output_log "error message: #{e.message}"
          output_log "#{e.backtrace.inspect}"
          output_log "======== end ============"
          #puts e.message
          #puts e.backtrace.inspect
        end
      end
    end

    def output_log(*params)
      if Requester::Base.const_defined?('Rails')
        Rails.logger.error params
      else
        puts params
      end
    end
  end
end
