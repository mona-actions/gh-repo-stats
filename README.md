# Get Repository Statistics

GitHub CLI extensions are repositories that provide additional gh commands, and this GitHub CLI extension can help you find information about your repositories in your system.

## Prerequisites

- You need to have GitHub CLI installed by following this documentation: https://github.com/cli/cli#installation
- You need to have an operating system to run shell script

You need to either export these environment variables

| Environment Variable name | Value |
| ------------------------- | ----- |
| GITHUB_TOKEN | GitHub Personal Access Token (PAT) with `admin:org`, `user:all`, and `repo:all` permissions
| ORG_NAME | Organization name to run script |
| GHE_URL | GitHub URL or GHES URL without http or https |

You can export these environment variables with following commands:

```sh
export GITHUB_TOKEN=<Your GitHub PAT>
export ORG_NAME=<Your Org name>
export GHE_URL=<Your GHE URL>
```

You can also create an environment variable named `.env` in following format:

```sh
GITHUB_TOKEN=<Your GitHub PAT>
ORG_NAME=<Your Org name>
GHE_URL=<Your GHE URL>
```

Then, you can source with a following command:

```sh
source .env
```

## How to run

Make sure you followed prerequisites and then follow this instruction.

### Step 1: Install GitHub extension

```sh
gh extension install mona-actions/gh-repo-stats
```

### Input file
If you want to run this over multiple Orgs, you can pass an `input file` when starting the script
- `./get-repo-statistics.sh --input Org-file.csv`
- This will read in a list of orgs and run over the list

The input file needs to be in the following format:

```csv
trash,more-trash,OrgName1
trash,more-trash,OrgName2
trash,more-trash,OrgName3
trash,more-trash,OrgName4
```

**NOTE:** The input file was originally pulled from a previous location and the objects in columns `1` and `2` are only placeholders in this context.
