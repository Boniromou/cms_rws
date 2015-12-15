module Rigi
  module PunditHelper
    module Policy
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def target_name
          @@target_name
        end

        def policy_target(target_name)
          @@target_name = target_name.to_s
        end

        #
        # i.e.
        #
        # map_policy :index?, :show?, :update?
        # map_policy :add?, :action_name => :create
        # map_policy :show_maintenance_link?, :delegate_policies => [:index?, :create?]
        #
        def map_policy(*args)
          options = args.extract_options!
          action_defs = args
          target = options[:target] || @@target_name

          action_defs.each do |action_def|
            if options.has_key? :delegate_policies
              define_method("#{action_def}") do 
                options[:delegate_policies].each do |policy_def|
                  return true if send(policy_def)
                end

                false
              end
            else
              action_name = options[:action_name] || action_def.to_s.chomp('?')

              define_method("#{action_def}") do
                send("permitted?", target, action_name)
              end
            end
          end
        end
      end

      def found_permission?(system_user_uid, target, actions)
        permissions = extract_permission(system_user_uid)

        permit_actions = 
          if permissions && permissions.has_key?(target.to_sym)
            permissions[target.to_sym]
          else
            []
          end

        #Rails.logger.debug 'found_permission???????????????'
        #Rails.logger.debug permit_actions
        #Rails.logger.debug target
        #Rails.logger.debug actions

        actions = format_array(actions)
        actions.map!{ |action| action.to_s }

        intersect = permit_actions & actions
        !intersect.empty?
      end

      def fetch_permission_from_cache(uid)
        Rails.cache.fetch "#{APP_NAME}:permissions:#{uid}"
      end

      def extract_permission(uid)
        raw = fetch_permission_from_cache(uid)
        # Rails.logger.warn "----- Permission cache not found ------" unless raw_permissions
        raw ? raw[:permissions][:permissions] : nil
      end

      def format_array(item)
        case item
        when nil
          []
        when Array
          item
        else
          [item]
        end
      end

      def get_user
        send(:user)
      end

      def get_record
        send(:record)
      end

      #
      # examples like: 
      #   authorize :dashboard, :index?
      #   policy(:dashboard).index?
      #
      def headless_policy?
        record = get_record
        record.blank? || record.is_a?(Symbol)
      end

      # overwrite this for customization
      def get_record_property_ids
        record = get_record
        #raise ArgumentError if record.blank? || record.is_a?(Symbol) || record.id == nil
        return [] if record.blank? || record.is_a?(Symbol) || record.id == nil

        if record.is_a? Property
          [record.id]
        else
          if record.respond_to?(:property_id)
            [record.property_id]
          elsif record.respond_to?(:property)
            [record.property.id]
          elsif record.respond_to?(:properties)
            ids = []
            record.properties.each {|prop| ids << prop.id}
            ids
          else
            []
          end
        end
      end

      def record_has_property_assoication?
        record = get_record

        klass = 
          if record.is_a?(Class) && record < ActiveRecord::Base
            record
          elsif record.is_a?(ActiveRecord::Base)
            record.class
          end

        Rails.logger.debug 'record_has_property_assoication?'
        Rails.logger.debug klass.inspect

        return false unless klass

        intersect = klass.column_names & %w(property_id property properties)
        !intersect.empty?
      end

      def same_scope?(target_property_ids=nil)
        #record = get_record
        user_property_ids = format_array(system_user.property_ids)
        target_property_ids = format_array(target_property_ids || get_record_property_ids)

        Rails.logger.debug "user's properties => #{user_property_ids}, target's properties => #{target_property_ids}"

        user_property_ids.each do |user_property_id|
          target_property_ids.each do |target_property_id|
            if user_property_id.to_s == target_property_id.to_s
              return true
            end
          end
        end

        false
      end

      
      #
      # admin user always return true
      # internal user bypass scope checking
      #
      # for link display only checking
      #   permitted?(:maintenance, :search, :headless => true)
      # or
      #   permitted?(:maintenance, [:list_scheduled, :list_on_going, :search], :headless => true)
      #   => true     # ONLY find if system_user has this permission
      #               # if array of action names is passed, find if system_user has any one of these
      #   => false    # otherwise
      #
      # for read, create request
      #   permitted?(:maintenance, :search, :property_id => 1003)
      #   => true     # if system_user has property_id 1003 or is internal
      #   => false    # otherwise
      #
      # for update request
      #   permitted?(:maintenance, :extend, record)
      # or 
      #   permitted?(:maintenance, :extend, record, :property_id => maint1.property_id)
      # or 
      #   permitted?(:maintenance, :extend, :property_id => record.property_id)
      #   => true     # if system_user share the same property as that of maintenance obj or is internal
      #   => false    # otherwise
      #
      # for internal use only function
      #   permitted(:game_release, :deprecate, game_rel1, :internal_only => true)
      #
      def permitted?(*args)
        system_user = get_user
        return true if system_user.is_admin?

        options = args.extract_options!
        target_name, action_names = args

        #record ||= get_record
        #target_name = self.class.target_name
        property_id = options[:property_id]
        headless_checking = options[:headless] || false
        role_has_permission = found_permission?(system_user.uid, target_name, action_names)

=begin
        if headless_policy?
          Rails.logger.debug "--Policy-- [#{target_name}] [#{action_name}] -> headless_policy"
          role_has_permission
        elsif record_has_property_assoication?
          Rails.logger.debug "--Policy-- [#{target_name}] [#{action_name}] -> target has_property_assoication = true"
          role_has_permission && same_scope?
        else
          Rails.logger.debug "--Policy-- [#{target_name}] [#{action_name}] -> target has_property_assoication = false"
          role_has_permission && system_user.is_internal?
        end
=end

=begin
        Rails.logger.debug "--Policy-- headless_checking => #{headless_checking}"
        Rails.logger.debug "--Policy-- system_user.is_internal? => #{system_user.is_internal?}"
        #Rails.logger.debug "--Policy-- record_has_property_assoication? => #{record_has_property_assoication?}"
        Rails.logger.debug "--Policy-- property_id => #{property_id}"
        Rails.logger.debug role_has_permission

        if headless_checking || system_user.is_internal? || record.is_a?(Symbol) || !record_has_property_assoication?
          role_has_permission
        else
          if property_id.present?
            role_has_permission && same_scope?(property_id)
          else
            role_has_permission && same_scope?(get_record_property_ids)
          end
        end
=end
        role_has_permission
      end
    end

    module Controller
      class SystemUserContext
        attr_reader :system_user, :request_property_id

        def initialize(system_user, request_property_id)
          @system_user = system_user
          @request_property_id = request_property_id
        end
      end

      #
      # convention:
      #   policy scope/target name as controller resource name
      #   policy action name as controller action/api name
      #
      # e.g.
      # 
      # MaintenancesController#index
      # => policy_target = "maintenance"
      # => action_name = "index"
      #
      # include the following line in MaintenancesController:
      #   before_filter :authorize_action, :only => [:index]
      #
      def authorize_action(record=nil, policy_def=nil)
        policy_def ||= "#{action_name}?".to_sym
        policy_target = 
          if record.nil?
            controller_name.singularize.to_sym
          elsif record.is_a?(Array)
            record.first
          else
            record
          end

        Rails.logger.info "------ authorize action ------> target = #{policy_target}, action = #{policy_def}"
        authorize policy_target, policy_def
      end
    end
  end
end
