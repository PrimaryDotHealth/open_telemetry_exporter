# frozen_string_literal: true

require "spec_helper"
require "climate_control"

RSpec.describe OpenTelemetryExporter::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.opentelemetry_enabled).to be false
      expect(config.opentelemetry_meter).to be_nil
      expect(config.fallback_object).to be_nil
    end

    it "reads opentelemetry_enabled from environment" do
      ClimateControl.modify OPENTELEMETRY_ENABLED: "true" do
        config = described_class.new
        expect(config.opentelemetry_enabled).to be true
      end
    end
  end

  describe "#opentelemetry_enabled?" do
    it "returns true when enabled" do
      config.opentelemetry_enabled = true
      expect(config.opentelemetry_enabled?).to be true
    end

    it "returns false when disabled" do
      config.opentelemetry_enabled = false
      expect(config.opentelemetry_enabled?).to be false
    end
  end

  describe "#fallback_configured?" do
    it "returns true when fallback object is set" do
      config.fallback_object = double("fallback")
      expect(config.fallback_configured?).to be true
    end

    it "returns false when fallback object is nil" do
      config.fallback_object = nil
      expect(config.fallback_configured?).to be false
    end
  end

  describe "#logger" do
    it "returns Rails.logger when Rails is defined" do
      stub_const("Rails", double(logger: double("rails_logger")))
      expect(config.logger).to eq(Rails.logger)
    end

    it "returns Logger.new($stdout) when Rails is not defined" do
      hide_const("Rails")
      expect(config.logger).to be_a(Logger)
    end
  end
end 