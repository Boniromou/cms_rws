$:.unshift File.expand_path(File.dirname(__FILE__))

require 'lax-support/version'
require 'lax-support/event/errors'
require 'lax-support/core_ext.rb'
require 'lax-support/sequel_ext.rb' if defined?(Sequel)

module LaxSupport
  autoload :Model,                   'lax-support/model'
  autoload :Callbacks,               'lax-support/callbacks'
  autoload :Configurator,            'lax-support/configurator'
  autoload :Rescuable,               'lax-support/rescuable'
  autoload :Daemonizable,            'lax-support/daemonizable'
  autoload :Validation,              'lax-support/validation'
  autoload :Stats,                   'lax-support/stats'
  autoload :PerfTrace,               'lax-support/perf_trace'
  autoload :RWSError,                'lax-support/rws_error'
  autoload :RWSErrorHandler,         'lax-support/rws_error'
  autoload :ActsAsMessagable,        'lax-support/acts_as_messagable'
  autoload :ActsAsNamespacedSession, 'lax-support/acts_as_namespaced_session'
  autoload :DomainDataMigration,     'lax-support/domain_data_migration' 
  autoload :NonblockingFileLock,     'lax-support/nonblocking_file_lock'
  
  module Event
    autoload :Store,          'lax-support/event/store'
    autoload :Base,           'lax-support/event/base'
    autoload :InboundEvent,   'lax-support/event/inbound_event'
    autoload :OutboundEvent,  'lax-support/event/outbound_event'
  end

  module Messenger
    autoload :Base,           'lax-support/messenger/base'
    autoload :Destination,    'lax-support/messenger/destination'
    autoload :Adapter,        'lax-support/messenger/adapter'
    module Adapters
      module Stomp
        autoload :Connection, 'lax-support/messenger/adapters/stomp'
      end
    end
  end

  module SimpleStore
    autoload :Base,           'lax-support/simple_store/base'
    autoload :Lock,           'lax-support/simple_store/lock'
    autoload :LockMixin,      'lax-support/simple_store/lock'
    autoload :Expiration,     'lax-support/simple_store/expiration'
    #autoload :Mock,          'lax-support/simple_store/mock'
    module Adapters
      autoload :Memcache,     'lax-support/simple_store/adapters/memcache'
      autoload :Memory,       'lax-support/simple_store/adapters/memory'
      module Rufus
        module Tokyo
          autoload :Cabinet,  'lax-support/simple_store/adapters/rufus/tokyo/cabinet'
          autoload :Tyrant,   'lax-support/simple_store/adapters/rufus/tokyo/tyrant'
        end
        module Edo
          autoload :Cabinet,  'lax-support/simple_store/adapters/rufus/edo/cabinet'
          autoload :Tyrant,   'lax-support/simple_store/adapters/rufus/edo/tyrant'
        end
      end
    end
  end

  module AuthorizedRWS
    autoload :Authentication, 'lax-support/authorized_rws/authentication'
    autoload :Base,           'lax-support/authorized_rws/base'
    autoload :LaxRWS,         'lax-support/authorized_rws/base'
    autoload :Parser,         'lax-support/authorized_rws/parser'
  end

  module ServiceController
    autoload :Cluster,       'lax-support/service_controller/cluster'
    autoload :Node,          'lax-support/service_controller/node'
    autoload :Thin,          'lax-support/service_controller/thin'
  end
end

module Sequel
  module Plugins
    autoload :Timestamped,    'lax-support/sequel_plugins/sequel_timestamped'
    autoload :LockVersioned,  'lax-support/sequel_plugins/sequel_lock_versioned'
  end
end
