# frozen_string_literal: true

module OpenTelemetryExporter
  class Configuration
    attr_accessor :opentelemetry_enabled, :opentelemetry_meter, :fallback_object, :logger

    def initialize
      @opentelemetry_enabled = ENV.fetch("OPENTELEMETRY_ENABLED", "false") == "true"
      @opentelemetry_meter = nil
      @fallback_object = nil
      @logger = nil
    end

    def opentelemetry_enabled?
      @opentelemetry_enabled
    end

    def fallback_configured?
      !@fallback_object.nil?
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
    end
  end
end 