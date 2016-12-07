# \Datadog global namespace that includes all tracing functionality for Tracer and Span classes.
module Datadog
  # A \Pin (a.k.a Patch INfo) is a small class which is used to
  # set tracing metadata on a particular traced object.
  # This is useful if you wanted to, say, trace two different
  # database clusters.
  class Tracer
    def self.get_from(obj)
      return nil unless obj.respond_to? :datadog_pin
      obj.datadog_pin
    end

    def initialize(service, params = {})
      @service = service
      @app = params[:app]
      @tags = params[:tags]
      @app_type = params[:app_type]
      @name = nil # this would rarely be overriden as it's really span-specific
      @tracer = params.fetch(:tracer, Datadog.tracer)

      attr_accessor :service
      attr_accessor :app
      attr_accessor :tags
      attr_accessor :app_type
      attr_accessor :name
      attr_accessor :tracer
    end

    def enabled
      return @tracer.enabled? if @tracer
      false
    end

    def onto(obj)
      unless obj.respond_to? :datadog_pin=
        obj.instance_exec do
          attr_writer :datadog_pin
        end
      end

      unless obj.respond_to? :datadog_pin
        obj.instance_exec do
          attr_reader :datadog_pin
        end
      end

      obj.datadog_pin = self
    end
  end
end
