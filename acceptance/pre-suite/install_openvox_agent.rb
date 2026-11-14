# frozen_string_literal: true

# beaker-puppet only installs Perforce's puppet-agent, so openvox-agent comes
# from voxpupuli's beaker_puppet_helpers. Only its install code is loaded,
# because its DSL would replace the beaker-puppet helpers of the same names.
require 'beaker_puppet_helpers/install_utils'
require 'beaker_puppet_helpers/windows_utils'

test_name('install openvox-agent') do
  extend BeakerPuppetHelpers::WindowsUtils

  collection = ENV.fetch('RELEASE_STREAM')

  agents.each do |agent|
    # beaker_puppet_helpers can't install on macOS, so the workflow does
    next if agent['platform'].start_with?('osx')

    if agent['platform'].include?('windows')
      install_msi_on(agent, collection)
    else
      BeakerPuppetHelpers::InstallUtils.install_puppet_release_repo_on(agent, collection)
      agent.install_package(BeakerPuppetHelpers::InstallUtils.collection2packagename(agent, collection))
    end
  end

  # Puts the agent's bin directories on the PATH that Beaker gives to the
  # commands of the tests.
  configure_type_defaults_on(agents)
end
