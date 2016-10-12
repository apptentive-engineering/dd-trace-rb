# Datadog initialization for frameworks
#
# When installed as a gem you can auto instrument the code with:
#
# Rails -> add the following to your initialization sequence:
# ```
#   config.gem 'ddtrace'
# ```

if defined?(Rails::VERSION)
  if Rails::VERSION::MAJOR.to_i >= 3
    require 'ddtrace/contrib/rails/framework'

    module Datadog
      # TODO[manu]: write docs
      class Railtie < Rails::Railtie
        initializer 'ddtrace.instrument' do |app|
          Datadog::Contrib::Rails::Framework.init_plugin(config: app.config)
        end
      end
    end
  else
    logger = Logger.new(STDOUT)
    logger.warn 'Detected a Rails version < 3.x.'\
        'This version is not supported and the'\
        'auto-instrumentation for core components will be disabled.'
  end
end