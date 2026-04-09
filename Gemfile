# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group(:release, optional: true) do
  gem 'faraday-retry', '~> 2.1', require: false if RUBY_VERSION >= '2.6'
  gem 'github_changelog_generator', '~> 1.16.4', require: false
end

gem 'packaging', require: false
