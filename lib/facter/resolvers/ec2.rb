# frozen_string_literal: true

module Facter
  module Resolvers
    class Ec2 < BaseResolver
      init_resolver

      EC2_METADATA_ROOT_URL = 'http://169.254.169.254/latest/meta-data/'
      EC2_USERDATA_ROOT_URL = 'http://169.254.169.254/latest/user-data/'
      EC2_SESSION_TIMEOUT = 5

      class << self
        private

        def post_resolve(fact_name, _options)
          log.debug('Querying Ec2 metadata')
          @fact_list.fetch(fact_name) { read_facts(fact_name) }
        end

        def read_facts(fact_name)
          if fact_name == :metadata
            metadata = {}
            query_for_metadata(EC2_METADATA_ROOT_URL, metadata)
            @fact_list[:metadata] = metadata
          else
            @fact_list[:userdata] = get_data_from(EC2_USERDATA_ROOT_URL).strip.force_encoding('UTF-8')
          end

          @fact_list[fact_name]
        end

        def query_for_metadata(url, container)
          metadata = get_metadata_from(url)
          metadata.each_line do |line|
            next if line.empty?

            http_path_component = build_path_component(line)
            next if http_path_component == 'security-credentials/'

            if http_path_component.end_with?('/')
              child = {}
              query_for_metadata("#{url}#{http_path_component}", child)
              name = http_path_component.chomp('/')
              container[name] = child
            else
              container[http_path_component] = get_metadata_from("#{url}#{http_path_component}").strip
            end
          end

          container
        end

        def build_path_component(line)
          array_match = /^(\d+)=.*$/.match(line)
          array_match ? "#{array_match[1]}/" : line.strip
        end

        def get_data_from(url)
          headers = {}
          headers['X-aws-ec2-metadata-token'] = v2_token if v2_token
          Facter::Util::Resolvers::Http.get_request(url, headers, { session: determine_session_timeout }, false)
        end

        def get_metadata_from(url)
          headers = {}
          headers['X-aws-ec2-metadata-token'] = v2_token if v2_token
          Facter::Util::Resolvers::Http.get_request!(url, headers, { session: determine_session_timeout }, false)
        end

        def determine_session_timeout
          session_env = ENV['EC2_SESSION_TIMEOUT']
          session_env ? session_env.to_i : EC2_SESSION_TIMEOUT
        end

        def v2_token
          @v2_token ||= begin
            token = Facter::Util::Resolvers::AwsToken.get
            token == '' ? nil : token
          end
        end
      end
    end
  end
end
