module Hood
  module RWSHandler
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.rescue_from Exception, :with=>:handle_exceptions
    end

    module ClassMethods
      attr_reader :processor, :rws_parser, :backtrace_cleaner
      def config_handler(processor,verify=true)
        @processor = processor
        if verify
          @rws_parser = LaxSupport::AuthorizedRWS::Parser.new(Hood::CONFIG.property_keys,Hood::CONFIG.service_keys)
        end
      end

      def config_handler_backtrace_cleaner(backtrace_cleaner)
        @backtrace_cleaner = backtrace_cleaner
      end
    end

    module InstanceMethods
      private

      def now_utc_time
        now = Time.now.utc
        now.strftime("%Y-%m-%d %H:%M:%S.#{now.usec} UTC")
      end

      protected

      def handle_request(event_name,accept_format=nil)
        @inbound = params.symbolize_keys
        if self.class.rws_parser && event_name != :internal_deposit
          parser_result = self.class.rws_parser.verify(request.method, request.path, request.headers)
          @inbound[:property_id] = parser_result[0].to_i
        end
        @inbound[:_event_name] = event_name
        @inbound[:_created_at] = now_utc_time
        logger.info "  Inbound event: #{@inbound.inspect}\n"

        #process the request
        @outbound = self.class.processor.update(@inbound) || {}
        @outbound = @outbound.to_hash unless @outbound.kind_of?(Hash)

        logger.info "\n  Outbund event: #{@outbound.merge({:_created_at=>now_utc_time}).inspect}\n"
        respond_with_result(@outbound,accept_format)
      end

      def handle_exceptions(exception, status_code=500)
        result = { :status => status_code,
          :error_code => exception.class.name,
          :message => exception.message
        }
        log_exception(exception)
        respond_with_result(result)
      end
      
      def log_exception(exception)
        logger.fatal "  Exception\n  [#{exception.class}] #{exception.message}\n  " +
          get_clean_backtrace(exception.backtrace) +
          "\n"
      end

      def get_clean_backtrace(backtrace)
        if self.class.backtrace_cleaner
          self.class.backtrace_cleaner.clean(backtrace).join("\n  ")
        else
          backtrace.join("\n  ")
        end
      end

      def respond_with_result(result,accept_format=nil)
        request.accept = get_mime_type(accept_format) if accept_format
        respond_to do |format|
         format.html { render :status => result[:status], :text => result.to_json }
         format.json { render :status => result[:status], :text => result.to_json }
         format.yaml { render :status => result[:status], :text => result.to_yaml }
         format.xml  { render :status => result[:status], :text => result.to_xml }
         #format.amf  { render :amf => result }
        end
      end

      def get_mime_type(format)
        case format
        when :json
          "application/json"
        when :yaml
          "application/x-yaml"
        when :xml
          "application/x-xml"
        else
          "application/json"
        end
      end

    end

  end
end
