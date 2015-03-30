require 'rubygems'
require 'yaml'
require 'ostruct'

module LaxSupport

    class Configurator
      include Callbacks
  
      define_callbacks :after_configure

      def initialize(config, environment = nil)
        @config = OpenStruct.new
        if config.kind_of?(Hash)
          configure_from_hash(config) 
        elsif config.kind_of?(String)
          if File.file?(config)
            configure_from_file(config, environment)
          else 
            raise ArgumentError, "config file #{config.inspect} is NOT found."
          end
        else
          raise ArgumentError, "A hash/file is expected for initial config."
        end
      end

      # Forwards the method calls onto OpenStruct
      def method_missing(sym, *args)
        @config.send(sym, *args)
      end

      def config_file_changed?
        @config.config_file && (@config.last_mtime.nil? || File.stat(@config.config_file).mtime > @config.last_mtime)
      end

      def configure_from_file(config_file, environment=nil)
        config = YAML.load_file(config_file)
        config.recursively_symbolize_keys!
        config = config[environment.to_sym] unless environment.nil?

        config.each { |k, v| @config.send("#{k}=", v) }
        @config.environment = environment unless environment.nil?
        @config.config_file = config_file
        @config.last_mtime = File.stat(config_file).mtime
        run_tasks_after_configure
      end
  
      def reconfigure_from_file
        if config_file_changed?
          configure_from_file(@config.config_file, @config.environment)
          true
        else
          false
        end
      end

      def configure_from_hash(config_hash)
        config = config_hash.recursively_symbolize_keys
        config.each { |k, v| @config.send("#{k}=", v) }
        @config.last_mtime = Time.now
        run_tasks_after_configure
      end

      def reconfigure_from_hash(config_hash)
        configure_from_hash(config_hash)
        true
      end

      def to_hash
        @config.marshal_dump
      end

      def validate
      end
      
      def set_default_values
      end

      def [](key)
        @config.send("#{key}")
      end

      def []=(key, value)
        @config.send("#{key}=", value)
      end

      protected
    
      def set_default(key, default_value)
        @config.send("#{key}=", default_value) if @config.send("#{key}").nil?
      end

      private

      def run_tasks_after_configure
        set_default_values
        run_callbacks(:after_configure)
        validate
      end
    end

end
