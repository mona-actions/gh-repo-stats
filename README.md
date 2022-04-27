# Get Repository Statistics

**GitHub CLI** extensions are repositories that provide additional `gh` commands, and this **GitHub CLI** extension can help you find information about your repositories in your organizations.
This information outlines the underlying **GitHub** `metadata` associated with your repository. This information is key to understanding how long a migration of the data from one instance of **GitHub** to another will take.
When the extension is run to completion, you will be presented with a visual table, or `*.csv` file to parse for all relevant information.

## Prerequisites

- **GitHub CLI** installed by following this documentation: <https://github.com/cli/cli#installation>
- Operating system that can run shell scripts(*bash/sh*)

You need to either export these environment variables:

| Environment Variable name | Value                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| GITHUB_TOKEN              | GitHub Personal Access Token (PAT) with `admin:org`, `user:all`, and `repo:all` permissions |
| GHE_URL                   | GitHub URL or GHES URL without HTTP or HTTPS. Defaults to `https://github.com`.             |

Or the script will prompt you to put in the relevant information.

## How to run

Make sure you followed prerequisites and then follow these instructions.

### Step 1: Install GitHub extension

```sh
gh extension install mona-actions/gh-repo-stats
```

![Step 1](./screenshots/step1.png)

### Step 2: Run gh repo-stats

```sh
gh repo-stats --org <ORG_NAME> --ghe-url <GHE_URL> --token <GITHUB_TOKEN>
```

### Example Output

![Output 1](./screenshots/output1.png)
![Output 2](./screenshots/output2.png)

### CSV

Once the script has completed you will have either an inline table, or a genereted `csv` you can use to parse data.

```csv
Org_Name,Repo_Name,Is_Empty,Last_Push,Last_Update,isFork,Repo_Size(mb),Record_Count,Collaborator_Count,Protected_Branch_Count,PR_Review_Count,Milestone_Count,Issue_Count,PR_Count,PR_Review_Comment_Count,Commit_Comment_Count,Issue_Comment_Count,Issue_Event_Count,Release_Count,Project_Count,Full_URL,Migration_Issue
lukaspersonal,monitoring,false,2018-03-12T14:28:22Z,2018-01-26T17:10:44Z,false,0,11,1,0,0,0,4,2,0,0,0,4,0,0,https://github.com/lukaspersonal/monitoring,FALSE
lukaspersonal,pipelines,false,2018-01-26T17:53:32Z,2018-01-26T17:34:50Z,false,0,5,1,0,0,0,4,0,0,0,0,0,0,0,https://github.com/lukaspersonal/pipelines,FALSE
lukaspersonal,hubot,false,2018-03-05T19:00:08Z,2018-01-26T17:55:49Z,false,0,6,1,1,0,0,4,0,0,0,0,0,0,0,https://github.com/lukaspersonal/hubot,FALSE
lukaspersonal,webhooklistener,false,2018-01-26T18:20:03Z,2018-01-26T18:20:04Z,false,0,5,1,0,0,0,4,0,0,0,0,0,0,0,https://github.com/lukaspersonal/webhooklistener,FALSE
lukaspersonal,jenkins,false,2018-03-14T13:20:59Z,2018-03-14T13:21:00Z,false,0,11,1,0,0,0,4,2,0,0,0,4,0,0,https://github.com/lukaspersonal/jenkins,FALSE
```
