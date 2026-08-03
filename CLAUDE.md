# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

claude-statusline is an npm package (`@zynoo/claude-statusline`), forked from `@kamranahmedse/claude-statusline`, that provides a custom status line for Claude Code CLI. It displays model info, context window usage, rate limits, directory/git branch, session duration, and effort level.

## Installation & Testing

```bash
# Run via bunx (configured in Claude Code settings.json)
bunx @zynoo/claude-statusline

# With all options
bunx @zynoo/claude-statusline --bar-style shade --usage-style compact
```

There are no automated tests or linting. Testing is manual — install the statusline and verify it renders correctly in Claude Code.

**Requirements**: jq, git must be installed on the system.

## Architecture

Two files do all the work:

- **`bin/install.js`** — Node.js CLI entry point. Passes CLI arguments through to the shell script.

- **`bin/statusline.sh`** — Bash script that Claude Code invokes. Reads JSON context from stdin (model, tokens, session info, rate limits) and outputs a colored status display. No network calls — all data comes from stdin.

### Data Flow

1. Claude Code pipes JSON context to `statusline.sh` via stdin (includes `rate_limits.{five_hour,seven_day}.{used_percentage,resets_at}`)
2. Script extracts model name, context usage, cwd, session start time, rate limits
3. Git branch/dirty state detected if in a repo
4. Effort level read from the transcript JSONL (see below), fallback to settings.json
5. Formatted output with Catppuccin Mocha ANSI colors rendered to stdout

### Effort Detection

Two signals, both parsed with jq so the same strings quoted inside tool output can't spoof them:

1. **`.effort` on assistant records** (`low`/`medium`/`high`/`xhigh`/`max`) — Claude Code stamps this on every assistant turn, so the last 200 lines always carry the current value.
2. **`/effort` command output** — `ultracode` never appears in `.effort` (it is xhigh + orchestration, so the field reports `xhigh`). Only checked when the level is `xhigh`/empty: a `grep -F` narrows the whole file to candidate lines, then jq confirms the record really is command output. Full-file scan because the marker is usually set once at session start and scrolls out of any tail window.

### Status Line Output

- **Default mode**: Line 1 (model, context %, dir, branch, session, effort) + multi-line rate limits
- **Compact mode** (`--usage-style compact`): Line 1 + single-line usage with remaining time
- **Minimal mode** (`--minimal`): single line — model, context %, effort. Exits before any cwd/git/session/rate-limit work

### CLI Arguments

- `--bar-style <style>` — Bar character style: `diamond` (default), `block`, `dot`, `arrow`, `square`, `shade`
- `--usage-style <style>` — Usage layout: `default` (multi-line) or `compact` (single-line)
- `--time-style <style>` — Time format: `remaining` (default, e.g. `1h·4m left`) or `absolute` (e.g. `12:00am`)
- `--minimal` — Single line with model, context % and effort only; no rate limits, dir, branch or session

Unknown arguments are ignored, so stale configs (e.g. the pre-1.7.0 `--cache-ttl 300`) keep working.

### Environment Variables

CLI arguments take priority over environment variables:

- `CLAUDE_STATUSLINE_BAR_STYLE` — Same as `--bar-style`
- `CLAUDE_STATUSLINE_USAGE_STYLE` — Same as `--usage-style`
- `CLAUDE_STATUSLINE_TIME_STYLE` — Same as `--time-style`
- `CLAUDE_STATUSLINE_MINIMAL` — Any non-empty value enables `--minimal`
