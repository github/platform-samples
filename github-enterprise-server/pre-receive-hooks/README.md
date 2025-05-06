## Pre-receive hooks

### tl;dr

This directory contains examples for [pre-receive hooks ](https://help.github.com/enterprise/user/articles/working-with-pre-receive-hooks/) which are a [GitHub Enterprise feature](https://developer.github.com/v3/enterprise/pre_receive_hooks/) to block unwanted commits before they even reach your repository.

If you have a great example for a pre-receive hook you used with GitHub Enterprise that is not yet part of this directory, create a pull request and we will happily review it.

While blocking commits at push time using pre-receive-hooks seems like an awesome idea, there are many cases where other approaches work much better for your developers, check out the rest of this README for more info.

### Pre-receive hooks - The longer story

As of GitHub Enterprise 2.6 we [support pre-receive hooks](https://help.github.com/enterprise/user/articles/working-with-pre-receive-hooks/). [Pre-receive hooks](https://help.github.com/enterprise/user/articles/working-with-pre-receive-hooks/) run tests on code pushed to a repository to ensure contributions meet repository or organization policy. If the commits pass the tests, the push will be accepted into the repository. If the commits do not pass the tests, the push will not be accepted.

Your GitHub Enterprise site administrator can [create and remove pre-receive hooks](https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/) for your organization or repository, and may allow organization or repository administrators to enable or disable pre-receive hooks. GitHub Enterprise allows you to [develop and test](https://help.github.com/enterprise/admin/guides/developer-workflow/creating-a-pre-receive-hook-script/) all scripts locally in a [pre-receive hook environment](https://help.github.com/enterprise/2.6/admin/guides/developer-workflow/creating-a-pre-receive-hook-environment/).

Examples of pre-receive hooks:
* Require commit messages to follow a specific pattern or format, such as including a valid ticket number or being over a certain length.
* Prevent sensitive data from being added to the repository by blocking keywords, patterns or filetypes.
* Prevent a PR author from merging their own changes.
* Prevent a developer from pushing commits of a different author or committer.
* Prevent a developer from pushing unsigned commits.

You can find examples on how to write pre-receive hooks on the [Pro Git website](https://git-scm.com/book/en/v2/Customizing-Git-An-Example-Git-Enforced-Policy) and within this directory.

### Think twice before you deploy a pre-receive hook

GitHub recommends a cautious and thoughtful approach when applying mechanisms like pre-receive hooks that can block Git push operations. Blocking pushes right away typically prevents contribution and visibility into proposed changes. We think it's best that individuals collaborate with each other to identify and fix any problems after changes have been proposed. Even some of our largest customers have found that a subtle shift to [non-blocking web-hooks](https://help.github.com/enterprise/admin/guides/developer-workflow/using-webhooks-for-continuous-integration/) allowed more individuals to contribute and provided more opportunities for learning and collaboration. Combined with asynchronous collaboration workflows like [GitHubFlow](https://guides.github.com/introduction/flow/), non-blocking web-hooks typically resulted in higher-quality output.

That said, we understand there may be compliance or other organizational reasons to incorporate pre-receive hooks into a development workflow, e.g. ensuring that sensitive information is not included as part of pushed commits.

### Performance, stability and workflow implications of pre-receive hooks

Pre-receive hooks can have unintended effects on the performance of the GitHub Enterprise appliance and should be carefully [implemented and reviewed](https://help.github.com/enterprise/admin/guides/developer-workflow/creating-a-pre-receive-hook-script/). A misconfigured pre-receive hook may block all developers from contributing/pushing to a repository or consume all system resources on the appliance.

Running scripts will be automatically terminated after 5 seconds (blocking the push). Consequently, pre-receive hooks should not rely on the results of external systems that may not be always available or on any other potentially blocking resource. As any negative exit code of a pre-receive hook will reject the associated push attempt, your scripts should handle unforeseen standard input and environment variable values in a robust way.

When designing your scripts, also consider scenarios where many developers push at once (e.g. before lunch time). Parallel pushes will result in parallel runs of hook scripts. All parallel script runs have to compete for the same resources: CPU, memory, files, network, external systems. If any of the parallel runs needed more than 5 seconds to complete or triggered a programming error ([race condition](https://en.wikipedia.org/wiki/Race_condition#Software)), this may result in an unhappy developer whose push just got rejected for the wrong reasons.

**Any acceptable approach that can enforce your policy in an asynchronous fashion (see following paragraphs), will have less risk on the performance of your appliance and the effectiveness of your developer workflow.**

### Alternatives to pre-receive-hooks

Depending on your particular use case, you might be able to achieve your goals using [Protected Branches and Required Status checks](https://github.com/blog/2051-protected-branches-and-required-status-checks). Starting GitHub Enterprise 2.4, you can use Protected Branches to ensure that collaborators on your repository cannot make irrevocable changes to branches. If you [configure a branch as protected](https://help.github.com/articles/configuring-protected-branches/) it:

 - Can't be force pushed
 - Can't be deleted

If you also enable [Required Status](https://help.github.com/articles/enabling-required-status-checks/) on a protected branch, all required checks must succeed before team members are able to merge a Pull Request. Using our [Status API](https://developer.github.com/v3/repos/statuses/) you are able to define which checks (required or optional) should be triggered upon a Pull Request submission.

Instead of preventing the code from being committed you can also prevent it from being deployed. To do this, you can configure your deployment process to be triggered by the Pull Request merge event. Using the information that [GitHub's webhooks](https://developer.github.com/webhooks/) provide, you'll be able to determine whether the Pull Request meets the review and CI requirements. If it does not, you can reject the deployment and post the failure information back to the Pull Request. You can learn more about delivering deployments at https://developer.github.com/guides/delivering-deployments/.

Instead of putting controls in place that technically enforce your policy, you can also socially enforce it. Let's say your policy prescribes that pull requests should not be merged by the author of the pull request. You can build a culture within the company which makes merging your own Pull Request unacceptable behavior. To do this, you will need to be notified when someone merges their own Pull Request so that you can revert it and educate them on why having independent review is important. You can write a simple script, and attach it to a [webhook](https://developer.github.com/webhooks/), that looks for Pull Requests that were merged by the author. When this happens you can either post a comment in the Pull Request pinging a compliance team or send an email to a mailing list reporting the transgression. Once a developer has had their Pull Request reverted, they will be unlikely to make the same mistake again. This model places trust in the developers but still allows a certain degree of control and audibility. The power of Git makes undoing any unreviewed changes easy.

Worth noting if you haven't already considered it, you can set up a similar mechanism on your team members' local machines using a pre-commit hook which could certainly be faster than a server-side implementation: http://git-scm.com/book/en/Customizing-Git-Git-Hooks#Client-Side-Hooks
