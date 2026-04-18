# Knowledge Base Version

- **Knowledge base version**: 1.3.0
- **Last update**: 2026-04-18
- **Claude Code baseline**: Sonnet 4.6 / Opus 4.7 (1M context)
- **Source**: Derivative commentary based on [Claude Code documentation](https://docs.claude.com/en/docs/claude-code). Each `knowledge/NN-*.md` file carries a top-of-file `Source:` comment mapping to the relevant documentation section.
- **Sections**: 14 files (`00-overview.md` through `13-strict-coding-workflow.md`)

Plugin release versioning is tracked separately in `.claude-plugin/plugin.json` and (once published) in `CHANGELOG.md`. This file documents only the knowledge base content.

## Update protocol

1. Update the relevant `knowledge/NN-*.md` file and its top-of-file Source comment if the documentation section changes.
2. Bump the version above and update the Last update date.
3. Mirror substantive changes in `CHANGELOG.md` under the next plugin release.
