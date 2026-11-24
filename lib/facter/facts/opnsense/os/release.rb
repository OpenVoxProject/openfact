# frozen_string_literal: true

module Facts
  module Opnsense
    module Os
      class Release
        FACT_NAME = 'os.release'
        ALIASES = %w[operatingsystemmajrelease operatingsystemrelease].freeze

        def call_the_resolver
          version = determine_release_version

          return Facter::ResolvedFact.new(FACT_NAME, nil) unless version

          [Facter::ResolvedFact.new(FACT_NAME, version),
           Facter::ResolvedFact.new(ALIASES.first, version['major'], :legacy),
           Facter::ResolvedFact.new(ALIASES.last, version['full'], :legacy)]
        end

        # The series (e.g. "26.1") is the major release, the third version
        # component (e.g. "2" in "26.1.2") is the minor release
        def determine_release_version
          series = Facter::Resolvers::Opnsense::OpnsenseVersion.resolve(:series)
          version = Facter::Resolvers::Opnsense::OpnsenseVersion.resolve(:version)

          return unless series && version

          minor = version.split('.')[2]

          {}.tap do |release|
            release['full'] = version
            release['major'] = series
            release['minor'] = minor if minor
          end
        end
      end
    end
  end
end
