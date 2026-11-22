# frozen_string_literal: true

module Facter
  module Resolvers
    module Opnsense
      class OpnsenseVersion < BaseResolver
        init_resolver

        class << self
          private

          def post_resolve(fact_name, _options)
            @fact_list.fetch(fact_name) { opnsense_version_system_call(fact_name) }
          end

          # opnsense-version -NVv outputs name, series and version, e.g. "OPNsense 26.1 26.1.2"
          def opnsense_version_system_call(fact_name)
            output = Facter::Core::Execution.execute('/usr/local/sbin/opnsense-version -NVv', logger: log)

            build_fact_list(output)

            @fact_list[fact_name]
          end

          # Incomplete output sets all values to nil
          def build_fact_list(output)
            opnsense_version_results = output.split
            opnsense_version_results = [] if opnsense_version_results.length < 3

            @fact_list[:name], @fact_list[:series], @fact_list[:version] = opnsense_version_results
          end
        end
      end
    end
  end
end
