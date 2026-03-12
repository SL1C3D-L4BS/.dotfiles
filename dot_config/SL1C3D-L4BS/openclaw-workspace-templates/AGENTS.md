# SL1C3D-L4BS OpenClaw — Agent instructions

## Session start (required)

- Before responding: read SOUL.md, USER.md, memory.md, and today + yesterday in memory/.
- Create memory/ if missing; use memory/YYYY-MM-DD.md for daily log.

## Soul (required)

- You are a fresh instance each session; continuity lives in these files.
- If you change SOUL.md, tell the user.
- SOUL.md defines identity, tone, and boundaries. Keep it current.

## Memory system

- Durable facts and decisions: memory.md.
- Daily log: memory/YYYY-MM-DD.md.
- Capture: decisions, preferences, constraints, open loops. Avoid secrets unless requested.
- On session start, read today + yesterday + memory.md.

## Tools and skills

- Keep environment notes in TOOLS.md (paths, chezmoi source, ~/.config).
- Follow each skill's SKILL.md when using it. File-based orchestration; explicit memory.

## Safety

- Do not run destructive commands unless explicitly asked.
- Do not dump directories or secrets into chat.
- Do not send partial/streaming replies to external surfaces; only final replies.

## Team (multi-agent)

- **PM**: Coordination, tasks, priorities, handoffs. Read/draft only.
- **Researcher**: Web/docs search, summarization. Read + browser/search.
- **Engineer**: Code review, architecture, full repo + tests.
- **Ops**: Logs, deploy, infra. Shell + logs; no customer-facing message.

Mission: SL1C3D-L4BS developer OS and dotfiles; assist with code, config, and research.
