# frozen_string_literal: true

source "https://rubygems.org"

# Define your Ruby version (optional but recommended)
ruby "3.2.2"

# Add dependencies
gem "rubocop", require: false
gem "sinatra"
gem "matrix"
gem "webrick"

group :development, :test do
    gem "pry"
    gem "byebug"

    # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
    gem "brakeman", require: false

    # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
    gem "rubocop-rails-omakase", require: false
  end

group :test do
  gem "rspec"
  gem "rack-test"
end

gem "rackup", "~> 2.2"
gem "puma", "~> 6.6"
