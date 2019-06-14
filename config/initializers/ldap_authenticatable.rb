require 'net/ldap'
require 'devise/strategies/authenticatable'
require 'user_management'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def valid?
        auth_token && user_cache
      end

      def authenticate!
        Rails.logger.info "authenticating through SSO..."
        result = user_cache
        Rails.logger.info "SSO responds: {#{result.inspect}}"        
          casino_id = User.get_casino_ids_by_uid(result[:system_user][:id]).first
          if Casino.find_by_id(casino_id).nil?
            clear_cookie_and_cache
            fail!('alert.inactive_account')
            return
          end
          user = User.find_by_uid(result[:system_user][:id])
          if !user
            user = User.create!(uid: result[:system_user][:id], name: result[:system_user][:username])
          end
          clear_cookie_and_cache
          success!(user)
          Object.send(:remove_const, :TIMEZONE) if defined? TIMEZONE
          Object.const_set('TIMEZONE', user.timezone)
      end

      # def user_data
      #   params[:user]
      # end

      def success!(system_user)
        Rails.logger.info "success login system_user: #{system_user.inspect}"
        super(system_user)
      end

      def auth_token
        cookies[:auth_token]
      end

      def user_cache
        Rails.cache.read(auth_token) if auth_token
      end

      def clear_cookie_and_cache
        Rails.logger.info "clear cookie"
        Rails.cache.delete(auth_token)
        cookies.delete(:auth_token, domain: :all)
      end



    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
