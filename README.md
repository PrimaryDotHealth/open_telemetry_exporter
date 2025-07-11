# OpenTelemetryExporter

A flexible OpenTelemetry exporter gem that supports OpenTelemetry as the primary backend with configurable fallback options for other metrics systems like Datadog StatsD.

## Features

- **OpenTelemetry Integration**: Primary support for OpenTelemetry metrics
- **Fallback Support**: Configurable fallback to other metrics systems
- **Flexible Configuration**: Easy setup and configuration
- **Error Handling**: Robust error handling with fallback mechanisms

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'open_telemetry_exporter'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Basic Configuration

```ruby
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
```

### Using the Logger

```ruby
# Increment a counter
OpenTelemetryExporter::Logger.increment("app.requests", tags: ["endpoint:users", "status:200"])

# Record timing
OpenTelemetryExporter::Logger.timing("app.response_time", 150.5, tags: ["endpoint:users"])

# Record histogram
OpenTelemetryExporter::Logger.histogram("app.request_size", 1024, tags: ["endpoint:users"])
```

### Fallback Configuration

The gem now supports specific fallback implementations for different metrics systems:

#### Datadog StatsD (Built-in Support)

```ruby
OpenTelemetryExporter.configure do |config|
  config.opentelemetry_enabled = false
  
  # Configure Datadog StatsD as fallback (no additional configuration needed)
  config.fallback_object = Datadog::Statsd.new
end
```

#### Custom Fallback Objects

For other metrics systems, you can still use the generic fallback mechanism:

```ruby
OpenTelemetryExporter.configure do |config|
  config.opentelemetry_enabled = false
  
  # Configure custom metrics system as fallback
  # Note: Only Datadog StatsD is currently supported as a fallback
  # For other systems, you may need to implement custom fallback logic
  config.fallback_object = your_custom_metrics_object
end
```

### Error Handling

The gem automatically handles errors and falls back to the configured fallback system:

```ruby
OpenTelemetryExporter.configure do |config|
  config.opentelemetry_enabled = true
  config.opentelemetry_meter = your_meter
  
  # Fallback will be used if OpenTelemetry fails
  config.fallback_object = your_fallback
end
```

### Testing Configuration

The gem includes a rake task to test your OpenTelemetryExporter configuration:

```bash
# Test basic configuration and logging methods
rake open_telemetry:test
```

This task will:
- Test basic configuration setup
- Verify logging methods work correctly
- Test fallback configuration (if Datadog::Statsd is available)
- Provide detailed feedback on what's working and what might need attention

The task is useful for:
- Validating your configuration before deployment
- Troubleshooting setup issues
- Ensuring fallback mechanisms work as expected

### Test Helper

The gem provides a test helper for configuring OpenTelemetryExporter in your test environment:

```ruby
# In your spec_helper.rb or rails_helper.rb
require "open_telemetry_exporter/test_helper"

# Configure for tests (disables OpenTelemetry and clears fallback)
OpenTelemetryExporterHelper.configure_for_tests

# Or configure with a specific fallback object
OpenTelemetryExporterHelper.configure_with_fallback(your_test_metrics_object)
```

This helper ensures that:
- OpenTelemetry is disabled during tests
- Configuration is reset to a clean state
- You can optionally configure a test-specific fallback object

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `opentelemetry_enabled` | Boolean | `false` | Enable OpenTelemetry integration |
| `opentelemetry_meter` | Object | `nil` | OpenTelemetry meter instance |
| `fallback_object` | Object | `nil` | Fallback metrics object |
| `logger` | Object | `Rails.logger` or `Logger.new($stdout)` | Logger for error messages |

## Supported Fallback Systems

### Datadog StatsD
Built-in support with automatic tag conversion and method mapping.

### Custom Systems
Currently, only Datadog StatsD is supported as a fallback. For other systems, you may need to implement custom fallback logic.
