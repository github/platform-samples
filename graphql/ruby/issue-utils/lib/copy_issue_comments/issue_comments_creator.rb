class CopyIssueComments
  class IssueCommentsCreator
    attr_reader :issue_number, :comments, :orgname, :reponame, :client

    def initialize(issue_number, comments, orgname:, reponame:, client:)
      @issue_number = issue_number
      @comments = comments
      @orgname = orgname
      @reponame = reponame
      @client = client
    end

    def self.call(*args)
      self.new(*args).call
    end

    def call
      comments.each do |comment|
        add_comment(subject_id: issue_id, body: format_body(comment))
      end
    end

    private

    def issue_id
      @_issue_id ||= get_issue_by_number(issue_number: issue_number)["data"]["repository"]["issueOrPullRequest"]["id"]
    end

    def add_comment(subject_id:, body:)
      client.query(create_comment_mutation, variables: { subject_id: subject_id, body: body }).original_hash
    end

    def get_issue_by_number(issue_number:)
      client.query(issue_number_query, variables: { owner: orgname, name: reponame, number: issue_number }).original_hash
    end

    def create_comment_mutation
      client.parse <<-'GRAPHQL'
        mutation($subject_id: ID!, $body: String!) {
          addComment(input: { subjectId: $subject_id, body: $body }) {
            commentEdge {
              node {
                body
              }
            }
          }
        }
      GRAPHQL
    end

    def issue_number_query
      client.parse <<-'GRAPHQL'
        query($owner: String!, $name: String!, $number: Int!) {
          repository(owner: $owner, name: $name) {
            issueOrPullRequest(number: $number) {
              ... on Issue {
                id
              }
              ... on PullRequest {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    def format_body(comment)
      <<~"EOF"
        *Originally posted by [#{comment["author"]["login"]}](#{comment["author"]["url"]}) on #{comment["createdAt"]}*

        ---

        #{comment["body"]}
      EOF
    end
  end
end
