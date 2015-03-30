module LaxSupport
  module Messenger 
    module Adapter
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def register(adapter_name)
          LaxSupport::Messenger::Base.register_adapter adapter_name, self
        end
      end
    end
  end
end

