# Contributing

Thanks for considering a contribution. `coe` is solo-maintained. The
contribution model reflects that.

## Filing an issue

Use one of the [issue templates](./.github/ISSUE_TEMPLATE):
- **Bug** — something's broken
- **Feature request** — something should exist
- **Question** — anything else

Blank issues are disabled by design.

## Opening a PR

1. Open an issue first. We agree on the change before code is written.
2. One concern per PR. Small + reviewable beats large + monolithic.
3. Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`,
   `ci:`, `test:`. Subject ≤ 70 chars.
4. No `Co-Authored-By` trailers.
5. `CHANGELOG.md` updates are automatic — release-please handles versioning
   from conventional commits.

## Coding conventions

- Shell scripts stay `shellcheck`-clean (`shellcheck plugins/coe/scripts/*.sh`).
- Build hook JSON with `jq -n`, never string interpolation.
- Run `bash plugins/coe/scripts/test-coe-nudge.sh` after any change to a
  script — it must stay green.
- Plugin files reference scripts via `${CLAUDE_PLUGIN_ROOT}/...`.

## Running locally

The nudge test suite is the fast feedback loop:

```bash
bash plugins/coe/scripts/test-coe-nudge.sh
```

## Secret scanning

This repo runs [gitleaks](https://github.com/gitleaks/gitleaks) to keep secrets
out of the codebase, on two layers:

- **CI (blocking):** the `Security` workflow scans every push to `main` and every
  PR. A finding fails the check — secrets must be removed and rotated, never
  ignored.
- **Local pre-commit hook (optional, recommended):** scans your staged diff
  before each commit, so a secret never reaches a commit in the first place.

Enable the local hook once per clone:

```bash
brew install prek gitleaks   # or any prek install method (cargo, uv, npm, …)
prek install                 # writes .git/hooks/pre-commit
```

[prek](https://github.com/j178/prek) is a single-binary, Python-free runner for
the standard `.pre-commit-config.yaml`. Classic `pre-commit` also works.
