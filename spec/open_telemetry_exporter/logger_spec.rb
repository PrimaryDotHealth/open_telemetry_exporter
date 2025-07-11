# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenTelemetryExporter::Logger do
  let(:mock_logger) { double("logger") }
  let(:mock_meter) { double("meter") }
  let(:mock_counter) { double("counter") }
  let(:mock_histogram) { double("histogram") }
  let(:mock_fallback) { double("fallback") }

  before do
    OpenTelemetryExporter.reset_configuration!
    OpenTelemetryExporter.configure do |config|
      config.logger = mock_logger
      config.fallback_object = mock_fallback
    end

    # Mock the Datadog::Statsd class
    stub_const("Datadog::Statsd", Class.new)
    allow(mock_fallback).to receive(:is_a?).with(Datadog::Statsd).and_return(true)
    allow(mock_fallback).to receive(:increment).and_return(1)
    allow(mock_fallback).to receive(:timing).and_return(100)
    allow(mock_fallback).to receive(:histogram).and_return(50)
  end

  describe ".increment" do
    context "when OpenTelemetry is enabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = true
        OpenTelemetryExporter.configuration.opentelemetry_meter = mock_meter
      end

      it "calls OpenTelemetry meter when successful" do
        expect(mock_meter).to receive(:create_counter).with("test.metric").and_return(mock_counter)
        expect(mock_counter).to receive(:add).with(1, attributes: { "tag1" => "value1" })

        described_class.increment("test.metric", tags: { "tag1" => "value1" })
      end

      it "falls back to fallback when OpenTelemetry fails" do
        allow(mock_meter).to receive(:create_counter).and_raise("OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: OpenTelemetry error for metric 'test.metric': OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: Falling back to configured fallback")
        expect(mock_fallback).to receive(:increment).with("test.metric", by: 1, tags: ["tag1:value1"])

        described_class.increment("test.metric", tags: { "tag1" => "value1" })
      end

      it "falls back when meter is not configured" do
        OpenTelemetryExporter.configuration.opentelemetry_meter = nil
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: OpenTelemetry error for metric 'test.metric': OpenTelemetry meter not configured")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: Falling back to configured fallback")
        expect(mock_fallback).to receive(:increment).with("test.metric", by: 1, tags: ["tag1:value1"])

        described_class.increment("test.metric", tags: { "tag1" => "value1" })
      end
    end

    context "when OpenTelemetry is disabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
      end

      it "calls fallback directly" do
        expect(mock_fallback).to receive(:increment).with("test.metric", by: 1, tags: ["tag1:value1"])

        described_class.increment("test.metric", tags: { "tag1" => "value1" })
      end
    end

    context "when fallback is not configured" do
      before do
        OpenTelemetryExporter.configuration.fallback_object = nil
      end

      it "returns the original value silently" do
        result = described_class.increment("test.metric")
        expect(result).to eq(1)
      end
    end

    context "with Datadog StatsD fallback" do
      let(:datadog_statsd) { double("Datadog::Statsd") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = datadog_statsd
        allow(datadog_statsd).to receive(:increment).and_return(1)
        allow(datadog_statsd).to receive(:is_a?).with(Datadog::Statsd).and_return(true)
      end

      it "calls Datadog StatsD with converted tags" do
        expect(datadog_statsd).to receive(:increment).with("test.metric", by: 1, tags: ["tag1:value1"])

        described_class.increment("test.metric", tags: { "tag1" => "value1" })
      end

      it "handles array tags for Datadog" do
        expect(datadog_statsd).to receive(:increment).with("test.metric", by: 1, tags: ["tag1:value1", "tag2:value2"])

        described_class.increment("test.metric", tags: ["tag1:value1", "tag2:value2"])
      end
    end

    context "with non-Datadog fallback object" do
      let(:custom_fallback) { double("custom_fallback") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = custom_fallback
        allow(custom_fallback).to receive(:is_a?).with(Datadog::Statsd).and_return(false)
      end

      it "returns the original value silently" do
        result = described_class.increment("test.metric", tags: { "tag1" => "value1" })
        expect(result).to eq(1)
      end
    end
  end

  describe ".timing" do
    context "when OpenTelemetry is enabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = true
        OpenTelemetryExporter.configuration.opentelemetry_meter = mock_meter
      end

      it "calls OpenTelemetry meter when successful" do
        expect(mock_meter).to receive(:create_histogram).with("test.timing").and_return(mock_histogram)
        expect(mock_histogram).to receive(:record).with(150.5, attributes: { "tag1" => "value1" })

        described_class.timing("test.timing", 150.5, tags: { "tag1" => "value1" })
      end

      it "falls back to fallback when OpenTelemetry fails" do
        allow(mock_meter).to receive(:create_histogram).and_raise("OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: OpenTelemetry error for timing metric 'test.timing': OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: Falling back to configured fallback")
        expect(mock_fallback).to receive(:timing).with("test.timing", 150.5, tags: ["tag1:value1"])

        described_class.timing("test.timing", 150.5, tags: { "tag1" => "value1" })
      end
    end

    context "when OpenTelemetry is disabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
      end

      it "calls fallback directly" do
        expect(mock_fallback).to receive(:timing).with("test.timing", 150.5, tags: ["tag1:value1"])

        described_class.timing("test.timing", 150.5, tags: { "tag1" => "value1" })
      end
    end

    context "when fallback is not configured" do
      before do
        OpenTelemetryExporter.configuration.fallback_object = nil
      end

      it "returns the original value silently" do
        result = described_class.timing("test.timing", 150.5)
        expect(result).to eq(150.5)
      end
    end

    context "with Datadog StatsD fallback" do
      let(:datadog_statsd) { double("Datadog::Statsd") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = datadog_statsd
        allow(datadog_statsd).to receive(:timing).and_return(150.5)
        allow(datadog_statsd).to receive(:is_a?).with(Datadog::Statsd).and_return(true)
      end

      it "calls Datadog StatsD with converted tags" do
        expect(datadog_statsd).to receive(:timing).with("test.timing", 150.5, tags: ["tag1:value1"])

        described_class.timing("test.timing", 150.5, tags: { "tag1" => "value1" })
      end
    end

    context "with non-Datadog fallback object" do
      let(:custom_fallback) { double("custom_fallback") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = custom_fallback
        allow(custom_fallback).to receive(:is_a?).with(Datadog::Statsd).and_return(false)
      end

      it "returns the original value silently" do
        result = described_class.timing("test.timing", 150.5, tags: { "tag1" => "value1" })
        expect(result).to eq(150.5)
      end
    end
  end

  describe ".histogram" do
    context "when OpenTelemetry is enabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = true
        OpenTelemetryExporter.configuration.opentelemetry_meter = mock_meter
      end

      it "calls OpenTelemetry meter when successful" do
        expect(mock_meter).to receive(:create_histogram).with("test.histogram").and_return(mock_histogram)
        expect(mock_histogram).to receive(:record).with(42, attributes: { "tag1" => "value1" })

        described_class.histogram("test.histogram", 42, tags: { "tag1" => "value1" })
      end

      it "falls back to fallback when OpenTelemetry fails" do
        allow(mock_meter).to receive(:create_histogram).and_raise("OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: OpenTelemetry error for histogram metric 'test.histogram': OpenTelemetry timeout")
        expect(mock_logger).to receive(:error).with("OpenTelemetryExporter: Falling back to configured fallback")
        expect(mock_fallback).to receive(:histogram).with("test.histogram", 42, tags: ["tag1:value1"])

        described_class.histogram("test.histogram", 42, tags: { "tag1" => "value1" })
      end
    end

    context "when OpenTelemetry is disabled" do
      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
      end

      it "calls fallback directly" do
        expect(mock_fallback).to receive(:histogram).with("test.histogram", 42, tags: ["tag1:value1"])

        described_class.histogram("test.histogram", 42, tags: { "tag1" => "value1" })
      end
    end

    context "when fallback is not configured" do
      before do
        OpenTelemetryExporter.configuration.fallback_object = nil
      end

      it "returns the original value silently" do
        result = described_class.histogram("test.histogram", 42)
        expect(result).to eq(42)
      end
    end

    context "with Datadog StatsD fallback" do
      let(:datadog_statsd) { double("Datadog::Statsd") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = datadog_statsd
        allow(datadog_statsd).to receive(:histogram).and_return(42)
        allow(datadog_statsd).to receive(:is_a?).with(Datadog::Statsd).and_return(true)
      end

      it "calls Datadog StatsD with converted tags" do
        expect(datadog_statsd).to receive(:histogram).with("test.histogram", 42, tags: ["tag1:value1"])

        described_class.histogram("test.histogram", 42, tags: { "tag1" => "value1" })
      end
    end

    context "with non-Datadog fallback object" do
      let(:custom_fallback) { double("custom_fallback") }

      before do
        OpenTelemetryExporter.configuration.opentelemetry_enabled = false
        OpenTelemetryExporter.configuration.fallback_object = custom_fallback
        allow(custom_fallback).to receive(:is_a?).with(Datadog::Statsd).and_return(false)
      end

      it "returns the original value silently" do
        result = described_class.histogram("test.histogram", 42, tags: { "tag1" => "value1" })
        expect(result).to eq(42)
      end
    end
  end
end 