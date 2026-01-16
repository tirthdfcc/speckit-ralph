# Ralph Loop (Codex & Claude Code) for TGScanner

This folder provides a Ralph-style loop tailored to the speckit workflow with support for both:

- **Codex CLI** (optimized for CI/CD automation)
- **Claude Code CLI** (interactive development with full context)

It reads the current spec, plan, and tasks, then iterates on ONE task per loop.

## Prerequisites

- Spec + plan + tasks exist under `specs/<feature>/` (generated via speckit).
- **Either**:
  - Codex CLI installed (`codex exec`) - for automation
  - Claude Code CLI installed (`claude`) - for development
- Optional: `gh` CLI configured for GitHub integration.

## Files

### Core Infrastructure

- `ralph-env.sh` - Resolve feature paths via `.specify/scripts/bash/common.sh`
- `build-prompt.sh` - Build a prompt from `prompt-template.md`
- `prompt-template.md` - Prompt template used for each iteration

### Codex Scripts (CI/CD Automation)

- `ralph-once-codex.sh` - Run a single iteration with Codex
- `afk-ralph-codex.sh` - Run multiple iterations (AFK mode) with Codex

### Claude Code Scripts (Interactive Development)

- `ralph-once-claude.sh` - Run a single iteration with Claude Code
- `afk-ralph-claude.sh` - Run multiple iterations (AFK mode) with Claude Code

## Quickstart

### Using Codex (HITL)

```bash
scripts/ralph/ralph-once-codex.sh
```

### Using Claude Code (Interactive)

```bash
scripts/ralph/ralph-once-claude.sh
```

## AFK Loop

### With Codex

```bash
scripts/ralph/afk-ralph-codex.sh 10
```

### With Claude Code

```bash
scripts/ralph/afk-ralph-claude.sh 10
```

## AFK Loop (Detached)

### With Codex

Run in background so it keeps going after the terminal closes:

```bash
scripts/ralph/afk-ralph-codex.sh --detach 10
```

Optional log and pid paths:

```bash
scripts/ralph/afk-ralph-codex.sh --detach --log logs/ralph-afk.log --pid logs/ralph-afk.pid 10
```

Stop the detached loop:

```bash
kill "$(cat logs/ralph-afk.pid)"
```

### With Claude Code

Run in background:

```bash
scripts/ralph/afk-ralph-claude.sh --detach 25
```

Monitor progress:

```bash
tail -f logs/ralph-claude-*.log
```

Stop the detached loop:

```bash
kill "$(cat logs/ralph-claude.pid)"
```

## Progress Tracking

A progress log is created per feature at:

```
specs/<feature>/progress.txt
```

Each iteration appends a short entry after completing a task.

## Feature Selection

By default, the current git branch determines the spec directory.
To override, set:

```bash
export SPECIFY_FEATURE=003-audit-fixes
```

## Environment Variables

### Common Variables (Both Codex & Claude Code)

- `RALPH_PROMISE` - Completion token (default: COMPLETE)
- `RALPH_PROGRESS_FILE` - Override progress file path
- `RALPH_ARTIFACT_DIR` - Keep prompt + output artifacts
- `RALPH_SLEEP_SECONDS` - Sleep between AFK iterations (default: 1 for Codex, 2 for Claude)
- `RALPH_SKIP_BRANCH_CHECK` - Skip feature branch validation (set to 1)

### Codex-Specific Variables

- `CODEX_BIN` - Codex binary (default: codex)
- `CODEX_SANDBOX` - Sandbox policy (default: workspace-write)
- `CODEX_APPROVAL_POLICY` - Approval policy (default: never)
- `CODEX_EXTRA_ARGS` - Extra CLI args for `codex exec`

### Claude Code-Specific Variables

- `CLAUDE_BIN` - Claude CLI binary (default: claude)
- `CLAUDE_EXTRA_ARGS` - Extra CLI args for `claude` (e.g., "--model opus")

## GitHub Integration (Optional)

If you set these in your environment, the prompt instructs Codex to use `gh`:

- `RALPH_GH_ISSUE` Issue number to comment on
- `RALPH_GH_CREATE_PR` Set to `1` to open a PR at the end of an iteration

## Notes

- One task per iteration. Commit after each task.
- Feedback loops are enforced in the prompt:
  - `ruff check .`
  - `ruff format --check .`
  - `pytest` (smallest relevant scope)

## Codex vs Claude Code: When to Use Which?

| Aspect        | Codex                                  | Claude Code                                |
| ------------- | -------------------------------------- | ------------------------------------------ |
| **Speed**     | Faster (optimized for automation)      | Slower (API rate limits)                   |
| **Context**   | Each iteration is independent          | Full session context preserved             |
| **Debugging** | Limited visibility                     | Full conversational debugging              |
| **Cost**      | By execution time                      | By API tokens                              |
| **Use Case**  | CI/CD pipelines, production automation | Interactive development, exploration       |
| **Best For**  | Executing well-defined tasks           | Complex problem-solving, learning codebase |

**Recommendation:**

- Use **Claude Code** for initial development and debugging
- Use **Codex** for production automation and CI/CD pipelines
