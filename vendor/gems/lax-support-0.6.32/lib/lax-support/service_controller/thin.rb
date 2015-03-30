require 'socket'

module LaxSupport
  module ServiceController

    class Thin < Node
      include LaxSupport::Validation

      def initialize(opts)
        super
       
        @service_exec     = 'thin'
        @service_current  = opts[:service_current] || File.join(@service_root, 'current')
        @service_shared   = opts[:service_shared] || File.join(@service_root, 'shared')
        @service_config   = "#{@service_current}/config/#{@service_exec}.conf"
        @service_socket   = "#{@service_shared}/system/#{@service_exec}.#{@node_num}.sock"
        @service_pid_file = "#{@service_shared}/pids/#{@service_exec}.#{@node_num}.pid"
        @service_log_file = "#{@service_current}/log/#{@service_exec}.#{@node_num}.log"
      end

      protected
  
      def create_controller
        @controller = DaemonController.new(
          :identifier    => @service,
          :start_command => "#{@service_exec} start -C #{@service_config} -o #{@node_num}",
          :stop_command  => "#{@service_exec} stop -C #{@service_config} -o #{@node_num}",
          :ping_command  => lambda { UNIXSocket.new("#{@service_socket}") },
          :ping_interval => 1,
          :pid_file      => @service_pid_file,
          :log_file      => @service_log_file,
          #:before_start  => method(:before_start),
          :start_timeout => @start_timeout,
          :stop_timeout  => @stop_timeout,
          :log_file_activity_timeout => @log_file_activity_timeout
        )
      end
    end

  end
end

