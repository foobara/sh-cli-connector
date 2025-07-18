require_relative "version"

source "https://rubygems.org"
ruby Foobara::ShCliConnector::MINIMUM_RUBY_VERSION

# gem "foobara", path: "../foobara"

gemspec

gem "rake"

group :development do
  gem "foobara-rubocop-rules", ">= 1.0.0"
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

group :test do
  gem "foobara-spec-helpers", "< 2.00"
  gem "rspec"
  gem "rspec-its"
  gem "simplecov"
end

group :test, :development do
  gem "guard-rspec"
  gem "pry"
  gem "pry-byebug"
  # TODO: Just adding this to suppress warnings seemingly coming from pry-byebug. Can probably remove this once
  # pry-byebug has irb as a gem dependency
  gem "irb"
end
