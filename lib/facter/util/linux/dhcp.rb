# frozen_string_literal: true

module Facter
  module Util
    module Linux
      class Dhcp
        class << self
          DIRS = %w[/var/lib/dhclient/
                    /var/lib/dhcp/
                    /var/lib/dhcp3/
                    /var/lib/NetworkManager/
                    /var/db/].freeze

          def dhcp(interface_name, interface_index, logger)
            @log = logger
            @log.debug("Get DHCP for interface #{interface_name}")

            dhcp = search_systemd_netif_leases(interface_index, interface_name)
            dhcp ||= search_dhclient_leases(interface_name)
            dhcp ||= search_internal_leases(interface_name)
            dhcp ||= search_with_dhcpcd_command(interface_name)
            dhcp
          end

          private

          def search_systemd_netif_leases(index, interface_name)
            return if index.nil?

            @log.debug("Attempt to get DHCP for interface #{interface_name}, from systemd/netif/leases")

            file_content = Facter::Util::FileHelper.safe_read("/run/systemd/netif/leases/#{index}", nil)
            dhcp = file_content.match(/SERVER_ADDRESS=(.*)/) if file_content
            dhcp[1] if dhcp
          end

          def search_dhclient_leases(interface_name)
            @log.debug("Attempt to get DHCP for interface #{interface_name}, from dhclient leases")

            DIRS.each do |dir|
              next unless File.readable?(dir)

              lease_files = Dir.entries(dir).select { |file| file =~ /dhclient.*\.lease/ }
              next if lease_files.empty?

              lease_files.select do |file|
                content = Facter::Util::FileHelper.safe_read("#{dir}#{file}", nil)
                next unless /interface.*#{interface_name}/.match?(content)

                dhcp = content.match(/dhcp-server-identifier ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/)
                return dhcp[1] if dhcp
              end
            end

            nil
          end

          def search_internal_leases(interface_name)
            return unless File.readable?('/var/lib/NetworkManager/')

            @log.debug("Attempt to get DHCP for interface #{interface_name}, from NetworkManager leases")

            files = Dir.entries('/var/lib/NetworkManager/').reject { |dir| dir =~ /^\.+$/ }
            lease_file = files.find { |file| file =~ /internal.*#{interface_name}\.lease/ }
            return unless lease_file

            dhcp = Facter::Util::FileHelper.safe_read("/var/lib/NetworkManager/#{lease_file}", nil)

            return unless dhcp

            dhcp = dhcp.match(/SERVER_ADDRESS=(.*)/)
            dhcp[1] if dhcp
          end

          def search_with_dhcpcd_command(interface_name)
            return if interface_name == 'lo'

            @dhcpcd_command ||= Facter::Core::Execution.which('dhcpcd')
            return unless @dhcpcd_command

            unless dhcpcd_running?
              @log.debug('Skipping dhcpcd -U because dhcpcd daemon is not running')
              return
            end

            @log.debug("Attempt to get DHCP for interface #{interface_name}, from dhcpcd command")

            output = Facter::Core::Execution.execute("#{@dhcpcd_command} -U #{interface_name}", logger: @log)
            dhcp = output.match(/dhcp_server_identifier='(.*)'/)
            dhcp[1] if dhcp
          end

          def dhcpcd_running?
            pidfiles = Dir.glob('{/run,/var/run}/dhcpcd{,*,/}*.pid')
            pidfiles.each do |pf|
              next unless File.file?(pf)

              pid = begin
                Integer(Facter::Util::FileHelper.safe_read(pf, '').strip, 10)
              rescue StandardError
                nil
              end
              next unless pid&.positive?

              begin
                # Doesn't actually kill, just detects if the process exists
                Process.kill(0, pid)
                return true if proc_comm(pid) == 'dhcpcd' || proc_cmdline(pid)&.match?(%r{(^|\s|/)dhcpcd(\s|$)})
              rescue Errno::ESRCH
                # If we can't confirm identity, still treat it as not running to be safe.
                next
              rescue Errno::EPERM
                # Exists but we can't inspect it; assume it's running.
                return true
              end
            end

            # Fallback: Try to find it in /proc
            return false unless Dir.exist?('/proc')

            Dir.glob('/proc/[0-9]*/comm').any? do |path|
              Facter::Util::FileHelper.safe_read(path, nil)&.strip == 'dhcpcd'
            end
          end

          def proc_comm(pid)
            Facter::Util::FileHelper.safe_read("/proc/#{pid}/comm", nil)&.strip
          end

          def proc_cmdline(pid)
            raw = Facter::Util::FileHelper.safe_read("/proc/#{pid}/cmdline", nil)
            raw&.tr("\0", ' ')
          end
        end
      end
    end
  end
end
