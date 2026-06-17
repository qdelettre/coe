# CLAUDE.md

Single-plugin marketplace. The plugin is `plugins/coe/` — it runs an end-of-session Correction-of-Errors (COE) retrospective and proposes self-improvements (rules, memories, skills, hooks, settings).

## Components

- `plugins/coe/skills/coe/SKILL.md` — the skill. Supports single-session and combined (multi-transcript) modes, plus a non-interactive mode for headless / Stop-hook-driven runs.
- `plugins/coe/agents/coe-analyst.md` — the analysis subagent, registered as `coe:coe-analyst`. Reads one transcript and writes structured findings to a file.
- `plugins/coe/scripts/coe-nudge.sh` — the Stop-hook nudge (pure shell, zero LLM tokens).
- `plugins/coe/commands/coe.md` — the `/coe` command.
- `plugins/coe/hooks/hooks.json` — registers the Stop hook.

## Foot-guns

- **Namespaced agent id.** The skill dispatches the analyst as `coe:coe-analyst`, never the bare `coe-analyst` (bare id fails with "Agent type not found").
- **File handoff, not chat.** Each `coe:coe-analyst` writes its findings as pure JSON to a skill-assigned `${TMPDIR:-/tmp}/coe-findings/<slug>/NN-<basename>.json`. The skill merges by reading those files — never by parsing the analyst's chat message. A missing/invalid file degrades to a low-signal flag, not a crash. Handoff files are kept as an audit trail.
- **Propose-only.** The skill must never write to `~/.claude`, `settings.json`, a rule, or a memory. Its only project-facing write is the COE doc (default `docs/coe/YYYY-MM-DD-<slug>.md`; the output path is parameterizable for combined / cross-project runs).
- **Non-interactive mode.** Headless (`claude -p`), Stop-hook-driven, or autonomous runs skip `AskUserQuestion` and auto-include top items by severity. Never block an unattended run on a prompt.
- **Nudge counts occurrences, not lines.** `coe-nudge.sh` must stay `shellcheck`-clean and build JSON with `jq -n` (never string interpolation); it counts `tool_use`/edit *occurrences* (`grep -o`), since parallel tool calls pack into one transcript line. Run `plugins/coe/scripts/test-coe-nudge.sh` after any change.
- **Hook scope.** The Stop-hook nudge covers the single-session case only and fires once per `session_id` (dedup marker). A combined COE across multiple sessions is invoked manually with the transcript paths.
- Plugin scripts are referenced via `${CLAUDE_PLUGIN_ROOT}/...`.

## Commit format

Conventional commits: `type(scope): description`. No `Co-Authored-By` trailers.
