# Security Audit Checklist

## Permissions Audit

### CRITICAL — Block if found in allow
- `Bash(*)` — allows ALL bash commands
- `Bash(sudo *)` — allows all superuser commands
- `Bash(rm -rf *)` — allows recursive deletion
- `Bash(curl * | bash)` — allows pipe-to-bash execution

### HIGH — Warn and ask user to confirm
- `Bash(sudo apt-get:*)` — package installation as root
- `Bash(sudo rm:*)` — deletion as root (any form)
- `Bash(git push --force *)` — force push
- `Bash(git reset --hard *)` — hard reset
- `Bash(npm install *)` without deny counterpart — dependency installation
- `Bash(chmod 777 *)` — world-writable permissions

### Required deny list (MUST be present)
```json
"deny": [
  "Bash(rm -rf /)",
  "Bash(sudo rm *)",
  "Bash(git push --force *)"
]
```

## Secret Detection Patterns

Scan generated env values for:
- `sk-` — OpenAI/Anthropic API keys
- `ghp_` — GitHub personal access tokens
- `AKIA` — AWS access key IDs
- `xoxb-` — Slack bot tokens
- `Bearer ` — Bearer tokens
- Any string longer than 30 chars that looks like a token

If found: move to settings.local.json (gitignored), never settings.json.

## File Access Audit

Verify generated files don't grant access to:
- `/etc/` system directories
- `~/.ssh/` SSH keys
- `~/.aws/` AWS credentials
- Other users' home directories
