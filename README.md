# Get Repository Statistics

`gh repo-stats` scans an organization or list of organizations for all repositories and gathers size statistics, key to understanding how long a migration of the data from one instance of **GitHub** to another will take.

## Quickstart

`gh repo-stats` was designed to work with GitHub.com as well as GitHub Enterprise Server 2.20 or newer.

1. Install [GitHub CLI](https://cli.github.com/)
1. Install [jq](https://stedolan.github.io/jq/download/)
1. `gh extension install mona-actions/gh-repo-stats`
1. `gh repo-stats --org <ORG_NAME>`
1. Profit! 💰 💸 🤑 💸 💰

## Usage

```shell
$ gh repo-stats --help

Usage: gh repo-stats [options]

Options:
     -d, --debug                   : Enable Debug logging
     -e, --extra-page-size         : Set the pagination size for subsequent, paginated GraphQL queries; reduce if timeout occurs
                                     Default: 50
     -h, --help                    : Show script help
     -H, --hostname                : The GitHub hostname for the request
                                     Default: github.com
     -i, --input                   : Set path to a file with a list of organizations to scan, one per line, newline delimited
     -o, --org                     : Name of the GitHub Organization to be analyzed
     -O, --output                  : Format of output, can either be "CSV" or "Table"
                                     Default: CSV
     -p, --repo-page-size          : Set the pagination size for the initial repository GraphQL query; reduce if timeout occurs
                                     Default: 10
                                     If a timeout occurs, reduce this value
     -r, --analyze-repo-conflicts  : Checks the Repo Name against repos in other organizations and generates a list
                                     of potential naming conflicts if those orgs are to be merged during migration
    -rl, --repo-list               : Path to a file with a list of repositories to scan, one per line, newline delimited
     -t, --token                   : Set Personal Access Token with repo scope
                                     Default: token for hostname via gh auth token
     -T, --analyze-team-conflicts  : Gathers each org's teams and checks against other orgs to generate a list of
                                     potential naming conflicts if those orgs are to be merged during migration
     -y, --token-type              : Type of Personal Access, can either be "user" or "app"
                                     Default: user

Description:
  Scans an organization or list of organizations for all repositories and gathers size statistics for each repository

Example:
  gh repo-stats -o my-org-name
  gh repo-stats -o my-org-name -H github.example.com
```

## Permissions

`gh repo-stats` uses the permissions of the authenticated accounts setup with [`gh auth login`](https://cli.github.com/manual/gh_auth_login) or [environment variables supported by `gh`](https://cli.github.com/manual/gh_help_environment).

The permissions needed by `gh repo-stats` depends based on `-y, --token-type`:

- `user`: `admin:org`, `user:all`, `repo:all`, and `read:project`
- `app` with [GitHub App server-to-server token](https://docs.github.com/en/developers/overview/managing-deploy-keys#server-to-server-tokens) with `Read-only` permissions to the following:
  - Repository Administration
  - Repository Contents
  - Repository Issues
  - Repository Metadata
  - Repository Projects
  - Repository Pull requests
  - Organization Members

## Output

`gh repo-stats` produces either a visual table or `*.csv` file containing detailed information about various records within repositories.

```csv
Org_Name,Repo_Name,Is_Empty,Last_Push,Last_Update,isFork,isArchive,Repo_Size(mb),Record_Count,Collaborator_Count,Protected_Branch_Count,PR_Review_Count,Milestone_Count,Issue_Count,PR_Count,PR_Review_Comment_Count,Commit_Comment_Count,Issue_Comment_Count,Issue_Event_Count,Release_Count,Project_Count,Branch_Count,Tag_Count,Discussion_Count,Has_Wiki,Full_URL,Migration_Issue,Created
tinyfists,actions-experiments,false,2023-03-10T16:15:27Z,2022-10-28T19:38:34Z,false,false,0,19,18,0,0,0,0,1,0,0,0,0,0,0,2,0,0,true,https://github.com/tinyfists/actions-experiments,FALSE,2020-01-01T13:37:00Z
tinyfists,git-xargs,false,2022-12-09T03:44:39Z,2022-11-01T03:19:49Z,false,false,0,19,18,0,0,0,0,1,0,0,0,0,0,0,2,0,0,true,https://github.com/tinyfists/git-xargs,FALSE,2020-01-01T13:37:00Z
tinyfists,githubcustomer,false,2022-06-04T17:00:43Z,2022-05-10T03:05:16Z,false,false,0,25,18,0,0,0,4,0,0,0,0,3,0,0,1,0,0,true,https://github.com/tinyfists/githubcustomer,FALSE,2020-01-01T13:37:00Z
tinyfists,issue-driven-github-admin,false,2022-12-09T03:44:36Z,2022-10-14T22:03:38Z,false,false,2,1644,37,1,1,0,140,4,1,0,897,552,10,1,4,10,1,true,https://github.com/tinyfists/issue-driven-github-admin,FALSE,2020-01-01T13:37:00Z
tinyfists,multi-runner-poc,false,2022-12-09T03:43:30Z,2022-08-03T12:44:35Z,false,false,0,19,18,0,0,0,0,1,0,0,0,0,0,0,2,0,0,true,https://github.com/tinyfists/multi-runner-poc,FALSE,2020-01-01T13:37:00Z
tinyfists,pages-demo,false,2022-12-09T03:43:29Z,2022-11-17T23:44:50Z,false,false,0,19,18,0,0,0,0,1,0,0,0,0,0,0,2,0,0,true,https://github.com/tinyfists/pages-demo,FALSE,2020-01-01T13:37:00Z
tinyfists,publish-packages-to-repo-demo,false,2022-12-09T03:43:31Z,2021-10-11T19:39:32Z,false,false,0,24,18,0,0,0,0,3,0,0,0,3,0,0,2,0,0,true,https://github.com/tinyfists/publish-packages-to-repo-demo,FALSE,2020-01-01T13:37:00Z
```

**Columns**

- `Org_Name`: Organization login
- `Repo_Name`: Repository name
- `Is_Empty`: Whether the repository is empty; only available for GitHub.com and GHES >= 3.0
- `Last_Push`: Date/time when a push was last made
- `Last_Update`: Date/time when an update was last made
- `isFork`: Whether the repository is a fork
- `isArchive`: Whether the repository is archived
- `Repo_Size(mb)`: Size of the repository in megabytes
- `Record_Count`: Number of database records this repository represents
- `Collaborator_Count`: Number of users who have contributed to this repository
- `Protected_Branch_Count`: Number of branch protection rules on this repository
- `PR_Review_Count`: Number of pull request reviews
- `Milestone_Count`: Number of issue milestones
- `Issue_Count`: Number of issues
- `PR_Count`: Number of pull requests
- `PR_Review_Comment_Count`: Number of pull request review comments
- `Commit_Comment_Count`: Number of commit comments
- `Issue_Comment_Count`: Number of issue comments
- `Issue_Event_Count`: Number of issues
- `Release_Count`: Number of releases
- `Project_Count`: Number of v1 projects
- `Branch_Count`: Number of branches
- `Tag_Count`: Number of tags
- `Discussion_Count`: Number of discussions
- `Has_Wiki`: Whether the repository has wiki feature enabled; unable to tell whether user via API
- `Full_URL`: Repository URL
- `Migration_Issue`: Indicates whether the repository might have a problem during migration due to
  - 60,000 or more number of objects being imported
  - 1.5 GB or larger size on disk
- `Created`: Date/time when the repository was created
