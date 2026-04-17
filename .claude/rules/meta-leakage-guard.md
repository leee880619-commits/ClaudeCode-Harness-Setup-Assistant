# Meta-Leakage Guard

## The Problem
This tool is a Claude Code project that generates Claude Code projects.
There is a critical risk of the tool's own behavioral instructions
contaminating the generated output files.

## Forbidden Content in Generated Files

Generated CLAUDE.md and rules MUST NOT contain ANY of these:
- This tool's behavioral rules ("ask everything", "assume nothing")
- Claude Code architecture explanations (4-Tier scope, composition rules)
- References to this tool ("Harness Setup Assistant", "setup agent")
- Meta-instructions ("question-discipline", "progressive disclosure")
- Phrases: "질문을 먼저", "가정하지 마세요", "하네스 에이전트"

## What Generated Files SHOULD Contain

Generated CLAUDE.md should contain:
- The TARGET project's identity and purpose
- The TARGET project's tech stack
- The TARGET project's development principles (from user's answers)
- The TARGET project's specific conventions
- References to the TARGET project's own documents (@import)

Generated rules should contain:
- Rules specific to the TARGET project's needs
- Not generic Claude Code usage instructions

## Self-Check

Before writing any generated file, verify:
1. Does this file make sense for someone who has never seen this tool?
2. Would a developer reading this CLAUDE.md understand their project better?
3. Is there ANY content that only makes sense in the context of "setting up a harness"?
   If yes → REMOVE IT.
