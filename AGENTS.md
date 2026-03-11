# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

Codex-statusline is an npm package (`@zynoo/Codex-statusline`), forked from `@kamranahmedse/Codex-statusline`, that provides a custom status line for Codex CLI. It displays model info, context window usage, rate limits, directory/git branch, session duration, and effort level.

## Installation & Testing

```bash
# Run via bunx (configured in Codex settings.json)
bunx @zynoo/Codex-statusline

# With custom cache TTL (default 120s)
bunx @zynoo/Codex-statusline --cache-ttl 300
```

There are no automated tests or linting. Testing is manual — install the statusline and verify it renders correctly in Codex.

**Requirements**: jq, curl, git must be installed on the system.

## Architecture

Two files do all the work:

- **`bin/install.js`** — Node.js CLI entry point. Passes CLI arguments (e.g. `--cache-ttl`) through to the shell script.

- **`bin/statusline.sh`** — Bash script that Codex invokes. Reads JSON context from stdin (model, tokens, session info), fetches rate limits from the Anthropic API (cached with configurable TTL in `/tmp/Codex/`), and outputs a colored multi-line status display.

### Data Flow

1. Codex pipes JSON context to `statusline.sh` via stdin
2. Script extracts model name, context usage, cwd, session start time
3. Git branch/dirty state detected if in a repo
4. OAuth token retrieved (env var → macOS Keychain → credentials file → Linux secret-tool)
5. Rate limit data fetched from API with file-based caching (default 120s, configurable via `--cache-ttl`)
6. Formatted output with ANSI colors rendered to stdout

### Status Line Output

- **Line 1**: Model name, context usage bar, directory + git branch, session duration, effort level
- **Lines 2-4**: Rate limit bars (current 5-hour, weekly 7-day, optional extra/pay-as-you-go) with reset times
