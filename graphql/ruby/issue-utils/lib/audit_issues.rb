require "yaml"
require "graphql/client"
require "graphql/client/http"
require "github/configuration"
require "github/helpers"
require "audit_issues/issue_fetcher"

class AuditIssues
  include GitHub::Helpers

  attr_reader :source, :target

  def initialize(source:, target:)
    @source = extract_repo_info(:source, source)
    @target = extract_repo_info(:target, target)
  end

  def audit
    source_issues = IssueFetcher.call(**source)
    target_issues = IssueFetcher.call(**target)
    compare_issues(source_issues, target_issues)
  end

  private

  def compare_issues(source_issues, target_issues)
    source_issues.map do |issue|
      next if matching_issue_exists?(issue, target_issues)
      if matched_issue = find_by_title(target_issues, issue["title"])
        renumbered_issue(issue, matched_issue)
      else
        unmatched_issue(issue)
      end
    end.compact
  end

  def renumbered_issue(issue, matched_issue)
    {
      number: issue["number"],
      renumbered: matched_issue["number"],
      issue: issue,
      candidate_issue: matched_issue,
      reason: "Possibly renumbered to #{matched_issue["number"]}"
    }
  end

  def unmatched_issue(issue)
    {
      number: issue["number"],
      issue: issue,
      reason: "No matching issue found"
    }
  end

  def matching_issue_exists?(issue, target_issues)
    return unless matched_issue = find_by_number(target_issues, issue["number"])
    issue["title"] == matched_issue["title"]
  end

  def find_by_number(issues, issue_number)
    issues.detect { |issue| issue["number"] == issue_number }
  end

  def find_by_title(issues, issue_title)
    issues.detect { |issue| issue["title"] == issue_title }
  end
end
