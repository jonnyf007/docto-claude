# /pr — Create Pull Request

Review the current branch diff and create a GitHub PR, then notify the Trello card.

## Usage

```
/pr
```

## Steps

1. **Gather info:**
   ```bash
   git branch --show-current
   git diff staging...HEAD --stat
   git log staging..HEAD --oneline
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
   - If the branch isn't pushed yet, push it first: `git push -u origin <branch>`
   - Create the PR:
     ```bash
     gh pr create --title "..." --body "..." --base staging
     ```

7. **Output the PR URL.**

8. **Post PR link to Trello** — if a Trello card ID is available from the current session (e.g. from `/ticket`), add a comment to the card using the Trello MCP tool:
   ```
   PR raised for this ticket: <pr-url>
   ```

## Notes

- Always target `staging` as the base branch (not `main`)
- Don't add co-author lines unless the user asks
