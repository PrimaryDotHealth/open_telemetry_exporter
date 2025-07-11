# Example usage of OpenTelemetryExporter in your current application

# 1. Basic Configuration (in config/initializers/open_telemetry_exporter.rb)
OpenTelemetryExporter.configure do |config|
  # Enable OpenTelemetry if environment variable is set
  config.opentelemetry_enabled = ENV.fetch("OPENTELEMETRY_ENABLED", "false") == "true"
  
  # Configure OpenTelemetry meter if enabled
  if config.opentelemetry_enabled?
    require "opentelemetry/sdk"
    require "opentelemetry/exporter/otlp"
    
    # Initialize OpenTelemetry SDK
    OpenTelemetry::SDK.configure
    
    # Get the meter provider and create a meter
    meter_provider = OpenTelemetry.meter_provider
    config.opentelemetry_meter = meter_provider.meter("primary_health")
  end
  
  # Configure fallback object (e.g., Datadog StatsD)
  if defined?(Datadog::Statsd)
    config.fallback_object = Datadog::Statsd.new
  end
  
  # Use Rails logger for error messages
  config.logger = Rails.logger
end

# 2. Usage in Controllers
class UsersController < ApplicationController
  def create
    start_time = Time.current
    
    user = User.create!(user_params)
    
    # Record timing and success
    OpenTelemetryExporter::Logger.timing("user.creation_time", (Time.current - start_time) * 1000, tags: { success: true })
    OpenTelemetryExporter::Logger.increment("user.created", tags: { source: "api" })
    
    render json: user
  rescue => e
    # Record error
    OpenTelemetryExporter::Logger.increment("user.creation_error", tags: ["error_type:#{e.class.name}"])
    raise
  end
end

# 3. Usage in Background Jobs
class ProcessUploadJob < ApplicationJob
  def perform(file_id)
    start_time = Time.current
    
    file = File.find(file_id)
    
    # Process the file...
    process_file(file)
    
    # Record metrics
    OpenTelemetryExporter::Logger.timing("job.process_upload_time", (Time.current - start_time) * 1000, tags: { file_type: file.type })
    OpenTelemetryExporter::Logger.increment("job.process_upload_success", tags: { file_size: file.size })
  rescue => e
    OpenTelemetryExporter::Logger.increment("job.process_upload_error", tags: { error: e.class.name })
    raise
  end
end

# 4. Custom Fallback Configuration
OpenTelemetryExporter.configure do |config|
  config.opentelemetry_enabled = false
  
  # Use a custom metrics system as fallback
  # Note: Only Datadog StatsD is currently supported as a fallback
  # For other systems, you may need to implement custom fallback logic
  config.fallback_object = MyCustomMetrics.new
end

# 5. Environment-Based Configuration
case Rails.env
when 'production'
  OpenTelemetryExporter.configure do |config|
    config.opentelemetry_enabled = true
    config.opentelemetry_meter = production_meter
    config.fallback_object = Datadog::Statsd.new
  end
when 'development'
  OpenTelemetryExporter.configure do |config|
    config.opentelemetry_enabled = false
    config.fallback_object = MockMetrics.new
  end
when 'test'
  OpenTelemetryExporter.configure do |config|
    config.opentelemetry_enabled = false
    config.fallback_object = TestMetrics.new
  end
end 