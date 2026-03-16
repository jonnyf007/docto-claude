# /update-context — Update CLAUDE.md

Suggest updates to CLAUDE.md files based on recent changes in the repo.

## Usage

```
/update-context
```

## Steps

1. **Determine scope** — what CLAUDE.md files are relevant?
   - If in `scheduled_tasks/<lambda>/` → check `scheduled_tasks/CLAUDE.md` and `docto-api/CLAUDE.md`
   - If in `docto-api/src/` → check `docto-api/CLAUDE.md`
   - If in `docto-app/` → check `docto-app/CLAUDE.md`
   - If in `docto-nextjs/` → check `docto-nextjs/CLAUDE.md`
   - Always consider the parent `~/Documents/projects/docto/CLAUDE.md` for cross-repo changes

2. **Read recent commits:**
   ```bash
   git log --oneline -20
   git diff HEAD~5..HEAD --stat
   ```

3. **Read the relevant CLAUDE.md** file(s)

4. **Identify gaps** — what's in the recent commits that isn't in CLAUDE.md?
   - New Lambda functions added
   - New services or models
   - Changed deploy process
   - New environment variables or AWS resources
   - New patterns or conventions introduced

5. **Propose specific edits** — show the exact diff (old text → new text) for each suggested change. Be concise — CLAUDE.md files should stay short.

6. **Ask for confirmation** before writing anything.

7. **On confirmation**, write the changes to the CLAUDE.md file(s).

8. **Commit the changes** to `docto-claude` if the parent CLAUDE.md was updated:
   ```bash
   cd ~/Documents/projects/docto/docto-claude
   git add CLAUDE.md
   git commit -m "docs: update parent context - <brief description>"
   git push
   ```
   For repo-specific CLAUDE.md files, commit them in their own repo.

## Notes

- Keep CLAUDE.md files short — the goal is signal, not documentation
- Don't duplicate info already in code or git history
- If a Lambda was renamed or removed, update the table in `scheduled_tasks/CLAUDE.md`
- The parent CLAUDE.md lives in `docto-claude/` repo — changes there need to be pushed separately

## Adding a new skill

If you or a dev has created a new useful skill:
1. Create `docto-claude/.claude/skills/<name>/SKILL.md`
2. Commit to `docto-claude` and push
3. Other devs run: `cp -r ~/Documents/projects/docto/docto-claude/.claude/skills/<name> ~/.claude/skills/`
   Or re-run `setup.sh` to get all skills
