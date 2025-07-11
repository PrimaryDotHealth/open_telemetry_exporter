# frozen_string_literal: true

# Test helper for OpenTelemetryExporter configuration
module OpenTelemetryExporterHelper
  def self.configure_for_tests
    # Reset configuration to ensure clean state
    OpenTelemetryExporter.reset_configuration!
    
    # Configure for testing
    OpenTelemetryExporter.configure do |config|
      config.opentelemetry_enabled = false
      config.fallback_object = nil
      config.logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end
  end

  def self.configure_with_fallback(fallback_object)
    OpenTelemetryExporter.configure do |config|
      config.opentelemetry_enabled = false
      config.fallback_object = fallback_object
    end
  end
end 