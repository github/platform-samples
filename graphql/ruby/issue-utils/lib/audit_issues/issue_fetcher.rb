class AuditIssues
  class IssueFetcher
    attr_reader :orgname, :reponame, :client

    def initialize(orgname:, reponame:, client:)
      @orgname = orgname
      @reponame = reponame
      @client = client
    end

    def self.call(*args)
      self.new(*args).call
    end
    def call
      issues = []
      after = nil
      %w{issues pullRequests}.each do |model|
        begin
          data = get_issues(model: model, after: after)
          issues +=  data["data"]["organization"]["repository"][model]["edges"].map { |i| i["node"].dup }
        end while after = next_cursor(data["data"]["organization"]["repository"][model]["pageInfo"])
      end
      issues
    end

    private

    def get_issues(model: "issues", after:nil)
      client.query(issues_query(model), variables: { orgname: orgname, reponame: reponame, issues_after: after }).original_hash
    end

    def issues_query(model)
      client.parse <<-"GRAPHQL"
        query($orgname: String!, $reponame: String!, $issues_after: String) {
          organization(login: $orgname) {
            repository(name: $reponame) {
              #{model}(first: 100, after: $issues_after) {
                edges {
                  node {
                    id
                    number
                    title
                  }
                }
                totalCount
                pageInfo {
                  endCursor
                  hasNextPage
                  hasPreviousPage
                  startCursor
                }
              }
            }
          }
        }
      GRAPHQL
    end


    def next_cursor(page_info)
      if page_info["hasNextPage"]
        return page_info["endCursor"]
      end
    end
  end
end
