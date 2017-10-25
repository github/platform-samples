class CopyIssueComments
  class IssueCommentFetcher
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
          issues +=  data["data"]["organization"]["repository"][model]["edges"].map { |i| i["node"].dup }.select { |i| i["comments"]["edges"].any? }
        end while after = next_cursor(data["data"]["organization"]["repository"][model]["pageInfo"])
      end

      issues.map do |issue|
        page_info = issue["comments"]["pageInfo"]
        issue_comments = issue["comments"]["edges"].map { |c| c["node"] }
        while comments_after = next_cursor(page_info)
          comments = get_additional_comments(issue_id: issue["id"], after: comments_after)
          page_info = comments["data"]["node"]["comments"]["pageInfo"]
          issue_comments += comments["data"]["node"]["comments"]["edges"].map { |c| c["node"] }
        end
        issue["comments"] = issue_comments
        issue
      end
    end

    private

    def get_issues(model: "issues", after:nil)
      client.query(issue_with_comments_query(model), variables: { orgname: orgname, reponame: reponame, issues_after: after }).original_hash
    end

    def get_additional_comments(issue_id:, after: nil)
      client.query(additional_comments_query, variables: { issue_id: issue_id, comments_after: after }).original_hash
    end

    def issue_with_comments_query(model)
      client.parse <<-"GRAPHQL"
        query($orgname: String!, $reponame: String!, $issues_after: String, $comments_after: String) {
          organization(login: $orgname) {
            repository(name: $reponame) {
              #{model}(first: 100, after: $issues_after) {
                edges {
                  node {
                    id
                    number
                    comments(first: 100, after: $comments_after) {
                      edges {
                        node {
                          author {
                            url
                            login
                          }
                          body
                          createdAt
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

    def additional_comments_query
      client.parse <<-'GRAPHQL'
        query($issue_id: ID!, $comments_after: String) {
          node(id: $issue_id) {
            ... on Issue {
              comments(first: 20, after: $comments_after) {
                edges {
                  node {
                    author {
                      url
                      login
                    }
                    body
                    createdAt
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
