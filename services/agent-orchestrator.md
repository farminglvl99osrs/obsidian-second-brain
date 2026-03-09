---
type: service
status: active
repo: https://github.com/ComposioHQ/agent-orchestrator
owner: staffdill
tags: [ai, orchestration, typescript, cli, agents]
last_updated: 2026-03-06
---

# agent-orchestrator

## Overview

Open-source system for orchestrating fleets of parallel AI coding agents. Each agent works in an isolated git worktree on its own branch/PR. The orchestrator manages session lifecycle, auto-handles CI failures and review comments, and only notifies the human when judgment is genuinely needed. Core principle: **push, not pull** — spawn agents and walk away.

## Tech Stack

- Language / framework: TypeScript (ESM, strict mode), Node.js 20+
- Package manager: pnpm 9 (workspaces)
- Web framework: Next.js 15 (App Router) + Tailwind CSS 4
- CLI framework: Commander.js 13
- Config: YAML + Zod validation
- Real-time: SSE + WebSocket (xterm.js / node-pty)
- Storage: Flat key=value metadata files + JSONL event log (no database)
- Testing: vitest (3,288 test cases)
- Database: None (stateless, flat files in `~/.agent-orchestrator/`)

## Package Structure

```
packages/
  core/       @composio/ao-core       — types, config, session manager, lifecycle, event bus
  cli/        @composio/ao-cli        — the `ao` CLI command
  web/        @composio/ao-web        — Next.js dashboard (port 3000)
  plugins/
    runtime-{tmux,process}
    agent-{claude-code,codex,aider,opencode}
    workspace-{worktree,clone}
    tracker-{github,linear}
    scm-github
    notifier-{desktop,slack,composio,webhook}
    terminal-{iterm2,web}
```

## Key Endpoints / Interfaces

**Web API (Next.js App Router):**
- `GET /api/sessions` — list sessions
- `GET/PATCH /api/sessions/[id]` — session detail/update
- `POST /api/spawn` — spawn a new agent session
- `GET /api/prs` — PR state
- `GET /api/events` — SSE event stream

**CLI commands:**
- `ao status` / `ao spawn` / `ao send` / `ao session ls|kill|restore`
- `ao dashboard` / `ao start` / `ao init --auto`

**8 Plugin interfaces** defined in `packages/core/src/types.ts`: Runtime, Agent, Workspace, Tracker, SCM, Notifier, Terminal, Lifecycle

## Relationships

- Used by [[three-sword-style-ai]] for managing development agents
- Integrates with GitHub SCM (PRs, CI, reviews via `gh` CLI)
- Integrates with Linear for issue tracking
- Notifies via desktop, Slack, Composio, webhook

## Architecture Decisions

- **Stateless orchestrator** — no database; flat metadata files + JSONL event log
- **Hash-based project isolation** — `SHA256(configDir)[:12]-{projectId}` namespace
- **Plugin system** — every abstraction is a swappable TypeScript interface
- **Push, not pull** — Notifier is the primary human interface; dashboard is secondary
- **Two-tier event handling** — auto-handle routine issues; escalate only when judgment needed

## Operational Notes

- **Prerequisites:** Node.js 20+, Git 2.25+, tmux, `gh` CLI
- **Config:** `agent-orchestrator.yaml` in working directory (Zod-validated)
- **Data dir:** `~/.agent-orchestrator/{hash}-{projectId}/`
- **Dev workflow:** `pnpm install && pnpm build` before `pnpm dev`
- **Dashboard:** `http://localhost:3000`
- **Local path:** `~/Documents/github/agent-orchestrator`
