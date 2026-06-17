# coe

[![Ko-fi](https://img.shields.io/badge/Ko--fi-support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/qdelettre)

A Claude Code plugin marketplace whose `coe` plugin runs a **Correction-of-Errors retrospective** at the end of medium-to-big sessions and proposes systemic self-improvements — rules, memories, skills, hooks, settings.

## How it works

1. A `Stop` hook (`coe-nudge.sh`, pure shell, zero LLM tokens) detects a medium-to-big session and suggests running `/coe` — once per session.
2. `/coe` delegates transcript analysis to the bundled `coe-analyst` subagent, runs a confidence-gated confirm (or interviews you when the transcript is sparse), performs a blameless 5-whys, and writes a **propose-only** COE document to `docs/coe/`.
3. You review the proposed action items and apply the ones you want. The skill never edits your config.

Analyst findings are written to `${TMPDIR:-/tmp}/coe-findings/<slug>/` as per-transcript `.json` (+ optional `.md`) files and kept as an audit trail; the skill merges from those files, never from chat output.

## Install

Add this marketplace and install the `coe` plugin via Claude Code's plugin commands.

## Layout

- `plugins/coe/skills/coe/SKILL.md` — the skill
- `plugins/coe/agents/coe-analyst.md` — the analysis subagent (`coe:coe-analyst`)
- `plugins/coe/scripts/coe-nudge.sh` — the Stop-hook nudge
- `plugins/coe/commands/coe.md` — the `/coe` command
- `plugins/coe/hooks/hooks.json` — Stop-hook registration

## Action-item tags

`[RULE]` `[MEMORY]` `[SKILL]` `[HOOK]` `[SETTING]` `[CLAUDE.md]` `[PROCESS]` `[TEST]` `[LINT]` `[CI]`

## Learn more about COE

Correction of Errors is Amazon's blameless, mechanisms-over-blame root-cause practice. Good starting points:

- [Why you should develop a correction of error (COE)](https://aws.amazon.com/blogs/mt/why-you-should-develop-a-correction-of-error-coe) — AWS Cloud Operations Blog, the introductory post.
- [Creating a correction of errors document](https://aws.amazon.com/blogs/mt/creating-a-correction-of-errors-document/) — AWS Cloud Operations Blog, a walkthrough of the document sections (summary, timeline, 5 whys, action items).
- [Amazon's approach to failing successfully](https://aws.amazon.com/builders-library/amazon-approach-to-failing-successfully/) — Amazon Builders' Library, on postmortems that drive real improvement.

## Acknowledgments

The COE concepts here were inspired by two prior Claude skills, built fresh rather than copied:

- [robisson/build-like-amazon-agent-skills](https://github.com/robisson/build-like-amazon-agent-skills) (MIT) — blameless 5-whys and mechanisms-over-promises framing.
- [rot13maxi/agent-post-mortem](https://github.com/rot13maxi/agent-post-mortem) — skill packaging, the interview phase, and typed action items.

The novel twist this plugin adds: a session-end retrospective that runs **even on success**, targeting Claude Code's own configuration (rules, memories, skills, hooks, settings) rather than production incidents only.

## License

Apache-2.0. See [LICENSE](LICENSE).
