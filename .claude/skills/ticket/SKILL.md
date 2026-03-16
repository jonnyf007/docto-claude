# /ticket — Trello Card → Branch

Fetch a Trello card and turn it into an actionable development task.

## Usage

```
/ticket [trello-url]
```

If no URL is provided, ask the user to paste the Trello card URL.

## Steps

1. **Fetch the card** using the Trello MCP tool:
   - Get title, description, checklist items, and comments
   - Get the card's list name (e.g. "In Progress", "To Do")

2. **Assess completeness** — does the card have enough context to start work?
   - Enough: clear acceptance criteria, known affected repo(s), no ambiguous requirements
   - Not enough: vague description, missing UI specs, unclear scope, dependencies not mentioned

3. **If NOT enough context**, output a message the dev can paste to the PO:
   ```
   Hi [PO name or "team"],

   I'm picking up the "[card title]" card. Before I start, a few quick questions:

   1. [specific question]
   2. [specific question]
   ...

   Thanks!
   ```
   Stop here and wait for the user to confirm they have the answers.

4. **If enough context**, output:
   - **Affected repo(s):** docto-api / docto-app / docto-nextjs (list all relevant)
   - **Summary:** 2-3 sentences of what needs to be done
   - **Tasks:** numbered checklist of concrete implementation steps
   - **Suggested branch name:** `feature/<short-kebab-description>` (based on card title)

5. **Confirm with user:** "Does this look right? Should I create the branch?"

6. **On confirmation**, run in the appropriate repo(s):
   ```bash
   git checkout staging && git pull && git checkout -b feature/<branch-name>
   ```

## Notes

- Always branch from `staging`, not `main`
- If the card touches multiple repos, suggest separate branches with the same base name
- Keep branch names short and lowercase with hyphens
- Keep the Trello card ID in context — the `/pr` skill will use it to post the PR link back to the card
