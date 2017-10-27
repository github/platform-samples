require "yaml"
require "graphql/client"
require "graphql/client/http"
require "github/configuration"
require "github/helpers"
require "copy_issue_comments/issue_comment_fetcher"
require "copy_issue_comments/issue_comments_creator"

class CopyIssueComments
  include GitHub::Helpers

  attr_reader :source, :target, :mappings

  def initialize(source:, target:, mappings: [])
    @source = extract_repo_info(:source, source)
    @target = extract_repo_info(:target, target)
    @mappings = mappings
  end

  def copy!
    issues_with_comments = IssueCommentFetcher.call(**source)
    issues_with_comments.each do |issue|
      next unless number = mapped_issue_number(issue["number"])
      IssueCommentsCreator.call(number, issue["comments"], **target)
    end
  end

  private

  # Returns the mapped number or nil if a mapping exists, otherwise returns the
  # provided number
  def mapped_issue_number(number)
    if mapping = mappings.detect { |m| m[:number] == number }
      return mapping[:renumbered]
    end
    number
  end
end
