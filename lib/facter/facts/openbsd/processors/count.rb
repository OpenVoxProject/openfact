# frozen_string_literal: true

module Facts
  module Openbsd
    module Processors
      class Count
        FACT_NAME = 'processors.count'

        def call_the_resolver
          fact_value = Facter::Resolvers::Openbsd::Processors.resolve(:online_count)
          Facter::ResolvedFact.new(FACT_NAME, fact_value)
        end
      end
    end
  end
end
