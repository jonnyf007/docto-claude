# /deploy — Deploy to Environment

Deploy current changes to staging, qat, or production.

## Usage

```
/deploy [staging|qat|production]
```

If no environment is specified, ask which one.

## Steps

1. **Detect context** — are we inside `scheduled_tasks/<lambda-name>/`?

---

### If inside `scheduled_tasks/`

Deploy the Lambda directly (not via GitHub Actions):

```bash
cd scheduled_tasks/<lambda-name>
./deploy-code.sh <env>
```

If the upload times out (large zip), use the manual build:
```bash
mkdir -p dist && cp index.js package.json package-lock.json dist/ && cp -r templates dist/ 2>/dev/null || true
cd dist && npm install --production && zip -r ../fn.zip . && cd ..
AWS_CLI_READ_TIMEOUT=300 aws lambda update-function-code \
  --function-name <lambda-name>-<env> \
  --zip-file fileb://fn.zip \
  --region ap-southeast-2
rm -rf dist fn.zip
```

After deploy, tail logs:
```bash
aws logs tail /aws/lambda/<lambda-name>-<env> --since 5m --follow
```

---

### If in docto-api, docto-app, or docto-nextjs

Deploy via GitHub Actions (push to env branch):

1. Check current branch: `git branch --show-current`
2. Check for uncommitted changes: `git status`
3. If clean, push to the target env branch:
   ```bash
   git push origin HEAD:<env>
   ```
4. Show the GitHub Actions link:
   - `https://github.com/jonnyf007/<repo>/actions`

---

## Safety checks

- **Never deploy directly to production without confirming** — always ask "Are you sure you want to deploy to production?" before running
- If there are uncommitted changes, warn the user and ask if they want to commit first
- If the current branch is `main`, warn — typically you push a feature branch to the env branch, not main

## Notes

- `staging` — safe to push anytime, emails are redirected
- `qat` — QA team may be testing, give a heads up if a big change
- `production` — always double-check, always confirm
