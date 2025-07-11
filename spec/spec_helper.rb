# frozen_string_literal: true

require "bundler/setup"
require "open_telemetry_exporter"
require "open_telemetry_exporter/test_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Object` and `Main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure OpenTelemetryExporter for tests
  config.before(:suite) do
    OpenTelemetryExporterHelper.configure_for_tests
  end
end 