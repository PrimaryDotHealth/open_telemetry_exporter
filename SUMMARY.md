# OpenTelemetryExporter - Summary

A flexible OpenTelemetry exporter gem that provides a unified interface for metrics logging with OpenTelemetry as the primary backend and configurable fallback options.

## Key Features

- **OpenTelemetry Integration**: Primary support for OpenTelemetry metrics
- **Fallback Support**: Configurable fallback to other metrics systems (Datadog StatsD, etc.)
- **Flexible Configuration**: Easy setup and customization
- **Error Handling**: Robust error handling with fallback mechanisms
- **Tag Support**: Both array and hash tag formats
- **Specific Fallback Implementations**: Built-in support for Datadog StatsD with automatic tag conversion

## Architecture

The gem consists of three main components:

1. **Configuration**: Manages OpenTelemetry and fallback settings
2. **Logger**: Provides the unified interface for metrics logging
3. **Error Handling**: Graceful fallback when OpenTelemetry fails

## Configuration

```ruby
OpenTelemetryExporter.configure do |config|
  # Enable OpenTelemetry
  config.opentelemetry_enabled = true
  
  # Configure OpenTelemetry meter
  config.opentelemetry_meter = your_meter_instance
  
  # Configure fallback object
  config.fallback_object = your_fallback_instance
end
```

## Usage

```ruby
# Increment a counter
OpenTelemetryExporter::Logger.increment("app.requests", tags: ["endpoint:users"])
or
OpenTelemetryExporter::Logger.increment("app.requests", tags: { "endpoint" => "users" }

# Record timing
OpenTelemetryExporter::Logger.timing("app.response_time", 150.5, tags: ["endpoint:users"])

# Record histogram
OpenTelemetryExporter::Logger.histogram("app.request_size", 1024, tags: ["endpoint:users"])
```

## Supported Fallback Systems

### Datadog StatsD (Built-in Support)
The gem now has built-in support for Datadog StatsD with automatic tag conversion and method mapping. No additional configuration is needed:

```ruby
config.fallback_object = Datadog::Statsd.new
```

### Custom Systems
Currently, only Datadog StatsD is supported as a fallback. For other systems, you may need to implement custom fallback logic.

## Migration Strategy

### Phase 1: Install and Configure
- Install the gem
- Configure with existing metrics system as fallback
- Update code to use new interface

### Phase 2: Enable OpenTelemetry
- Set up OpenTelemetry infrastructure
- Enable OpenTelemetry in configuration
- Monitor both systems

### Phase 3: Remove Fallback
- Once confident with OpenTelemetry
- Remove fallback configuration
- Use OpenTelemetry exclusively

## Error Handling

The gem provides comprehensive error handling:

- **OpenTelemetry failures**: Automatically falls back to configured metrics system
- **Fallback failures**: Logs errors and continues gracefully
- **Configuration errors**: Clear error messages for missing configuration

## Testing

Use the provided rake task to test configuration:

```bash
rails opentelemetry:test
```

## Benefits

1. **Unified Interface**: Single interface for all metrics needs
2. **Flexible Fallbacks**: Use any metrics system as fallback
3. **Better Error Handling**: More descriptive error messages and logging
4. **Environment Agnostic**: Works in development, test, and production
5. **Easy Testing**: Simple to mock and test
6. **Future Proof**: Easy to switch metrics systems without changing application code
7. **Flexible Tags**: Accepts both array and hash formats for tags
8. **Specific Implementations**: Built-in support for popular metrics systems like Datadog

## Best Practices

1. **Start with fallback only**: Begin with OpenTelemetry disabled and your existing system as fallback
2. **Test thoroughly**: Use the provided test tasks to verify configuration
3. **Monitor both systems**: During migration, monitor both OpenTelemetry and fallback metrics
4. **Gradual rollout**: Enable OpenTelemetry in stages across your application
5. **Error monitoring**: Watch for errors in your application logs during the transition 