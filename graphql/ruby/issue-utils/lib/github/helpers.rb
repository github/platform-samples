module GitHub
  module Helpers
    def extract_repo_info(target, str)
      orgname, reponame = str.split("/")
      client_config = GitHub::Configuration.new(target: target)
      {
        orgname: orgname,
        reponame: reponame,
        client: build_github_client(client_config)
      }
    end

    def build_github_client(config)
      # Configure GraphQL endpoint using the basic HTTP network adapter.
      http = GraphQL::Client::HTTP.new(config.graphql_endpoint) do

        define_method :headers do |context|
          { "Authorization": "Bearer #{config.personal_access_token}" }
        end
      end

      # Fetch latest schema on init, this will make a network request
      schema = GraphQL::Client.load_schema(http)

      GraphQL::Client.new(schema: schema, execute: http).tap do |client|
        client.allow_dynamic_queries = true
      end
    end
  end
end
