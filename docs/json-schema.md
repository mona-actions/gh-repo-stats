# gh-repo-stats JSON Schema Specification

This document defines the JSON output format produced by `gh-repo-stats --json`.

---

## Table of Contents

- [Top-Level Structure](#top-level-structure)
- [Repository Object](#repository-object-repos)
  - [Core Fields](#core-fields)
- [Example](#example)

---

## Top-Level Structure

```json
{
  "repos": []
}
```

| Field  | Type    | Required | Description                                                |
| ------ | ------- | -------- | ---------------------------------------------------------- |
| `repos`| `array` | ✅        | Array of [repository objects](#repository-object-repos)    |

---

## Repository Object (`repos[]`)

### Core Fields

| Field               | Type      | Description                                           |
| ------------------- | --------- | ----------------------------------------------------- |
| `org`               | `string`  | Organization name                                     |
| `name`              | `string`  | Repository name                                       |
| `url`               | `string`  | Repository URL                                        |
| `isFork`            | `boolean` | Whether the repository is a fork                      |
| `isArchived`        | `boolean` | Whether the repository is archived                    |
| `diskUsage`         | `number`  | Repository size in **KB**                             |
| `sizeMB`            | `number`  | Repository size in **MB**                             |
| `hasWikiEnabled`    | `boolean` | Whether the wiki is enabled                           |
| `createdAt`         | `string`  | ISO 8601 creation timestamp                           |
| `updatedAt`         | `string`  | ISO 8601 last update timestamp                        |
| `pushedAt`          | `string`  | ISO 8601 last push timestamp                          |
| `collaborators`     | `number`  | Number of collaborators                               |
| `branches`          | `number`  | Number of branches                                    |
| `tags`              | `number`  | Number of tags                                        |
| `branchProtections` | `number`  | Number of branch protection rules                     |
| `issues`            | `number`  | Total issue count                                     |
| `pullRequests`      | `number`  | Total pull request count                              |
| `milestones`        | `number`  | Number of milestones                                  |
| `releases`          | `number`  | Number of releases                                    |
| `projects`          | `number`  | Number of projects                                    |
| `discussions`       | `number`  | Number of discussions                                 |
| `commitComments`    | `number`  | Number of commit comments                             |
| `issueEvents`       | `number`  | Number of issue events                                |

All fields are always present in the output.

---

## Example

```json
{
  "repos": [
    {
      "org": "my-org",
      "name": "my-repo",
      "url": "https://github.com/my-org/my-repo",
      "isFork": false,
      "isArchived": false,
      "diskUsage": 51200,
      "sizeMB": 50,
      "hasWikiEnabled": false,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2025-06-01T14:00:00Z",
      "pushedAt": "2025-06-01T14:00:00Z",
      "collaborators": 12,
      "branches": 8,
      "tags": 15,
      "branchProtections": 2,
      "issues": 45,
      "pullRequests": 120,
      "milestones": 4,
      "releases": 12,
      "projects": 2,
      "discussions": 8,
      "commitComments": 5,
      "issueEvents": 350
    }
  ]
}
```
