require "yaml"
require "graphql/client"
require "graphql/client/http"
require "github/configuration"
require "audit_issues/issue_fetcher"

class AuditIssues
  attr_reader :source, :target

  def initialize(source:, target:)
    @source = extract_repo_info(:source, source)
    @target = extract_repo_info(:target, target)
  end

  def audit
    source_issues = IssueFetcher.call(**source)
    target_issues = IssueFetcher.call(**target)
    erroneous_issues = []
    source_issues.each do |issue|
      if matched_issue = find_by_number(target_issues, issue["number"])
        unless issue["title"] == matched_issue["title"]
          if matched_issue = find_by_title(target_issues, issue["title"])
            erroneous_issues.push({
              number: issue["number"],
              renumbered: matched_issue["number"],
              issue: issue,
              reason: "Possibly renumbered to #{matched_issue["number"]}"
            })
          else
            erroneous_issues.push({
              number: issue["number"],
              issue: issue,
              reason: "No matching issue found"
            })
          end
        end
      elsif matched_issue = find_by_title(target_issues, issue["title"])
        erroneous_issues.push({
          number: issue["number"],
          renumbered: matched_issue["number"],
          issue: issue,
          reason: "Possibly renumbered to #{matched_issue["number"]}"
        })
      else
        erroneous_issues.push({
          number: issue["number"],
          issue: issue,
          reason: "No matching issue found"
        })
      end
    end
    erroneous_issues
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

  def find_by_number(issues, issue_number)
    issues.detect { |issue| issue["number"] == issue_number }
  end

  def find_by_title(issues, issue_title)
    issues.detect { |issue| issue["title"] == issue_title }
  end
end
