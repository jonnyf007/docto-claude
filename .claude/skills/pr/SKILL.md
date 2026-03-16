# /pr — Create Pull Request

Review the current branch diff and create a GitHub PR.

## Usage

```
/pr
```

## Steps

1. **Gather info:**
   ```bash
   git branch --show-current
   git diff main...HEAD --stat
   git log main..HEAD --oneline
   ```

2. **Check conventions** from the loaded CLAUDE.md:
   - Controllers are thin (just catchAsync + service call)
   - No logic leaking into controllers or routes
   - Error handling uses `throw new ApiError(...)` not `res.status(500)`
   - No raw `console.log` — use Winston logger
   - Joi validation in `src/validations/` for new endpoints
   - No mocked DB in integration tests

3. **Flag any issues** found in the diff — list them briefly. Don't block the PR for minor style, only for real problems.

4. **Draft PR:**
   - **Title:** `<type>: <short description>` (e.g. `feat: add inbound email reply to chat`)
     - Types: `feat`, `fix`, `chore`, `refactor`, `docs`
     - Keep under 70 characters
   - **Body:**
     ```
     ## What
     <1-3 bullet points describing what changed>

     ## Why
     <1-2 sentences on motivation>

     ## Test plan
     - [ ] Deployed to staging
     - [ ] <specific thing to verify>
     - [ ] <specific thing to verify>
     ```

5. **Confirm with user:** show the draft title + body, ask "Looks good to create the PR?"

6. **On confirmation:**
   ```bash
   gh pr create --title "..." --body "..." --base main
   ```

7. Output the PR URL.

## Notes

- Always target `main` as the base branch
- If the branch isn't pushed yet, push it first: `git push -u origin <branch>`
- Don't add co-author lines unless the user asks
