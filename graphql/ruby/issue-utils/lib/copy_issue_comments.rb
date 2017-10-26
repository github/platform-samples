require "yaml"
require "graphql/client"
require "graphql/client/http"
require "github/configuration"
require "github/helpers"
require "copy_issue_comments/issue_comment_fetcher"
require "copy_issue_comments/issue_comments_creator"

class CopyIssueComments
  include GitHub::Helpers

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
end
