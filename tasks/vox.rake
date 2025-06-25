# frozen_string_literal: true

namespace :vox do
  desc 'Update the version in preparation for a release'
  task 'version:bump:full', [:version] do |_, args|
    abort 'You must provide a tag.' if args[:version].nil? || args[:version].empty?
    version = args[:version]
    abort "#{version} does not appear to be a valid version string in x.y.z format" unless Gem::Version.correct?(version)

    # Update lib/facter/version.rb and openvox.gemspec
    puts "Setting version to #{version}"

    data = File.read('lib/facter/version.rb')
    new_data = data.sub(/VERSION = '\d+\.\d+\.\d+'/, "VERSION = '#{version}'")
    raise 'Failed to update version in lib/facter/version.rb' if data == new_data

    File.write('lib/facter/version.rb', new_data)

    data = File.read('openfact.gemspec')
    new_data = data.sub(/(spec.version *=) '\d+\.\d+\.\d+'/, "\\1 '#{version}'")
    raise 'Failed to update version in openfact.gemspec' if data == new_data

    File.write('openfact.gemspec', new_data)
  end
end
