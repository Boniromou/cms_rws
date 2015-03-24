require 'net/ldap'
require 'devise/strategies/authenticatable'
require 'user_management'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def valid?
        username || password
      end

      def authenticate!
        result = UserManagement::authenticate(username, password)
        if result['success']
          system_user = SystemUser.find_by_uid(result['system_user']['id'])
          if !system_user
            system_user = SystemUser.create!(:uid => result['system_user']['id'], :username => result['system_user']['username'])
          end
          success!(system_user)
          return
        else
          fail!(result['message'])
          return
        end
      end

      def user_data
        params[:user]
      end

      def username
        if user_data
          return user_data[:username]
        end
        return nil
      end

      def password
        if user_data
          return user_data[:password]
        end
        return nil
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
#Devise.add_module :ldap_authenticatable, :strategy => true
