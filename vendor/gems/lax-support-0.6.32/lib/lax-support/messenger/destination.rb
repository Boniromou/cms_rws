module LaxSupport
  module Messenger
    class Destination
      DEFAULT_PUBLISH_HEADERS = { :persistent => false }

      attr_accessor :name, :value, :publish_headers, :broker_name

      def initialize(name, value, publish_headers, broker_name)
        @name, @value, @publish_headers, @broker_name = name, value, publish_headers, broker_name
        #@publish_headers.reverse_merge!(DEFAULT_PUBLISH_HEADERS)
        @publish_headers = DEFAULT_PUBLISH_HEADERS.merge(@publish_headers)

      end

      def to_s
        "#{broker_name}: #{name.inspect} => #{value.inspect}"
      end
    end
  end
end
