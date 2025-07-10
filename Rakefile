# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'open3'
require 'rspec/core/rake_task'
require 'facter/version'

Dir.glob(File.join('tasks/**/*.rake')).each { |file| load file }

task default: :spec

begin
  require 'github_changelog_generator/task'
  require_relative 'lib/facter/version'

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = <<~HEADER.chomp
      # Changelog

      All notable changes to this project will be documented in this file.
    HEADER
    config.user = 'openvoxproject'
    config.project = 'openfact'
    config.exclude_labels = %w[dependencies duplicate question invalid wontfix wont-fix modulesync skip-changelog]
    config.future_release = Facter::VERSION
  end
rescue LoadError
  task :changelog do
    abort('Run `bundle install --with release` to install the `github_changelog_generator` gem.')
  end
end

namespace :pl_ci do
  desc 'build the gem and place it at the directory root'
  task :gem_build, [:gemspec] do |_t, args|
    args.with_defaults(gemspec: 'facter.gemspec')
    stdout, stderr, status = Open3.capture3("gem build #{args.gemspec}")
    if !status.exitstatus.zero?
      puts "Error building facter.gemspec \n#{stdout} \n#{stderr}"
      exit(1)
    else
      puts stdout
    end
  end

  desc 'build the nightly gem and place it at the directory root'
  task :nightly_gem_build do
    # this is taken from `rake package:nightly_gem`
    extended_dot_version = `git describe --tags --dirty --abbrev=7`.chomp.tr('-', '.')

    # we must create tempfile in the same directory as facter.gemspec, since
    # it uses __dir__ to determine which files to include
    require 'tempfile'
    Tempfile.create('gemspec', __dir__) do |dst|
      File.open('facter.gemspec', 'r') do |src|
        src.readlines.each do |line|
          if line.match?(/spec\.version\s*=\s*'[0-9.]+'/)
            line = "spec.version = '#{extended_dot_version}'"
          end
          dst.puts line
        end
      end
      dst.flush
      Rake::Task['pl_ci:gem_build'].invoke(dst.path)
    end
  end
end

if Rake.application.top_level_tasks.grep(/^(pl:|package:)/).any?
  begin
    require 'packaging'
    Pkg::Util::RakeUtils.load_packaging_tasks
  rescue LoadError => e
    puts "Error loading packaging rake tasks: #{e}"
  end
end

desc 'Prepare for a release'
task 'release:prepare' => [:changelog]

begin
  require 'rubocop/rake_task'
rescue LoadError
  # Do nothing if no required gem installed
else
  RuboCop::RakeTask.new(:rubocop) do |task|
    # These make the rubocop experience maybe slightly less terrible
    task.options = ['--display-cop-names', '--display-style-guide', '--extra-details']
    # Use Rubocop's Github Actions formatter if possible
    task.formatters << 'github' if ENV['GITHUB_ACTIONS'] == 'true'
  end
end
