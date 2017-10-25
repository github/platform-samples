require "yaml"
require "graphql/client"
require "graphql/client/http"
require "github/configuration"
require "copy_issue_comments/issue_comment_fetcher"
require "copy_issue_comments/issue_comments_creator"

class CopyIssueComments
  attr_reader :source, :target

  def initialize(source:, target:)
    @source = extract_repo_info(:source, source)
    @target = extract_repo_info(:target, target)
  end

  def copy!
    issues_with_comments = IssueCommentFetcher.call(**source)
    issues_with_comments.each do |issue|
      puts "Creating comments for Issue ##{issue["number"]}"

      IssueCommentsCreator.call(issue["number"], issue["comments"], **target)
    end
  end

  private

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

    # However, it's smart to dump this to a JSON file and load from disk
    #
    # Run it from a script or rake task
    #   GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
    #
    # Schema = GraphQL::Client.load_schema("path/to/schema.json")

    GraphQL::Client.new(schema: schema, execute: http).tap do |client|
      client.allow_dynamic_queries = true
    end
  end
end
