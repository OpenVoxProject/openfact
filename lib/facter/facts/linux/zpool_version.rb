# frozen_string_literal: true

module Facts
  module Linux
    class ZpoolVersion
      FACT_NAME = 'zpool_version'

      def call_the_resolver
        fact_value = Facter::Resolvers::Zpool.resolve(:zpool_version)
        Facter::ResolvedFact.new(FACT_NAME, fact_value)
      end
    end
  end
end
