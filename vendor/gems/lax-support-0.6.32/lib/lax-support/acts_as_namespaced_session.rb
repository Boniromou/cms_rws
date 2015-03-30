require 'cgi/session'

class CGI #:nodoc:
  class Session #:nodoc:
    # Add restore API to reload session data
    def restore
      @data = @dbman.restore
    end

    class MemCacheStore #:nodoc:
      # Expose session_key
      attr_accessor :session_key

      # Overload constructor to avoid session boostrap
      # because session bootstrap is done in action level
      # after ActsAsNamespacedSession is mixed in. 
      # The other logic is the same as the original constructor.
      def initialize(session, options = {})
        id = session.session_id
        unless check_id(id)
          raise ArgumentError, "session_id '%s' is invalid" % id
        end
        @cache = options['cache'] || MemCache.new('localhost')
        @expires = options['expires'] || 0
        @session_key = "session:#{id}"
        @session_data = {}
      end
    end
  end
end

module LaxSupport
  
  # ActsAsNamedspaceSession is used to handle dynamic namespace for 
  # Rails session. 
  #
  # By default, session key composed by Rails is the following:
  #
  #   session:053ab258918db3c0638437fad1e4c31c
  #
  # In some cases, it will be useful to have a further separation on session
  # based on a dynamic value from the incoming request. One problem we encountered
  # when we develop Flex/AIR application is that the online Flex application running
  # from IE shares session with AIR application running from desktop. We believe
  # this is caused by AIR sharing the same browser engine with IE on Windows, which
  # makes AIR internet function as an extension of IE functionality. So, from Windows
  # IE prospective, AIR application is just another IE browser and they would share 
  # same set of internet accessing properties, one of which is session cookie. 
  # 
  # To address such issue, we would like to prepend some dynamic value from incoming
  # request to distinguish sessions from Flex and AIR applications. session key will 
  # be composed in the following format:
  # 
  #   <namespace>:session:053ab258918db3c0638437fad1e4c31c
  #
  # The basic concept of +ActsAsNamespacedSession+ is to use prepend_before_filter to 
  # determine the namespace from the request parameters based on the specified 
  # namespace key. At the meanwhile, AMF/non-AMF requests are properly handled as well.
  #
  # To use +ActsAsNamespacedSession+, you need to mix-in this module to your application
  # controller and specify the corresponding session namespace key. Here is one example:
  #
  #    class ApplicationController < ActionController::Base
  #      include LaxSupport::ActsAsNamespacedSession
  #
  #      session_namespace_key 'property_id'
  #
  #      helper :all # include all helpers, all the time
  #      filter_parameter_logging :password
  #    end
  #
  # where +session_namespace_key is the function to specify namespace key. The value of 
  # the request parameter with given name identical to +session_namespace_key+ will be 
  # prepended to the orignial session key.
  # 
  # If what you need is to prepend a static namespace, you can simply specify it through
  # the session store (like MemCacheStore) which supports static namespace already.
  # +ActsAsNamespacedSession+ fits better in dynamic namespace handling. 
  module ActsAsNamespacedSession

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Setup prepend_before_filter
      base.prepend_before_filter :parse_namespace
    end

    module ClassMethods
      # Specify the session namespace key name
      def session_namespace_key(namespace_key)
        @namespace_key = namespace_key
      end

      # Retrieve namespace key
      def namespace_key
        @namespace_key || self.superclass.instance_variable_get('@namespace_key')
      end
    end

    module InstanceMethods
      protected 

      # Before filter method to parse incoming request to retrieve the specified namespace
      # and prepend it to the session key and boostrap session data as well. If AuthorizedRWS
      # request is received, namespace key will be safely ignored because session is not used 
      # in AuthorizedRWS request.
      def parse_namespace
        namespace_key = self.class.namespace_key
        namespace_key_with_colon = ":#{namespace_key}"
        request_params = request.parameters
        namespace = nil
        if request.headers['Authorization'].nil?  # Non-AuthorizedRWS request
          namespace = if request_params[0].nil?           # non-AMF request
                        request_params[namespace_key] || request_params[namespace_key_with_colon]
                      elsif request_params[0]['msg'].nil? # AMF request without embeded msg
                        request_params[0][namespace_key] || request_params[0][namespace_key_with_colon]
                      else                                # AMF request with embeded msg
                        request_params[0]['msg'][namespace_key] || request_params[0]['msg'][namespace_key_with_colon]
                      end
          if namespace.nil?
            raise ArgumentError, "namespace key '%s' is nil" % namespace_key
          end
        end
        unless namespace.nil? # Only need to change session key when namespace is defined
          session.dbman.session_key = "#{namespace}:#{session.dbman.session_key}" unless session.dbman.session_key.split(':').include?(namespace.to_s)
          session.restore  # need to bootstrap the session content again since session key is changed.
        end
        namespace
      end
    end

  end
end
