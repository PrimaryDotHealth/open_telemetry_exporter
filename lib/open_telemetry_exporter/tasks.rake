# frozen_string_literal: true

namespace :open_telemetry do
  desc "Test OpenTelemetry configuration and fallback"
  task test: :environment do
    puts "Testing OpenTelemetry configuration..."
    
    # Test configuration
    test_configuration
    
    # Test fallback functionality
    test_fallback
    
    # Test OpenTelemetry functionality
    test_opentelemetry
    
    puts "All tests completed!"
  end

  private

  def test_configuration
    puts "\n=== Configuration Test ==="
    
    # Store original configuration
    original_enabled = OpenTelemetryExporter.configuration.opentelemetry_enabled
    OpenTelemetryExporter.configuration.opentelemetry_enabled = false
    
    begin
      # Test basic configuration
      puts "OpenTelemetry enabled: #{OpenTelemetryExporter.configuration.opentelemetry_enabled?}"
      puts "Fallback configured: #{OpenTelemetryExporter.configuration.fallback_configured?}"
      
      # Test logger configuration
      logger = OpenTelemetryExporter.configuration.logger
      puts "Logger configured: #{logger.class}"
      
    ensure
      # Restore original configuration
      OpenTelemetryExporter.configuration.opentelemetry_enabled = original_enabled
    end
  end

  def test_fallback
    puts "\n=== Fallback Test ==="
    
    # Store original configuration
    original_fallback = OpenTelemetryExporter.configuration.fallback_object
    OpenTelemetryExporter.configuration.fallback_object = nil
    
    begin
      # Test without fallback (should raise error)
      begin
        OpenTelemetryExporter::Logger.increment("test.metric")
        puts "ERROR: Should have raised an error for missing fallback"
      rescue => e
        puts "✓ Correctly raised error for missing fallback: #{e.message}"
      end
      
      # Test with fallback
      OpenTelemetryExporter.configuration.fallback_object = nil
      
      # Test with mock fallback object
      mock_fallback = double("fallback")
      allow(mock_fallback).to receive(:increment).and_return(1)
      allow(mock_fallback).to receive(:timing).and_return(100)
      allow(mock_fallback).to receive(:histogram).and_return(50)
      
      OpenTelemetryExporter.configuration.fallback_object = mock_fallback
      
      result = OpenTelemetryExporter::Logger.increment("test.metric")
      puts "✓ Fallback increment returned: #{result}"
      
    ensure
      # Restore original configuration
      OpenTelemetryExporter.configuration.fallback_object = original_fallback
    end
  end

  def test_opentelemetry
    puts "\n=== OpenTelemetry Test ==="
    
    # Store original configuration
    original_enabled = OpenTelemetryExporter.configuration.opentelemetry_enabled
    original_meter = OpenTelemetryExporter.configuration.opentelemetry_meter
    
    begin
      # Test with OpenTelemetry enabled
      OpenTelemetryExporter.configuration.opentelemetry_enabled = true
      
      # Mock meter
      mock_meter = double("meter")
      mock_counter = double("counter")
      mock_histogram = double("histogram")
      
      allow(mock_meter).to receive(:create_counter).and_return(mock_counter)
      allow(mock_meter).to receive(:create_histogram).and_return(mock_histogram)
      allow(mock_counter).to receive(:add)
      allow(mock_histogram).to receive(:record)
      
      OpenTelemetryExporter.configuration.opentelemetry_meter = mock_meter
      
      # Test increment
      result = OpenTelemetryExporter::Logger.increment("test.metric")
      puts "✓ OpenTelemetry increment returned: #{result}"
      
      # Test timing
      result = OpenTelemetryExporter::Logger.timing("test.timing", 100.5)
      puts "✓ OpenTelemetry timing returned: #{result}"
      
      # Test histogram
      result = OpenTelemetryExporter::Logger.histogram("test.histogram", 42)
      puts "✓ OpenTelemetry histogram returned: #{result}"
      
    ensure
      # Restore original configuration
      OpenTelemetryExporter.configuration.opentelemetry_enabled = original_enabled
      OpenTelemetryExporter.configuration.opentelemetry_meter = original_meter
    end
  end
end 