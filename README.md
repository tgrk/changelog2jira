# changelog2jira

Extracts JIRA IDs from CHANGELOG (using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with JIRA IDS, e.g. `feat(FOO-123): foobar`) and calls JIRA Webhook Automation rule. You can transition the JIRA issue to the released state. 

![alt text](docs/images/changelog2jira_settings.png?raw=true "JIRA Automation Rule Settings")

## Requirements

* Elixir 1.0+

## Usage

```shell
   export JIRA_WEBHOOK_URL=https://automation.atlassian.com/pro/hooks/secret
   elixir changelog2jira.exs --version=0.1.0 --path=../your/project
```

## Configuration

ENV variables:
 - `JIRA_WEBHOOK_URL` - your JIRA Automation rule Webhook URI

CLI arguments:
 - `version` - version you want to extract JIRA IDs
 - `path` - location of your project that includes CHANGELOG.md
