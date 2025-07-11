# Getting Started with OpenTelemetryExporter

This guide shows how to integrate `OpenTelemetryExporter` into your application to replace your existing metrics system (like DOGSTATSD, or any other metrics library) with a more flexible and configurable solution.

## Overview

`OpenTelemetryExporter` provides a unified interface for metrics logging that can work with OpenTelemetry as the primary system and any other metrics system as a fallback. This allows you to:

- Use OpenTelemetry as your primary metrics system
- Fall back to existing systems (like Datadog StatsD) when OpenTelemetry is unavailable
- Gradually migrate from existing systems to OpenTelemetry
- Maintain backward compatibility during the transition

## Installation

Add the gem to your Gemfile:

```ruby
gem 'open_telemetry_exporter'
```

Run bundle install:

```bash
bundle install
```

## Basic Configuration

Create an initializer file (`config/initializers/open_telemetry_exporter.rb`):

```ruby
OpenTelemetryExporter.configure do |config|
  # Enable OpenTelemetry (defaults to false)
  config.opentelemetry_enabled = ENV.fetch("OPENTELEMETRY_ENABLED", "false") == "true"
  
  # Configure OpenTelemetry meter if enabled
  if config.opentelemetry_enabled?
    require "opentelemetry/sdk"
    require "opentelemetry/exporter/otlp"
    
    # Initialize OpenTelemetry SDK
    OpenTelemetry::SDK.configure
    
    # Get the meter provider and create a meter
    meter_provider = OpenTelemetry.meter_provider
    config.opentelemetry_meter = meter_provider.meter("your_app_name")
  end
  
  # Configure fallback object (e.g., Datadog StatsD)
  if defined?(Datadog::Statsd)
    config.fallback_object = Datadog::Statsd.new
  end
  
  # Use Rails logger for error messages
  config.logger = Rails.logger
end
```

## Migration Examples

### Before (using DOGSTATSD directly)

```ruby
# In your controllers, jobs, etc.
DOGSTATSD.increment("app.requests", tags: ["endpoint:users"])
DOGSTATSD.timing("app.response_time", 150.5, tags: ["endpoint:users"])
DOGSTATSD.histogram("app.request_size", 1024, tags: ["endpoint:users"])
```

### After (using OpenTelemetryExporter)

```ruby
# Same interface, but now with OpenTelemetry support and fallback
OpenTelemetryExporter::Logger.increment("app.requests", tags: ["endpoint:users"])
OpenTelemetryExporter::Logger.timing("app.response_time", 150.5, tags: ["endpoint:users"])
OpenTelemetryExporter::Logger.histogram("app.request_size", 1024, tags: ["endpoint:users"])
```

### Before (using custom metrics system)

```ruby
# Custom metrics class
class MyMetrics
  def increment(name, tags: {}, by: 1)
    # Custom implementation
  end
  
  def timing(name, value, tags: {})
    # Custom implementation
  end
  
  def histogram(name, value, tags: {})
    # Custom implementation
  end
end

# Usage
metrics = MyMetrics.new
metrics.increment("app.requests", tags: ["endpoint:users"])
```

### After (using OpenTelemetryExporter with custom fallback)

```ruby
OpenTelemetryExporter.configure do |config|
  config.opentelemetry_enabled = true
  config.opentelemetry_meter = your_meter
  
  # Use your custom metrics as fallback
  # Note: Only Datadog StatsD is currently supported as a fallback
  # For other systems, you may need to implement custom fallback logic
  config.fallback_object = MyMetrics.new
end

# Usage (same as before, but with OpenTelemetry support)
OpenTelemetryExporter::Logger.increment("app.requests", tags: ["endpoint:users"])
```

## Supported Fallback Systems

### Datadog StatsD (Built-in Support)
The gem now has built-in support for Datadog StatsD with automatic tag conversion and method mapping. No additional configuration is needed:

```ruby
config.fallback_object = Datadog::Statsd.new
```

### Custom Systems
Currently, only Datadog StatsD is supported as a fallback. For other systems, you may need to implement custom fallback logic.

## Gradual Migration Strategy

### Phase 1: Install and Configure
1. Install the gem
2. Configure with your existing metrics system as fallback
3. Update your code to use the new interface

### Phase 2: Enable OpenTelemetry
1. Set up OpenTelemetry infrastructure
2. Enable OpenTelemetry in your configuration
3. Monitor that both systems are working

### Phase 3: Remove Fallback
1. Once confident with OpenTelemetry
2. Remove fallback configuration
3. Use OpenTelemetry exclusively

## Testing

You can test your configuration using the provided rake task:

```bash
rails opentelemetry:test
```

This will test both OpenTelemetry and fallback functionality.

## Error Handling

The gem automatically handles errors and provides fallback mechanisms:

- If OpenTelemetry fails, it falls back to your configured metrics system
- If the fallback fails, it logs errors and continues gracefully
- Clear error messages help with debugging configuration issues

## Best Practices

1. **Start with fallback only**: Begin with OpenTelemetry disabled and your existing system as fallback
2. **Test thoroughly**: Use the provided test tasks to verify configuration
3. **Monitor both systems**: During migration, monitor both OpenTelemetry and fallback metrics
4. **Gradual rollout**: Enable OpenTelemetry in stages across your application
5. **Error monitoring**: Watch for errors in your application logs during the transition 