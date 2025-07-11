# frozen_string_literal: true

require "open_telemetry_exporter/version"
require "open_telemetry_exporter/configuration"
require "open_telemetry_exporter/logger"

module OpenTelemetryExporter
  class Error < StandardError; end

  # Default configuration
  @configuration = Configuration.new

  class << self
    attr_accessor :configuration

    def configure
      yield(configuration) if block_given?
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end 