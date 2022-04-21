# Get Repository Statistics

This script can help you find information about your repositories in your system

## Prerequisites

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
- Download the folder `get-repo-statistics` to your local machine
- Use `git-bash` to run the following commands
- Change into the directory
  - `cd get-repo-statistics`
- Build the `Dockerfile`
  - `docker build -t github/runner:latest -f Dockerfile .`
- This will build the container image: `github/runner:latest` with the needed scripts and libraries inside
- Run the container and map to a local folder to pull out data
  - `docker run -it --entrypoint /bin/bash -v /tmp:/tmp github/runner:latest`
  - This command will start the container and drop you into the running container, with the `/tmp` directory mounted to your personal machines `/tmp` directory
- You can now run the script from the container
  - `./get-repo-statistics.sh`
- Give the script information about `GHE_URL`, `GITHUB_TOKEN`, and `ORG_NAME`

## Input file
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
