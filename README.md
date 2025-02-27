gomerge-util
============

Set of tools supporting in using [gomerge](https://github.com/Cian911/gomerge) for batch PR approval and merging.

Motivation
----------

Pull requests that are created automatically for dependency updates can be a lot of work to manage, especially if there are many repositories.
`gomerge` allows to review PRs for a repository in the terminal, marking those that should be approved and merged. For each pull request it shows the check status for a quick assessment.

To be able to better handle many repositories or even organizations, we want to automate checking repositories for PRs and provide a workflow for review.
Also, including links to the repository PRs and notifications supports in the review process.

Setup & configuration
---------------------

You need to provide a `.env` file that at least includes your GitHub (personal access) token.

The file `.env.sample` serves as a template for the configuration.

The personal access token usually needs `repo` permissions, also `workflow` if PRs related to GitHub actions workflow files should be merged.

Another option you can configure is a set of pull request labels. Only PRs with one of these labels will be included in the review.

General requirements:

- currently Docker is used to run `gomerge` (because I had some trouble to get it running using my a bit older Ubuntu - issue with GLIBC version)

Tools
-----

### Review PRs related to GitHub notifications

Run the script `./review-notifications.sh` to start a review workflow based on your GitHub notifications.

Specific requirements:

- `curl` for some GitHub API requests
- `jq` for processing Json responses

The workflow is as follows:

1. User is asked if read notifications should be included for selecting repos to review (otherwise only unread notifications are considered)
2. Identified repos are printed and user asked for confirmation
3. For each repository it is checked if there are open PRs matching the criteria (labels if configured)
4. The user should select PRs that shall be approved and merged, otherwise continue without selecting PRs (Press `enter`)
5. If a PR was merged, the related notification is marked as done, otherwise it is marked as read
6. This continue for each repo until all were handled


**Important to note:** If there are many notifications it may be that not all are processed during a run (limit is 200). If you have more notifications it is recommended to exclude the read notifications (default) and repeat the process (as reviewed PR notifications where the PR remains open are marked as read).
