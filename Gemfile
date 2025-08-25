# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group(:release, optional: true) do
  gem 'faraday-retry', '~> 2.1', require: false
  gem 'github_changelog_generator', '~> 1.16.4', require: false
end

gem 'packaging', require: false

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval_gemfile(local_gemfile) if File.exist?(local_gemfile)

group(:integration, optional: true) do
  # 1.16.0 - 1.16.2 are broken on Windows
  gem 'ffi', '>= 1.15.5', '< 1.17.0', '!= 1.16.0', '!= 1.16.1', '!= 1.16.2', require: false
end
