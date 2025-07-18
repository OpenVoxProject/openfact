# frozen_string_literal: true

module Facter
  module Resolvers
    module Aix
      class Filesystems < BaseResolver
        init_resolver

        class << self
          private

          def post_resolve(fact_name, _options)
            @fact_list.fetch(fact_name) { read_vtf_file(fact_name) }
          end

          def read_vtf_file(fact_name)
            file_content = Facter::Util::FileHelper.safe_readlines('/etc/vfs')
            return if file_content.empty?

            file_content = file_content.map do |line|
              next if /#|%/.match?(line) # skip lines that are comments or defaultvfs line

              line.split(' ').first
            end

            @fact_list[:file_systems] = file_content.compact.sort.join(',')
            @fact_list[fact_name]
          end
        end
      end
    end
  end
end
