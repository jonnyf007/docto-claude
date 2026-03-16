# docto-claude

Shared Claude context and skills for the Docto development team.

## What's in here

- `CLAUDE.md` — parent context loaded by Claude in all Docto repos
- `.claude/skills/` — shared Claude skills (`/ticket`, `/deploy`, `/pr`, `/update-context`)
- `docto.code-workspace` — multi-root VS Code / Cursor workspace
- `setup.sh` — one-command setup for new devs

## Setup (new dev)

```bash
cd ~/Documents/projects/docto
git clone git@github.com:jonnyf007/docto-claude.git
cd docto-claude
./setup.sh
```

Then open the workspace:
```bash
cursor docto.code-workspace   # or: code docto.code-workspace
```

## Adding a new skill

1. Create `docto-claude/.claude/skills/<name>/SKILL.md`
2. Commit + push to this repo
3. Run `cp -r .claude/skills/<name> ~/.claude/skills/` (or re-run `setup.sh`)

## Structure

```
~/Documents/projects/docto/
├── CLAUDE.md                   ← symlink → docto-claude/CLAUDE.md
├── docto-claude/               ← this repo
├── docto-api/
│   ├── CLAUDE.md               ← API-specific context
│   └── scheduled_tasks/
│       └── CLAUDE.md           ← Lambda-specific context
├── docto-app/
│   └── CLAUDE.md               ← React app context
└── docto-nextjs/
    └── CLAUDE.md               ← Next.js site context
```

Claude loads context hierarchically — working in `scheduled_tasks/` loads all three CLAUDE.md files.
