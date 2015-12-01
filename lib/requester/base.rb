require 'lax-support'

module Requester
  class Base
    RETRY_TIMES = 3

    def initialize(property_id, secret_access_key, base_path)
      @property_id = property_id
      @secret_access_key = secret_access_key
      
      @lax_requester = LaxSupport::AuthorizedRWS::Base.new(property_id, secret_access_key)
      @lax_requester.timeout = 5
      @path = base_path
    end

    protected

    def remote_rws_call(method, path, params)
      begin
        puts "----remote call #{path}, #{params.inspect}-------"
        response = @lax_requester.send(method.to_sym, path, params)
        puts "--------#{self.class.name} method #{method}, got respnose------"
        puts response
        return response
      rescue Exception => e
        puts e
        puts e.backtrace.join("\n")
        puts "service call/third party call #{self.class.name} unavailable"
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
        puts "***************retry_times: #{RETRY_TIMES - retry_times}***************"
        return block.call
      rescue Remote::ReturnError => e
        return e.result
      rescue Remote::RaiseError => e
        raise e
      rescue Remote::RetryError => e
        if retry_times > 0
          return retry_call(retry_times - 1, &block)
        else
          return e.result
        end
      rescue Exception => e
        Rails.logger.error "#{e.message}"
        Rails.logger.error "#{e.backtrace.inspect}"
        if retry_times > 0
          return retry_call(retry_times - 1, &block)
        else
          return e.message
        end
      end
    end
  end
end
