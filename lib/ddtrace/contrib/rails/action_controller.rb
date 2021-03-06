require 'ddtrace/ext/http'
require 'ddtrace/ext/errors'

module Datadog
  module Contrib
    module Rails
      # TODO[manu]: write docs
      module ActionController
        def self.instrument
          # subscribe when the request processing starts
          ::ActiveSupport::Notifications.subscribe('start_processing.action_controller') do |*args|
            start_processing(*args)
          end

          # subscribe when the request processing has been completed
          ::ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
            process_action(*args)
          end
        end

        def self.start_processing(*)
          tracer = ::Rails.configuration.datadog_trace.fetch(:tracer)
          service = ::Rails.configuration.datadog_trace.fetch(:default_service)
          type = Datadog::Ext::HTTP::TYPE
          tracer.trace('rails.request', service: service, span_type: type)
        rescue StandardError => e
          Datadog::Tracer.log.error(e.message)
        end

        def self.process_action(_name, start, finish, _id, payload)
          tracer = ::Rails.configuration.datadog_trace.fetch(:tracer)
          span = tracer.active_span()
          span.resource = "#{payload.fetch(:controller)}##{payload.fetch(:action)}"
          span.set_tag(Datadog::Ext::HTTP::URL, payload.fetch(:path))
          span.set_tag(Datadog::Ext::HTTP::METHOD, payload.fetch(:method))
          span.set_tag('rails.route.action', payload.fetch(:action))
          span.set_tag('rails.route.controller', payload.fetch(:controller))

          if payload[:exception].nil?
            span.set_tag(Datadog::Ext::HTTP::STATUS_CODE, payload.fetch(:status).to_s)
          else
            error = payload[:exception]
            # TODO[manu]: it's right to have a 500? there are cases in Rails that let
            # user to recover the error after this point?
            span.status = 1
            span.set_tag(Datadog::Ext::Errors::TYPE, error[0])
            span.set_tag(Datadog::Ext::Errors::MSG, error[1])
            span.set_tag(Datadog::Ext::HTTP::STATUS_CODE, '500')
          end

          span.start_time = start
          span.finish_at(finish)
        rescue StandardError => e
          Datadog::Tracer.log.error(e.message)
        end
      end
    end
  end
end
