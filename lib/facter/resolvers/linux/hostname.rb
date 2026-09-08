# frozen_string_literal: true

module Facter
  module Resolvers
    module Linux
      class Hostname < BaseResolver
        # :fqdn
        # :domain
        # :hostname

        init_resolver

        # Upper bound, in seconds, for the fqdn lookup. A hung name service
        # otherwise stalls fact collection until the agent's runtimeout fires
        # (OpenVoxProject/openvox#485). Only applied on Rubies that honour it.
        FQDN_LOOKUP_TIMEOUT = 10

        class << self
          private

          def post_resolve(fact_name, _options)
            @fact_list.fetch(fact_name) { retrieve_info(fact_name) }
          end

          def retrieve_info(fact_name)
            require 'socket'

            output = retrieving_hostname
            return nil unless output

            # Check if the gethostname method retrieved fqdn
            hostname, domain = parse_fqdn(output)

            fqdn = retrieve_fqdn_for_host(hostname) if hostname_and_no_domain?(hostname, domain)

            _, domain = parse_fqdn(fqdn) if exists_and_valid_fqdn?(fqdn, hostname)

            domain = read_domain unless exists_and_not_empty?(domain)

            construct_fact_list(hostname, domain, fqdn)
            @fact_list[fact_name]
          end

          def retrieving_hostname
            output = Socket.gethostname || ''
            if output.empty? || output['0.0.0.0']
              begin
                require_relative '../../../facter/util/resolvers/ffi/hostname'

                output = Facter::Util::Resolvers::Ffi::Hostname.getffihostname
              rescue LoadError => e
                log.debug(e.message)
                output = nil
              end
            end

            log.debug("Tried to retrieve hostname and got: #{output}")
            output unless output && output.empty?
          end

          def parse_fqdn(output)
            if output =~ /(.*?)\.(.+$)/
              log.debug("Managed to read hostname: #{Regexp.last_match(1)} and domain: #{Regexp.last_match(2)}")
              [Regexp.last_match(1), Regexp.last_match(2)]
            else
              log.debug("Only managed to read hostname: #{output}, no domain was found.")
              [output, '']
            end
          end

          def retrieve_fqdn_for_host(host)
            begin
              addr = Addrinfo.getaddrinfo(host, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME,
                                          **addrinfo_options)[0]
            rescue StandardError => e
              log.debug("Addrinfo.getaddrinfo failed to retrieve fqdn for hostname #{host} with: #{e}")
              # The name service is not answering. The FFI lookup below has no
              # timeout and holds the GVL while it waits, so do not try it.
              return if lookup_timed_out?(e)
            end

            name = addr&.canonname
            return name if exists_and_not_empty?(name) && host != name && name != addr.ip_address

            retrieve_fqdn_for_host_with_ffi(host)
          end

          def lookup_timed_out?(error)
            error.is_a?(Errno::ETIMEDOUT) || (defined?(IO::TimeoutError) && error.is_a?(IO::TimeoutError))
          end

          # Addrinfo.getaddrinfo only honours the timeout keyword from Ruby 4.0
          # on. Older MRI accepts and ignores it; JRuby does not accept it.
          def addrinfo_options
            addrinfo_timeout_supported? ? { timeout: FQDN_LOOKUP_TIMEOUT } : {}
          end

          def addrinfo_timeout_supported?
            RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0')
          end

          def retrieve_fqdn_for_host_with_ffi(host)
            require_relative '../../../facter/util/resolvers/ffi/hostname'

            fqdn = Facter::Util::Resolvers::Ffi::Hostname.getffiaddrinfo(host)
            log.debug("FFI getaddrinfo was called and it retrieved: #{fqdn}")
            fqdn
          rescue LoadError => e
            log.debug(e.message)
            nil
          end

          def exists_and_valid_fqdn?(fqdn, hostname)
            exists_and_not_empty?(fqdn) && fqdn.start_with?("#{hostname}.")
          end

          def hostname_and_no_domain?(hostname, domain)
            domain.empty? && !hostname.empty?
          end

          def read_domain
            file_content = Facter::Util::FileHelper.safe_read('/etc/resolv.conf')
            if file_content =~ /^domain\s+([^.]\S+)/
              Regexp.last_match(1)
            elsif file_content =~ /^search\s+([^.]\S+)/
              Regexp.last_match(1)
            end
          end

          def construct_fqdn(host, domain, fqdn)
            return fqdn if exists_and_not_empty?(fqdn)
            return if host.nil? || host.empty?

            exists_and_not_empty?(domain) ? "#{host}.#{domain}" : host
          end

          def construct_fact_list(hostname, domain, fqdn)
            @fact_list[:hostname] = hostname
            @fact_list[:domain] = domain
            @fact_list[:fqdn] = construct_fqdn(@fact_list[:hostname], @fact_list[:domain], fqdn)
          end

          def exists_and_not_empty?(variable)
            variable && !variable.empty?
          end
        end
      end
    end
  end
end
