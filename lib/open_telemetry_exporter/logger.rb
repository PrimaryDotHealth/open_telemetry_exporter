# frozen_string_literal: true

require "logger"

module OpenTelemetryExporter
  class Logger
    class << self
      def increment(name, tags: {}, by: 1)
        if OpenTelemetryExporter.configuration.opentelemetry_enabled?
          begin
            meter = OpenTelemetryExporter.configuration.opentelemetry_meter
            raise "OpenTelemetry meter not configured" unless meter

            meter.create_counter(name).add(by, attributes: convert_tags(tags))
            by
          rescue => e
            log_error("OpenTelemetry error for metric '#{name}': #{e.message}")
            log_error("Falling back to configured fallback")
            call_fallback_increment(name, tags: tags, by: by)
          end
        else
          call_fallback_increment(name, tags: tags, by: by)
        end
      end

      def timing(name, value, tags: {})
        if OpenTelemetryExporter.configuration.opentelemetry_enabled?
          begin
            meter = OpenTelemetryExporter.configuration.opentelemetry_meter
            raise "OpenTelemetry meter not configured" unless meter

            meter.create_histogram(name).record(value, attributes: convert_tags(tags))
            value
          rescue => e
            log_error("OpenTelemetry error for timing metric '#{name}': #{e.message}")
            log_error("Falling back to configured fallback")
            call_fallback_timing(name, value, tags: tags)
          end
        else
          call_fallback_timing(name, value, tags: tags)
        end
      end

      def histogram(name, value, tags: {})
        if OpenTelemetryExporter.configuration.opentelemetry_enabled?
          begin
            meter = OpenTelemetryExporter.configuration.opentelemetry_meter
            raise "OpenTelemetry meter not configured" unless meter

            meter.create_histogram(name).record(value, attributes: convert_tags(tags))
            value
          rescue => e
            log_error("OpenTelemetry error for histogram metric '#{name}': #{e.message}")
            log_error("Falling back to configured fallback")
            call_fallback_histogram(name, value, tags: tags)
          end
        else
          call_fallback_histogram(name, value, tags: tags)
        end
      end

      private

      def call_fallback_increment(name, tags: {}, by: 1)
        fallback_object = OpenTelemetryExporter.configuration.fallback_object
        
        unless fallback_object
          return by
        end

        if defined?(Datadog::Statsd) && fallback_object.is_a?(Datadog::Statsd)
          call_datadog_increment(fallback_object, name, tags: tags, by: by)
        else
          return by
        end
      end

      def call_fallback_timing(name, value, tags: {})
        fallback_object = OpenTelemetryExporter.configuration.fallback_object
        
        unless fallback_object
          return value
        end

        if defined?(Datadog::Statsd) && fallback_object.is_a?(Datadog::Statsd)
          call_datadog_timing(fallback_object, name, value, tags: tags)
        else
          return value
        end
      end

      def call_fallback_histogram(name, value, tags: {})
        fallback_object = OpenTelemetryExporter.configuration.fallback_object
        
        unless fallback_object
          return value
        end

        if defined?(Datadog::Statsd) && fallback_object.is_a?(Datadog::Statsd)
          call_datadog_histogram(fallback_object, name, value, tags: tags)
        else
          return value
        end
      end

      # Datadog-specific fallback implementations
      def call_datadog_increment(statsd, name, tags: {}, by: 1)
        converted_tags = convert_tags_for_datadog(tags)
        statsd.increment(name, by: by, tags: converted_tags)
        by
      end

      def call_datadog_timing(statsd, name, value, tags: {})
        converted_tags = convert_tags_for_datadog(tags)
        statsd.timing(name, value, tags: converted_tags)
        value
      end

      def call_datadog_histogram(statsd, name, value, tags: {})
        converted_tags = convert_tags_for_datadog(tags)
        statsd.histogram(name, value, tags: converted_tags)
        value
      end

      def convert_tags(tags)
        return tags if tags.is_a?(Hash)

        tags.each_with_object({}) do |tag, result|
          key, value = tag.split(":", 2)
          result[key] = value
        end
      end

      def convert_tags_for_datadog(tags)
        return [] if tags.empty?
        
        if tags.is_a?(Hash)
          tags.map { |key, value| "#{key}:#{value}" }
        else
          tags
        end
      end

      def log_error(message)
        OpenTelemetryExporter.configuration.logger.error("OpenTelemetryExporter: #{message}")
      end
    end
  end
end 