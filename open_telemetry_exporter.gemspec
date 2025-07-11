# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "open_telemetry_exporter"
  spec.version = "0.1.0"
  spec.authors = ["Engineering"]
  spec.email = ["engineering@primary.health"]

  spec.summary = "A configurable OpenTelemetry exporter gem with fallback options"
  spec.description = "A flexible OpenTelemetry exporter gem that supports OpenTelemetry as the primary backend with configurable fallback options for other metrics systems like Datadog StatsD."
  spec.homepage = "https://github.com/PrimaryDotHealth/open_telemetry_exporter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*") + %w[README.md LICENSE.txt]
  spec.require_paths = ["lib"]

  spec.add_dependency "opentelemetry-api", "~> 1.0"
  spec.add_dependency "opentelemetry-sdk", "~> 1.0"
  spec.add_dependency "opentelemetry-metrics-sdk", "~> 0.1"
  spec.add_dependency "opentelemetry-exporter-otlp", "~> 0.1"
  spec.add_dependency "opentelemetry-exporter-otlp-metrics", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-rspec", "~> 2.0"
  spec.add_development_dependency "climate_control", "~> 1.0"
end 