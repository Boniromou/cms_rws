module LaxSupport

  # ActsAsMessagable is a mixin module that handles Lax messages in general for Rails RWS applications  
  #
  # ActsAsMessagable provides callbacks that hook into the lifecycle of an ActionController object that 
  # allows you to trigger logic before or after an alteration of the object state.
  #
  # There are totol 10 callbacks. The order of callback execution is shown below:
  # 
  #   * validate(inbound_message)
  #   * before_process
  #     * before_each_process
  #     - process
  #     * after_each_process
  #     * before_publish
  #       * before_each_publish(outbound_event)
  #       * to_destination(recipient, outbound_event)
  #       - publish
  #       * after_each_publish(outbound_event)
  #     * after_publish
  #   * after_process
  #
  # Callback, to_destination, is used to compose event destination (topic/queue) for a given recipient.
  # It expects a destination and the associate broker are returned as the result. 
  # If this callback is not provided, no outbound events will be delivered.
  #
  # By default, acts_as_messagable define method #create to handle incoming messages:
  #
  #     def create
  #       @result = { :status => 200, :text => 'OK' }
  #       process_message
  #       respond_with_result(@result)
  #     end
  #
  # where #process_message and #respond_with_result are built-in methods to process incoming messages
  # and hanle result. You can overload this method to create custom behavior for your own controller.
  # However, this is usually not necessary.
  #
  # Also, it uses RWSErrorHandler to set up RWS exception handling for you automatically. 
  #
  # Here is a simple example. :encoding_format is used to specify data format for outbound message. 
  # Two options currently: :amf (default) or :yaml. Please ensure gem lax-amf is also installed properly.
  # 
  #     require 'lax-support'
  # 
  #     class MessagesController < ApplicationController
  #       include LaxSupport::ActsAsMessagable
  #
  #       acts_as_messagable my_processor, my_publisher, 
  #                          :validate            => :validate_message,
  #                          :before_each_publish => :update_game_session,
  #                          :to_destination      => :compose_destination,
  #                          :encoding_format     => :yaml 
  #
  #       protected
  #
  #       def validate_message(inbound_message)
  #         puts "validate message: #{inbound_message.inspect}"
  #       end
  #
  #       def update_game_session(outbound_event)
  #         puts "update game session with #{outbound_event.inspect}"
  #       end
  #
  #       def compose_destination(recipient, outbound_event)
  #         case recipient
  #         when :game_players
  #           destination = '/topic/game_players'
  #         when :bots
  #           destination = '/queue/bots'
  #         end
  #         destination
  #       end
  #
  #     end
  #
  module ActsAsMessagable

    class MissingInboundMessage < LaxSupport::RWSError
      def initialize
        super(400, 'Inbound message is NOT provided.')
      end
    end

    class InvalidInboundMessage < LaxSupport::RWSError
      def initialize
        super(400, 'Inbound message is invalid.')
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, LaxSupport::RWSErrorHandler)

      # Setup rescue handlers
      base.rescue_from LaxSupport::Event::EventError, :with => :handle_bad_events

      # Make method create exempt from forgery protection in Rails
      base.protect_from_forgery :except => [:create]
    end

    class Config
      attr_reader :processor
      attr_reader :publisher
      attr_reader :validate
      attr_reader :before_process,       :after_process
      attr_reader :before_each_process,  :after_each_process
      attr_reader :before_publish,       :after_publish
      attr_reader :before_each_publish,  :after_each_publish
      attr_reader :to_destination
      attr_reader :encoding_format
      attr_reader :encoding_method

      class MissingProcessor < LaxSupport::RWSError
        def initialize
          super(500, 'Processor is NOT provided.')
        end
      end

      class MissingPublisher < LaxSupport::RWSError
        def initialize
          super(500, 'Publisher is NOT provided.')
        end
      end

      class RequiredMethodNotDefined < LaxSupport::RWSError
        def initialize(method)
          super(500, "Required instance method ##{method.to_s} is NOT defined.")
        end
      end

      def initialize(processor, publisher, opts = {})
        raise MissingProcessor if processor.nil?
        raise MissingPublisher if publisher.nil?

        @processor           = processor
        @publisher           = publisher
        @validate            = opts[:validate]
        @before_process      = opts[:before_process]
        @after_process       = opts[:after_process]
        @before_each_process = opts[:before_each_process]
        @after_each_process  = opts[:after_each_process]
        @@before_publish     = opts[:before_publish]
        @after_publish       = opts[:after_publish]
        @before_each_publish = opts[:before_each_publish]
        @after_each_publish  = opts[:after_each_publish]
        @to_destination      = opts[:to_destination] || Proc.new { nil }
        @encoding_format     = opts[:encoding_format] || :amf
        @encoding_method     = "to_#{@encoding_format}".to_sym
      end
    end
  
    module ClassMethods
      # class method to set up acts_as_messagable mixin. here are the required/optional parameters:
      #   processor: the message processing callback (process inbound message events)
      #   publisher: the message publisher callback (deliver outbound message events to message broker)
      #   opts: optional callbacks and settings
      #     :validate => callback to validate inbound message
      #     :before_process      => callback to do preprocessing before any further processing
      #     :after_process       => callback to do postprocessing after any further processing
      #     :before_each_process => callback to do preprocessing before each inbound message
      #     :after_each_process  => callback to do postprocessing after each inbound message
      #     :before_publish      => callback to do preprocessing before any outbound message deliveries
      #     :after_publish       => callback to do postprocessing after any outbound message deliveries
      #     :before_each_publish => callback to do preprocessing before each outbound message delivery
      #     :after_each_publish  => callback to do postprocessing after each outbound message delivery
      #     :to_destination      => compose message event destination (topic/queue) fora given recipient. No outbound message will be delivered if this callback is not provided.
      #     :encoding_format     => data format for outbound message. Two options currently: :amf (default) or :yaml. 
      #                             Please ensure gem lax-amf is also installed properly.  
      def acts_as_messagable(processor, publisher, opts={})
        @acts_as_messagable_config = Config.new(processor, publisher, opts)

        rubyamf_option = self.method_defined?(:is_amf) ? 'with' : 'without'
        self.class_eval("alias extract_inbound_message extract_inbound_message_#{rubyamf_option}_rubyamf")
        self.class_eval("alias check_message_signature? check_message_signature_#{rubyamf_option}_rubyamf?")
      end

      # Make the @acts_as_messagable_config class instance variable easily 
      # accessible from the instance methods.
      def acts_as_messagable_config
        @acts_as_messagable_config || self.superclass.instance_variable_get('@acts_as_messagable_config')
      end
    end 

    module InstanceMethods
      def create
        @result = { :status => 200, :text => 'OK' }
        process_message
        respond_with_result(@result)
      end
 
      protected

      def process_message
				code = (1..10).collect{(65+rand(2)*32+rand(25)).chr}.to_s
        parse_time = Benchmark.realtime do
          @inbound_event = parse_params
        end
        logger.info "  [#{code}] Inbound event: #{@inbound_event.to_hash.inspect}\n"

        run_callback(:before_process)
        process_time = publish_time = 0
        # Loop until no more loopback event or exception raised
        loop do
          # Process inbound event
          process_time += Benchmark.realtime do
            run_callback(:before_each_process)
            @outbound_events, @loopback_event = process_inbound_event
            run_callback(:after_each_process)
          end

          # No need to proceed if exception occurs
          break if @result[:status] != 200

          # Publish outbound event
          publish_time += Benchmark.realtime do
            run_callback(:before_publish)
            @outbound_events.each do |outbound_event|
              run_callback(:before_each_publish, outbound_event)
              publish_outbound_event(outbound_event)
              run_callback(:after_each_publish, outbound_event)
    
              logger.info "  [#{code}] Outbound event: #{outbound_event.to_hash.inspect}\n"
            end
            run_callback(:after_publish)

            # Disconnect from the broker
            self.class.acts_as_messagable_config.publisher.disconnect_all
          end

          if @loopback_event.nil?
            break  # Break loop if no more loopback event
          else
            @inbound_event = @loopback_event
            logger.info "  [#{code}] Loopback event: #{@loopback_event.to_hash.inspect}\n"
          end
        end
        run_callback(:after_process)

        # Attach the original request to the server response
        @result[:request] = @inbound_message.to_yaml

        logger.info "[#{code}] Event Name: #{@inbound_event[:_event_name]} Benchmark: parse_time: %.4f, process_time: %.4f, publish_time: %.4f\n" % [parse_time, process_time, publish_time]
        logger.info "[#{code}] Response status: #{@result[:status]}"
				if @result[:status].to_i == 200
		      logger.debug "[#{code}] Response body: #{@result[:text].inspect}\n"
				else
					logger.info "[#{code}] Response body: #{@result[:text].inspect}\n"
				end
      end

      def extract_inbound_message_with_rubyamf
        inbound_message = {}
        if is_amf
          unless params[0][:msg].nil?
            request_params = params[0][:msg].kind_of?(String) ?
                             # Treat String message as YAML format
                             YAML.load(params[0][:msg]) :
                             # Else, simply return whatever stored in params[:msg]
                             params[0][:msg]
            
            # Make sure duplicate ':' is removed
            request_params.each do |key, value|
              inbound_message[key.gsub(/^:/, '')] = value
            end
          end
        else
          inbound_message = extract_inbound_message_without_rubyamf
        end
        inbound_message
      end

      def extract_inbound_message_without_rubyamf
        if params[:msg].kind_of?(String)
          # Treat String message as YAML format
          YAML.load(params[:msg]) 
        else
          # Else, simply return whatever stored in params[:msg]
          params[:msg]
        end
      end

      def check_message_signature_with_rubyamf?
        !is_amf
      end

      def check_message_signature_without_rubyamf?
        true  # Always check signature if rubyamf is not used
      end

      def run_callback(callback_name, *args)
        callback = self.class.acts_as_messagable_config.send(callback_name)
        case callback
        when Symbol, String
          __send__(callback, *args)
        when Proc
          callback.call(self, *args)
        else
          true
        end
      end

      def parse_params
        @inbound_message = extract_inbound_message
        raise MissingInboundMessage if @inbound_message.blank?
        @inbound_message = @inbound_message.symbolize_keys

        inbound_event = LaxSupport::Event::InboundEvent.new(@inbound_message, {:check_signature => check_message_signature?})
        
        # Add internal params
        inbound_event[:_host] ||= request.remote_ip
        inbound_event[:_host_ip] = request.remote_ip

        raise InvalidInboundMessage unless run_callback(:validate, inbound_event)
  
        inbound_event
      end

      def process_inbound_event
        if self.class.method_defined?("process_#{@inbound_event[:_event_name]}_event")
          @process_result = __send__("process_#{@inbound_event[:_event_name]}_event", @inbound_event)
        else
          @process_result = self.class.acts_as_messagable_config.processor.update(@inbound_event)
        end

        @result[:status] = @process_result[:status]
        @result[:text]   = @process_result[:status] == 200 ?
                           (@process_result[:message] || 'Request is successfully carried out.') :
                           @process_result[:error]
        [ @process_result[:outbound_events], @process_result[:loopback_event] ]
      end

      def publish_outbound_event(outbound_event)
        recipients = outbound_event.delete(:recipients)
        return if recipients.nil?

        publisher = self.class.acts_as_messagable_config.publisher
        encoding_method = self.class.acts_as_messagable_config.encoding_method
        encoding_format = self.class.acts_as_messagable_config.encoding_format

        recipients.each do |recipient|
          destination, broker  = run_callback(:to_destination, recipient, outbound_event)

          next unless destination

          unless publisher.has_destination?(destination)
            publisher.destination(destination, destination, {}, broker)
          end

          publisher.publish(destination, outbound_event.send(encoding_method), { :encoding_format => encoding_format }) 
        end

        logger.debug "  Outbound event has been published to: #{recipients.join(', ')}.\n"
      end

      # Exception handler for bad events (LaxSupport::Event::EventError)
      def handle_bad_events(exception)
        handle_exceptions(exception, 400)
      end
    end

  end
end
