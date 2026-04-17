# Changelog

All notable changes to `harness-architect` are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Phase 2.5 — Domain Research** (optional). A new agent `phase-domain-research` + playbook `playbooks/domain-research.md` collect industry-standard workflows, team roles, and tool stacks for the project's core domain, using a curated KB first and live web research as fallback.
- `knowledge/domains/` reference KB with 8 seed domains (5 full: deep-research, code-review, technical-docs, website-build, data-pipeline — and 3 stub: webtoon-production, youtube-content, marketing-campaign). Stub domains automatically trigger live search mode.
- `knowledge/domains/README.md` authoring contract: minimum 3 primary sources per full KB, stub/full quality frontmatter field.
- Phase 2.5 artifact: `docs/{요청명}/02b-domain-research.md` (file numbering preserves existing 02-07 chain — no cascade renumbering).
- Phase 3-6 playbooks (`workflow-design`, `pipeline-design`, `agent-team`, `skill-forge`) now optionally Read the Phase 2.5 artifact when present. Domain patterns are cited in downstream designs.
- Red-team Advisor (`playbooks/design-review.md`) gained a Dimension 6 for domain research consistency including source URL validation.
- `final-validation.md` Step 1 inventory + Step 3 consistency check now covers `02b-domain-research.md`.
- `.claude/settings.json` allows `WebSearch` and `WebFetch` so Phase 2.5 can run without permission prompts.

### Changed
- Domain identification is solicited via Phase 1-2 Escalation (`[ASK] 핵심 도메인 식별`) rather than Phase 0 AskUserQuestion, preserving the Phase 0 "≤4 questions" rule in `question-discipline.md`.
- Fast Track / Fast-Forward paths explicitly specify Phase 2.5 skip triggers ("해당 없음" answer, `--fast` keyword).

## [0.1.0] - 2026-04-17

Initial public release (soft launch).

### Added
- Plugin manifest (`.claude-plugin/plugin.json`) with custom component paths for `.claude/agents/`, `commands/`, and `.claude/hooks/hooks.json`.
- Self-hosted single-plugin marketplace (`.claude-plugin/marketplace.json`).
- Orchestrator slash command `/harness-architect:harness-setup` (entry point at `commands/harness-setup.md`).
- 8 Phase workers under `.claude/agents/`:
  `phase-setup`, `phase-workflow`, `phase-pipeline`, `phase-team`, `phase-skills`, `phase-hooks`, `phase-validate`, `red-team-advisor`.
- 11 playbooks under `playbooks/` (Agent-Playbook separation — HOW files, not exposed as Skills to the main session).
- 4 always-apply rules under `.claude/rules/`:
  `orchestrator-protocol`, `question-discipline`, `output-quality`, `meta-leakage-guard`.
- 2 plugin hooks under `.claude/hooks/`:
  `ownership-guard.sh` (PreToolUse Write/Edit — scope guard) and `syntax-check.sh` (PostToolUse Write/Edit — JSON/YAML validation).
- 14-file knowledge base under `knowledge/` (commentary derived from Claude Code documentation).
- 3 validation checklists under `checklists/`:
  `validation-checklist`, `security-audit`, `meta-leakage-keywords`.
- `strict-coding-6step` workflow preset under `.claude/templates/workflows/` for complex coding projects (8 agents + 8 playbooks).
- Documentation: `README.md` (Korean), `ARCHITECTURE.md`, `LICENSE` (Apache-2.0).

### Known limitations
- English README (`README_EN.md`) and `examples/` scenarios are incomplete in this release — see Unreleased.
- Submission to the official Anthropic plugin marketplace has not been completed; installation currently relies on GitHub-hosted marketplace path.

[Unreleased]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/leee880619-commits/ClaudeCode-Harness-Setup-Assistant/releases/tag/v0.1.0
