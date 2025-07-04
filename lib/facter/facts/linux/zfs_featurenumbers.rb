# frozen_string_literal: true

module Facts
  module Linux
    class ZfsFeaturenumbers
      FACT_NAME = 'zfs_featurenumbers'

      def call_the_resolver
        fact_value = Facter::Resolvers::ZFS.resolve(:zfs_featurenumbers)
        Facter::ResolvedFact.new(FACT_NAME, fact_value)
      end
    end
  end
end
