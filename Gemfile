# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group(:release, optional: true) do
  gem 'faraday-retry', '~> 2.1', require: false if RUBY_VERSION >= '2.6'
  gem 'github_changelog_generator', '~> 1.18', require: false if RUBY_VERSION >= '3.0'
end

gem 'packaging', require: false
