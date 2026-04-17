# harness-architect

[![ci](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/leee880619-commits/ClaudeCode-Harness-Setup-Assistant?include_prereleases&sort=semver)](https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases)
[![license](https://img.shields.io/github/license/leee880619-commits/ClaudeCode-Harness-Setup-Assistant)](./LICENSE)

> A meta-tool plugin for Claude Code that scans a project and builds a complete harness — CLAUDE.md, settings, rules, agents, playbooks, hooks, MCP — through a 9-phase orchestrated workflow.

> 🌐 Intro page: [harness-architect team guide](https://leee880619-commits.github.io/ClaudeCode-Harness-Setup-Assistant/) · 🇰🇷 Korean: [README.md](./README.md) · 🧭 Internals: [ARCHITECTURE.md](./ARCHITECTURE.md) · 📜 Changes: [CHANGELOG.md](./CHANGELOG.md)

## Why this exists

I'm not a developer. As I got into Claude Code and what I'd call *harness engineering* — stitching together CLAUDE.md, settings, rules, agents, hooks, and MCP to fit a specific project — I kept hitting the same friction: every new project meant redoing the same boilerplate setup, re-reading the same docs, and re-discovering the same mistakes.

"What rules do I need? Which permissions should I open? Which hooks? Does this project need an agent team or is a single skill enough?" — the same questions, every time.

This plugin is my attempt to collapse that loop. It draws from Claude Code's **official documentation** plus patterns that have worked in my own projects, then scans your target project, asks only the decisions that actually depend on you, and assembles the harness step by step.

## When to use it

- You want a **correct-from-day-one** Claude Code harness, not a bag of loose files.
- You want to cut the cognitive load of re-setting up Claude Code on every new project.
- You need more than an agent team — you need the **full harness** (settings + rules + agents + playbooks + hooks + MCP).
- You're working on a non-trivial project where an **independent red-team review** between design phases is worth the extra turn.

## Comparison with [revfactory/harness](https://github.com/revfactory/harness)

| Dimension | harness-architect (this plugin) | revfactory/harness |
|-----------|---------------------------------|--------------------|
| Scope | Full harness (settings/rules/agents/playbooks/hooks/MCP) | Agent + skill team focus |
| Input | Project-path scan + interactive interview | User-provided narrative |
| Workflow | 9-phase orchestration, Phase Gate, resume-on-crash | Single-conversation 6 steps |
| Design review | Red-team Advisor between phases | Not built in |
| Core pattern | Agent-Playbook separation (WHO/HOW), pure orchestrator | User-driven design |

**Positioning**: revfactory/harness is ideal when you want an agent/skill team *fast*. harness-architect is the one to reach for when you want a harness set up *properly, once*, with resumability and built-in review.

## Install

Run these slash commands inside a Claude Code session:

```
# 1) Register the marketplace (one-time)
/plugin marketplace add leee880619-commits/ClaudeCode-Harness-Setup-Assistant

# 2) Install the plugin
/plugin install harness-architect@harness-architect-marketplace
```

> Submission to the official Anthropic marketplace is in progress. Until then, use the GitHub-hosted path above.

### Developer setup (from source)

```bash
git clone https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant
cd ClaudeCode-Harness-Setup-Assistant
claude --plugin-dir .
```

## Usage

From **inside your target project** (not this repo), open Claude Code and run:

```
/harness-architect:harness-setup
```

The orchestrator starts at Phase 0 and advances through nine phases. Required decisions (project type, solo/team, hook scope, etc.) are collected via batched `AskUserQuestion` calls; settings, agents, playbooks, and hooks are written to your target project.

If the session is interrupted, state is persisted under `docs/{request-name}/` inside your target project and is resumed on the next invocation.

## Phases at a glance

| Phase | Responsibility | Agent |
|-------|----------------|-------|
| 0 | Collect target path, generate request name | (orchestrator) |
| 1-2 | Scan + interview + base harness | `phase-setup` |
| 3 | Workflow design (step sequence) | `phase-workflow` |
| 4 | Pipeline design (per-step execution chain) | `phase-pipeline` |
| 5 | Agent team assembly | `phase-team` |
| 6 | SKILL / playbook authoring | `phase-skills` |
| 7-8 | Hooks / MCP installation | `phase-hooks` |
| 9 | Final validation | `phase-validate` |
| every phase | Independent critical review | `red-team-advisor` |

Three **Phase 1-2 branches** handle the common cases:

- `fresh-setup` — brand-new project
- `cursor-migration` — convert a Cursor IDE config
- `harness-audit` — assess and improve an existing Claude Code setup

A `strict-coding-6step` preset (8 agents + 8 playbooks) is shipped under `.claude/templates/workflows/` and auto-copied for complex coding projects.

For the design philosophy, agent-playbook separation, escalation protocol, and red-team review details, read [ARCHITECTURE.md](./ARCHITECTURE.md).

## Guardrails

- **Target-project scope**: While building a harness for a target project, the plugin's own files are read-only. The `ownership-guard.sh` hook enforces this at `PreToolUse(Write|Edit)`.
- **Security**: Dangerous Bash patterns (`Bash(*)`, `sudo rm *`) are denied in the default settings template; secrets (API keys, tokens) are directed to gitignored `settings.local.json`.
- **No meta-leakage**: Generated files don't include this plugin's internal rules or Claude Code architecture notes. Enforced by `meta-leakage-guard` and the checklist under `checklists/meta-leakage-keywords.md`.

## Contributing

Issues and PRs are welcome. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a PR.

## Privacy

This plugin does not collect, store, or transmit any personal data. Full policy: [PRIVACY.md](./PRIVACY.md).

## License

[Apache-2.0](./LICENSE) · Copyright © 2026 leee880619-commits

`knowledge/*.md` contains derivative commentary based on Claude Code documentation at https://docs.claude.com/en/docs/claude-code. Each file carries a top-of-file `Source:` comment with the original section mapping.
