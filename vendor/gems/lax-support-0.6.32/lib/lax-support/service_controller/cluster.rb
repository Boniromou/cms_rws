require File.join(File.dirname(__FILE__), 'errors')

module LaxSupport
  module ServiceController

    class Cluster
      include LaxSupport::Validation
      
      attr_reader :service, :num_of_nodes, :node_class
  
      validates do
        presence_of     :service
        presence_of     :num_of_nodes
        presence_of     :node_class
        numericality_of :num_of_nodes, :only_integer => true
        type_of         :node_class, :class => Class
      end
 
      # Create a new Cluster controller object.
      # === Mandatory Options
      # [:num_of_nodes]
      #
      # [:node_class]
      #
      # [:service]
      #
      def initialize(opts)
        @service      = opts[:service]
        @num_of_nodes = opts[:num_of_nodes]
        @node_class   = LaxSupport::ServiceController.const_get(opts[:node_class])

        raise InvalidOptions.new(errors) unless valid? 
  
        @nodes = (0..(@num_of_nodes - 1)).to_a 
  
        @node_controllers = []
        @nodes.each do |node_num|
          node_opts = opts.clone
          node_opts[:node_num] = node_num
          node_opts[:service]  = "#{@service} (#{node_num})"
  
          @node_controllers << @node_class.new(node_opts)
        end
      end   

      def execute(operation='status', node_num=nil)
        operation.downcase!
        raise UnknownOperation.new(operation) unless ['start', 'stop', 'status'].include?(operation)

        node_num = node_num.nil? ? -1 : node_num.to_i
        @node_controllers.each do |controller|
          if node_num < 0 or controller.node_num == node_num
            controller.send operation
          end
        end
      end
    end

  end
end

