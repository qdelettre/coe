---
name: coe
description: Use when wrapping up a medium-to-big Claude Code session or task, or when the user asks to capture learnings / run a retrospective / post-mortem / COE, to propose systemic self-improvements (rules, memories, skills, hooks, settings).
---

# Correction of Errors (COE)

## Overview

Run a blameless retrospective at the end of a session and propose **mechanisms** — not intentions — that make a class of friction unable to recur. Targets Claude's own configuration: rules, memories, skills, hooks, settings.

**Core principle:** Reject "be more careful" as a conclusion. Every action item names a mechanism (a rule file, a memory entry, a skill, a hook) or it is not an action item.

**Runs on success too.** This is not failure-only. A session with zero failures still has frictions (repeated manual steps, missed skills) worth a mechanism.

**Single vs combined.** The Stop-hook nudge covers the single-session case only — one transcript, the session that just ended. A combined COE across multiple sessions is invoked manually with the transcript paths (or by asking to review the last N sessions).

## Workflow

1. **Resolve transcript(s).** Two modes:
   - **Single-session** (default — e.g. hook-triggered): use the `transcript_path` from the nudge context if present. Otherwise find the current session's `.jsonl` under `~/.claude/projects/` (the newest by modification time whose path matches the current project directory). If none, ask the user for the path.
   - **Combined**: when given multiple transcript paths, or asked to review the last N sessions, collect all of them.
2. **Delegate analysis (fan out).** First create a per-run handoff dir `${TMPDIR:-/tmp}/coe-findings/<slug>/` (where `<slug>` is the COE topic slug) and assign each transcript a base path `<dir>/NN-<transcript-basename>` (NN = 01, 02, …). Dispatch one `coe:coe-analyst` subagent per transcript (use the plugin-namespaced id `coe:coe-analyst` — the bare `coe-analyst` fails with "Agent type not found", since plugin agents register as `<plugin>:<agent>`), passing the transcript path, a one-line topic seed, AND the assigned `output_path` (the base path, no extension). Each analyst writes its findings to `<output_path>.json` (and optionally `<output_path>.md`) and returns only a confirmation line.
3. **Collect findings from files.** Read each assigned `<base>.json` from disk to obtain that transcript's findings (frictions, incidents, what_worked, confidence; each friction/incident carries a `severity` of `low|med|high`) — do NOT parse the analyst's chat message. If a `<base>.json` is missing or does not parse, flag that transcript as low-signal and continue; never fail the whole run on one missing file.
4. **Merge (combined mode only).** Cluster the findings collected from the files by theme across transcripts; dedup recurrences. Treat cross-session recurrence as a severity multiplier (a friction that recurs in multiple sessions escalates). Carry each transcript's confidence forward for the branch below. Single-session runs skip this step.
5. **Branch on confidence:**
   - **Single-session:** `confidence >= 0.4` → proceed. `confidence < 0.4` → **interview hatch**: ask the user, in order: what went wrong, how it was discovered, how it was resolved. Use the answers as the findings.
   - **Combined:** proceed if the **median** confidence across transcripts is `>= 0.4`. Flag any individual transcript with `confidence < 0.4` as low-signal *for that session* (do not interview for the whole set). Trigger the interview hatch only if the median is `< 0.4`.
6. **Brief-confirm (interactive runs only).** Present the 1–3 most material frictions/incidents and ask which to include and their severity (use AskUserQuestion). **Non-interactive mode:** when run headless (`claude -p`), Stop-hook-driven, or when told to run autonomously, SKIP AskUserQuestion entirely — auto-include the top items by severity and use the analyst's severity calls. Never block an unattended run on a prompt.
7. **5-whys per selected item.** Drill from impact to a systemic cause. Stop at a systemic cause, never at "Claude/the user should have been more careful."
8. **Write the COE document.** Default path is `docs/coe/YYYY-MM-DD-<slug>.md` in the current project, where `<slug>` is a short kebab-case form of the session topic (see structure below). Accept an explicit output path when one is provided (a combined / cross-project run may target `/tmp/...`); a combined run with no single "current project" MUST be given an explicit path. Propose-only — do NOT modify any `~/.claude` file, `settings.json`, rule, or memory. Name the handoff dir `${TMPDIR:-/tmp}/coe-findings/<slug>/` in the final summary so the user can inspect the per-transcript `.json`/`.md` audit files (kept, not cleaned up).
9. **Print the action-item summary** to chat so the user sees the proposed mechanisms without opening the file.

## COE Document Structure

```
# COE — <topic> — YYYY-MM-DD
1. Summary             — what the session did + outcome
2. What Worked         — keep-doing
3. Frictions/Incidents — each: what happened, how surfaced
4. Root Cause (5 Whys) — per item, stops at a systemic cause
5. Action Items        — each: owner, target, concrete mechanism, tagged per the taxonomy below
6. Lessons Learned
```

## Action-Item Taxonomy

Tag every action item by its target:

| Tag | Target |
|-----|--------|
| `[RULE]` | `~/.claude/rules/*.md` |
| `[MEMORY]` | `MEMORY.md` + memory file |
| `[SKILL]` | new/edited skill |
| `[HOOK]` | `settings.json` hook |
| `[SETTING]` | `settings.json` perms/env |
| `[CLAUDE.md]` | project `CLAUDE.md` |
| `[PROCESS]` | workflow change (no config) |
| `[TEST]` `[LINT]` `[CI]` | mechanism living in project code |

Each item MUST state a mechanism: "add a rule that X", not "remember to X".

## Red Flags — STOP if you catch yourself

- Concluding "be more careful" / "add more tests" with no mechanism
- Skipping the analyst and summarizing the session inline yourself
- Parsing analyst findings out of its chat message instead of reading the assigned `<base>.json` file
- Skipping categorization tags
- Stopping the 5-whys at the first cause
- Treating a successful session as having nothing to improve
- Writing to `~/.claude`, a rule, a memory, or `settings.json` (this skill is propose-only)
- Using the bare `coe-analyst` id instead of `coe:coe-analyst` (the bare id fails with "Agent type not found")
- Blocking an unattended or headless run on AskUserQuestion

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Session was fine, nothing to capture" | Frictions exist in successful sessions. Run the analyst. |
| "I already know what went wrong, skip the agent" | The analyst reads the full transcript; you hold a lossy summary. Delegate. |
| "I'll just remember to do better" | Intention, not mechanism. Rejected. Name a rule/hook/skill. |
| "Too small to bother" | The nudge already judged it medium-to-big. Proceed. |
| "Let me also apply the fix" | Propose-only. Applying config is a separate, user-approved step. |
| "Headless run, I'll just ask anyway" | Non-interactive mode: never block on a prompt; auto-include by severity. |
