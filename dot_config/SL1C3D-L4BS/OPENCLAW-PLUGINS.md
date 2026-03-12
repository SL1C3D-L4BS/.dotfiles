# OpenClaw plugins and hooks (SL1C3D-L4BS)

OpenClaw supports **plugins** that run at lifecycle points in the agent loop. Plugin dir: `~/.openclaw/plugins/`.

## Hook points

- **session_start** / **session_end** — session boundaries; use to log or sync memory.
- **before_tool_call** / **after_tool_call** — intercept tool params/results.
- **message_received** / **message_sent** — message lifecycle.
- **agent_end** — after the agent loop completes; use to update memory.md or daily log.
- **agent:bootstrap** (gateway hook) — add/remove context before system prompt.

See [OpenClaw Plugins](https://docs.openclaw.ai/plugin) for the API and registration.

## Minimal session_start example

Create a plugin that appends a line to a workspace log when a session starts:

1. Create `~/.openclaw/plugins/` and add a plugin that registers `session_start`.
2. In the hook, write a timestamp line to e.g. `~/.openclaw/workspace/session-log.txt`.

Example (conceptual; exact API depends on OpenClaw plugin format):

```javascript
// In your plugin's registration:
api.on('session_start', (ctx) => {
  const fs = require('fs');
  const logPath = require('path').join(process.env.HOME, '.openclaw/workspace/session-log.txt');
  fs.appendFileSync(logPath, new Date().toISOString() + ' session_start\n');
});
```

Refer to the official OpenClaw plugin docs for the current plugin layout and `api.on()` usage.
