require 'ddtrace/ext/cache'

module Datadog
  module Contrib
    module Rails
      # TODO[manu]: write docs
      module ActiveSupport
        def self.instrument
          # subscribe when a cache read has been processed
          ::ActiveSupport::Notifications.subscribe('cache_read.active_support') do |*args|
            trace_cache('GET', *args)
          end

          # subscribe when a cache write has been processed
          ::ActiveSupport::Notifications.subscribe('cache_write.active_support') do |*args|
            trace_cache('SET', *args)
          end

          # subscribe when a cache delete has been processed
          ::ActiveSupport::Notifications.subscribe('cache_delete.active_support') do |*args|
            trace_cache('DELETE', *args)
          end
        end

        def self.trace_cache(resource, _name, start, finish, _id, payload)
          tracer = ::Rails.configuration.datadog_trace.fetch(:tracer)
          service = ::Rails.configuration.datadog_trace.fetch(:default_cache_service)
          type = Datadog::Ext::CACHE::TYPE

          span = tracer.trace('rails.cache', service: service, span_type: type, resource: resource)
          span.set_tag('rails.cache.backend', ::Rails.configuration.cache_store)
          span.set_tag('rails.cache.key', payload.fetch(:key))
          span.start_time = start
          span.finish_at(finish)
        rescue StandardError => e
          Datadog::Tracer.log.error(e.message)
        end

        private_class_method :trace_cache
      end
    end
  end
end
