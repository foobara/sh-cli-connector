require_relative "src/sh_cli_connector/version"

Gem::Specification.new do |spec|
  spec.name = "foobara-sh-cli-connector"
  spec.version = Foobara::ShCliConnector::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Command-line connector for Foobara"
  spec.homepage = "https://github.com/foobara/sh-cli-connector"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "src/**/*",
    "LICENSE.txt"
  ]

  spec.add_dependency "foobara"

  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
