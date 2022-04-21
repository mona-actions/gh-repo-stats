# Get Repository Statistics

GitHub CLI extensions are repositories that provide additional gh commands, and this GitHub CLI extension can help you find information about your repositories in your organizations.

## Prerequisites

- You need to have GitHub CLI installed by following this documentation: <https://github.com/cli/cli#installation>
- You need to have an operating system to run shell scripts

You need to either export these environment variables

| Environment Variable name | Value                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| GITHUB_TOKEN              | GitHub Personal Access Token (PAT) with `admin:org`, `user:all`, and `repo:all` permissions |
| ORG_NAME                  | Organization name to run script                                                             |
| GHE_URL                   | GitHub URL or GHES URL without HTTP or HTTPS                                                |

Or the script will prompt you to put in the relevant information.

## How to run

Make sure you followed prerequisites and then follow this instruction.

### Step 1: Install GitHub extension

```sh
gh extension install mona-actions/gh-repo-stats
```

![Step 1](./screenshots/step1.png)

### Step 2: Run gh repo stats

```sh
gh repo-stats --org-name=<ORG_NAME> --ghe-url=<GHE_URL> --token=<GITHUB_TOKEN>
```

### Example Output

![Output 1](./screenshots/output1.png)
![Output 2](./screenshots/output2.png)
