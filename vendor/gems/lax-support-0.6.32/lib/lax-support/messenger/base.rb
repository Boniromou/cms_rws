require 'timeout'
if RUBY_VERSION =~ /1.8/
  require 'system_timer'
else
  require 'timeout'
end

module LaxSupport
  module Messenger
    # Default publish retries if any failures are encountered
    DEFAULT_PUBLISH_RETRY = 3

    class MessengerError < StandardError
    end

    class DuplicateDestination < MessengerError
      def initialize(dest_name)
        super("Duplicate destination name #{dest_name.inspect} is detected.")
      end
    end

    class NilDestination < MessengerError
      def initialize
        super('Destination name cannot be nil.')
      end
    end
    
    class EmptyMessage < MessengerError
      def initialize
        super('Message is NOT supposed to be empty.')
      end 
    end

    class DestinationNotFound < MessengerError
      def initialize(dest_name)
        super("Destination #{dest_name.inspect} is not found.")
      end
    end

    class MessageFailedToPublish < MessengerError
      def initialize(dest_name, message, exception)
        super("Failed to publish message #{message.inspect} to destination #{dest_name.inspect}: #{exception.message}")
      end
    end

    class Base
      attr_reader :destinations
      attr_accessor :configuration, :env, 
                    :root_path, :config_path, :config_file, 
                    :raise_on_publish_failure, :configure_by_file

      class << self
        attr_reader :adapters

        def register_adapter(adapter_name, adapter_class)
          (@adapters ||= {})[adapter_name] = adapter_class
        end
      end 
      
      def initialize 
        @configuration = {}
        @destinations = {}
        @connections = {}
        @raise_on_publish_failure = false
        @configure_by_file = true
   
        yield self if block_given?

        if @configure_by_file
          @config_file ||= 'broker.yml'
          @config_path ||= 'config'
          cfile = File.join(@root_path, @config_path, @config_file)
          if File.file?(cfile)
            if @env.nil?
              self.configuration = YAML::load_file(cfile)
            else
              self.configuration = YAML::load_file(cfile)[@env]
            end
          else
            raise ArgumentError, "config file #{cfile.inspect} is NOT found."
          end
        end
      end

      def configuration=(config={})
        disconnect_all 
        @destinations = {} 
   
        # Symbolize the config hash 
        @configuration = config.recursively_symbolize_keys
	configuration_nodes = {}
        @configuration.each { |k, v|
	  
          if v.has_key?(:destinations)
            v[:destinations].each { |d|
              d.recursively_symbolize_keys!
              destination(d[:name], d[:destination],
                          d[:publish_headers] || {}, k)
            }
          elsif v.has_key?(:nodes)
	    v[:nodes].each_with_index do |n,i|
		nodes_key = "#{k.to_s}_node#{i+1}".to_sym
		value = v.dup
		value[:host] = n
		value.delete(:nodes)
   		configuration_nodes[nodes_key] = value
            end
          end
        }	
	@configuration.merge!(configuration_nodes)
      end

      
			def destination_dup?(name)
				if @destinations.has_key?(name) 
					if !@destinations[name].is_a?(Array) && @destinations[name].broker_name == name
						return true
					elsif @destinations[name].is_a?(Array)
						@destinations[name].each do |n|
							return true if n.broker_name == name
						end
					end
				end
      	false
      end

			def destination(name, dest, publish_headers={}, broker=:default, node=false)
         unless node && @configuration[broker].has_key?(:nodes)
           _destination(name, dest, publish_headers={}, broker)
         else
           @configuration[broker][:nodes].each_with_index do |n,i|
             nodes_key = "#{broker.to_s}_node#{i+1}".to_sym
             _destination(name, dest, publish_headers={}, nodes_key)
         end
        end
			end
      alias queue destination
      alias topic destination

      def _destination(name, dest, publish_headers={}, broker=:default)
        raise DuplicateDestination.new(name) if destination_dup?(broker)
				if @destinations.has_key?(name)
	  			unless @destinations[name].is_a?(Array)
          	@destinations[name] = [@destinations[name]]
	  			end
	  			@destinations[name] << Destination.new(name, dest, publish_headers, broker)
				else
          @destinations[name] = Destination.new(name, dest, publish_headers, broker)
				end
      end

      def find_destination(name)
        @destinations[name]
      end
      alias find_queue find_destination
      alias find_topic find_destination

      def has_destination?(name)
        @destinations.has_key?(name)
      end
      alias has_queue? has_destination?
      alias has_topic? has_destination?

      def publish(destination_name, message, headers={}, timeout=2, retries=DEFAULT_PUBLISH_RETRY)
        retries.times do |count|
          @succeeded = true
          @exception = nil

          begin
            raise NilDestination if destination_name.nil?
            raise EmptyMessage if message.nil? || message.empty?
  
            dest = find_destination(destination_name)
            raise DestinationNotFound.new(destination_name) if dest.nil?
              
	          unless dest.is_a?(Array) 
              if RUBY_VERSION =~ /1.8/
                SystemTimer.timeout(timeout) { 
                  connection(dest.broker_name).send(dest.value,
                                                    message,
                                                    #headers.reverse_merge(dest.publish_headers))
                                                    dest.publish_headers.merge(headers))
                }
              else 
                Timeout::timeout(timeout) do 
                  connection(dest.broker_name).send(dest.value,
                                                    message,
                                                    dest.publish_headers.merge(headers))
                                                    #headers.reverse_merge(dest.publish_headers))
                                                    
                end
              end
            else
              dest.each do |d|
                if RUBY_VERSION =~ /1.8/
                  SystemTimer.timeout(timeout) {
	  	                        connection(d.broker_name).send(d.value,
		  				                message,
                                                                d.publish_headers.merge(headers))
			  			                #headers.reverse_merge(d.publish_headers))
                  }
                else
                  Timeout::timeout(timeout) do 
                    connection(dest.broker_name).send(dest.value,
                                                      message,
                                                      dest.publish_headers.merge(headers))
                                                      #headers.reverse_merge(dest.publish_headers))
                  end
                end
              end
            end
            
            return @succeeded
          rescue Exception => @exception
            if [EmptyMessage, NilDestination, DestinationNotFound].include?(@exception.class)
              break
            else
              unless dest.is_a?(Array)
                disconnect(dest.broker_name)
              else
                dest.each do |d|
                  disconnect(d.broker_name)
                end
              end
            end
            
            @succeeded = false
          end
   
          sleep(0.1)
        end

        if @raise_on_publish_failure
          raise MessageFailedToPublish.new(destination_name, message, @exception)
        else
          false
        end
      end     

      def disconnect(broker_name = :default)
        @connections[broker_name].disconnect unless @connections[broker_name].nil?
      end

      def disconnect_all
        @connections.each { |k, c| c.disconnect }
        @connections = {}
      end

      def subscribe(destination_name, broker_name = :default)
        connection(broker_name).subscribe(destination_name)
      end

      def unsubscribe(destination_name, broker_name = :default)
        connection(broker_name).unsubscribe(destination_name)
      end

      protected

      def connection(broker_name = :default)
        if @connections[broker_name].nil? or @connections[broker_name].closed?
          config = configuration[broker_name]
          require File.join(File.dirname(__FILE__), 'adapters', config[:adapter])
          @connections[broker_name] = self.class.adapters[config[:adapter].to_sym].new(config) 
        end

        @connections[broker_name]
      end
    end
  end
end
