require 'daemon_controller'
require File.join(File.dirname(__FILE__), 'errors')

module LaxSupport
  module ServiceController

    class Node
      include LaxSupport::Validation

      attr_reader :node_num, :service, :service_root,
                  :start_timeout, :stop_timeout, 
                  :log_file_activity_timeout

      validates do
        presence_of     :node_num
        presence_of     :service
        presence_of     :service_root 
        numericality_of :node_num, :only_integer => true
        numericality_of :start_timeout, :only_integer => true
        numericality_of :stop_timeout, :only_integer => true
        numericality_of :log_file_activity_timeout, :only_integer => true
      end


      attr_reader :service, :node_num
    
      def initialize(opts)
        @node_num        = opts[:node_num]
        @service         = opts[:service]
        @service_root    = opts[:service_root]
        @start_timeout   = opts[:start_timeout] || 30
        @stop_timeout    = opts[:stop_timeout] || 30
        @log_file_activity_timeout = opts[:log_file_activity_timeout] || 15

        raise InvalidOptions.new(errors) unless valid?
      end

      def controller
        create_controller if @controller.nil?
        @controller
      end

      def start
        controller.start
        status
      rescue DaemonController::AlreadyStarted
        puts "#{@service} has been already started."
      end
  
      def stop
        controller.stop
        status
      end

      def running?
        controller.running?
      end
    
      def pid
        controller.pid
      end
 
      def status
        if running?
          puts "#@service is running with pid #{pid}."
        else
          puts "#@service is stopped."
        end
      end 

      protected
  
      def create_controller
        raise NotImplementedError.new("#{self.class.name}#create_controller is an abstract method.")
      end
    end

  end
end

