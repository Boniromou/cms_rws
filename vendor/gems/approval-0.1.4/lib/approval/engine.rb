module Approval
  class Engine < ::Rails::Engine
    isolate_namespace Approval

		config.to_prepare do
      Dir.glob("#{File.dirname(__FILE__)}/utils/*.rb").each do |c|
        require_dependency(c)
      end
    end

    config.before_initialize do
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
    end

	  config.generators do |g|
	 	  g.test_framework :rspec, :fixture => false
	 	  g.fixture_replacement :factory_girl, :dir => 'spec/factories'
	 	  g.assets false
	 	  g.helper false
	  end
  end
end
