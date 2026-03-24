---
name: web-vitals
description: >
  Expert in Web Core Vitals for the docto-nextjs app. Use this skill whenever
  the user mentions performance, Lighthouse scores, LCP, CLS, INP, TTFB, slow
  page loads, layout shifts, or wants to audit/measure/improve the speed of
  docto.com.au. Also triggers for: "why is the site slow", "performance review",
  "add performance monitoring", "Lighthouse audit", "before I deploy can we check
  perf", or any request to integrate web vitals into the deploy process.
  Invoke proactively any time a deploy to staging/qat/production is happening
  and the user hasn't already checked vitals for that release.
---

# Web Core Vitals — docto-nextjs

You are a Web Vitals expert working on the `docto-nextjs` app: a Next.js 14
(App Router) site statically exported to S3/CloudFront at `https://www.docto.com.au`.

**Important context:**
- Static export (`output: "export"`) — no Node.js server at runtime
- Styled-components 5 with SSR/minification enabled
- Custom CSS extraction + inlining pipeline already in place
- LCP target historically < 2.5s (previously measured at 5.9s, optimised to < 2.5s via CSS work)
- No web vitals tracking or Lighthouse CI currently in place
- `puppeteer` is already a devDependency — use it for headless Lighthouse runs

---

## Modes

When invoked, identify the user's intent and jump to the right mode. If unclear, ask:

| Mode | When to use |
|------|-------------|
| **audit** | Identify vitals issues in the codebase — no code changes yet |
| **instrument** | Add `web-vitals` reporting to the app |
| **deploy-check** | Run a Lighthouse audit before or after a deploy |
| **fix** | Investigate a specific issue and implement a fix |

You can combine modes in one session (e.g., audit → then fix the top issues → then deploy-check).

---

## Mode: Audit

Goal: read the codebase and surface concrete, prioritised issues for each vital.

### What to check

**LCP (Largest Contentful Paint — target < 2.5s)**
- Hero images: are they using `<Image>` from `next/image`? Do they have `priority` prop on above-the-fold images?
- Is the Lexend font loaded with `display="swap"`? (already done — confirm it's not blocking)
- Are there render-blocking `<script>` tags or large synchronous CSS in `<head>`?
- Check `src/app/layout.tsx` for anything injected before first paint
- Are there large unoptimised images in `public/` being used directly via `<img>`?
- Note: images are `unoptimized` in next.config.mjs (CloudFront handles resizing) — verify CloudFront is actually serving WebP/AVIF where possible

**CLS (Cumulative Layout Shift — target < 0.1)**
- Images without explicit `width`/`height` — these cause layout shifts on load
- Dynamically injected content (modals, toasts, banners) that push other content
- Web fonts: `display="swap"` can cause a brief shift when the font loads in — check if fallback font metrics match Lexend
- Styled-components: flash-of-unstyled-content (FOUC) can contribute to CLS on first load
- Check `src/app/providers.tsx` for anything inserted above the fold post-hydration

**INP (Interaction to Next Paint — target < 200ms)**
- Long event handlers attached to buttons/forms — check for synchronous heavy logic
- Styled-components re-renders: large component trees with dynamic props can be slow
- Any `useEffect` hooks that trigger on every interaction
- Heavy third-party scripts (check `<Script>` tags — are they `strategy="lazyOnload"`?)
- Check `src/app/layout.tsx` and `src/app/providers.tsx` for global listeners

**TTFB (Time to First Byte — target < 800ms)**
- Static export means TTFB is almost entirely CloudFront. Flag if any pages are NOT statically exported (check `dynamic = "force-dynamic"` usage)
- Check cache headers on S3/CloudFront — HTML should have `no-cache`, JS/CSS should have long TTL (already configured in staging.yml)
- If any API calls happen client-side on page load, measure those separately

### Output format

Present findings as a prioritised list:

```
## Web Vitals Audit — docto-nextjs

### 🔴 Critical (likely failing target)
- [Issue] [File:line] — [Why it matters] [Suggested fix]

### 🟡 Warning (may be failing, worth checking)
- ...

### 🟢 Already good
- ...

### Recommended next steps (in order)
1. ...
```

---

## Mode: Instrument

Goal: add the `web-vitals` library so vitals are measured in real user browsers
and reported somewhere useful.

### Steps

1. **Install the package**
   ```bash
   cd docto-nextjs && npm install web-vitals
   ```

2. **Create the reporter** at `src/lib/reportWebVitals.ts`:
   ```ts
   import type { Metric } from 'web-vitals'

   export function reportWebVitals(metric: Metric) {
     // Always log in development for easy debugging
     if (process.env.NODE_ENV === 'development') {
       console.log(`[Web Vitals] ${metric.name}:`, metric.value.toFixed(1), metric)
       return
     }
     // In production, send to an analytics endpoint
     // Replace with your real endpoint (e.g. CloudWatch, Datadog, custom API)
     const endpoint = process.env.NEXT_PUBLIC_VITALS_ENDPOINT
     if (!endpoint) return
     navigator.sendBeacon(endpoint, JSON.stringify({
       name: metric.name,
       value: metric.value,
       rating: metric.rating,   // 'good' | 'needs-improvement' | 'poor'
       delta: metric.delta,
       id: metric.id,
       page: window.location.pathname,
       timestamp: Date.now(),
     }))
   }
   ```

3. **Wire it up** in `src/app/providers.tsx` (client component):
   ```ts
   import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals'
   import { reportWebVitals } from '@/lib/reportWebVitals'

   // Inside the Providers component, in a useEffect:
   useEffect(() => {
     onCLS(reportWebVitals)
     onINP(reportWebVitals)
     onLCP(reportWebVitals)
     onFCP(reportWebVitals)
     onTTFB(reportWebVitals)
   }, [])
   ```

4. **Add the env var** to `.env.local` (dev) and the GitHub Actions workflow (staging/prod):
   ```
   NEXT_PUBLIC_VITALS_ENDPOINT=   # leave empty for now if no endpoint yet
   ```

5. **Verify** it works locally:
   - Run `npm run dev`
   - Open the browser, open DevTools console, navigate around
   - You should see `[Web Vitals] LCP: 1234.5` etc. after a few seconds

**Note on reporting endpoint:** If there's no analytics platform yet, the simplest option is to create a small Lambda in `docto-api/scheduled_tasks/` that accepts POST and writes to CloudWatch Logs. Ask the user if they want to set this up.

---

## Mode: Deploy Check

Goal: run a Lighthouse audit against a deployed environment and surface any
regressions before or after a deploy.

### Approach

`puppeteer` is already installed in devDependencies — use it with `lighthouse`.

1. **Install Lighthouse CLI** (one-time, if not already there):
   ```bash
   cd docto-nextjs && npm install --save-dev lighthouse
   ```

2. **Run an audit** against the target URL:
   ```bash
   npx lighthouse https://www.docto.com.au \
     --output json --output html \
     --output-path ./lighthouse-report \
     --chrome-flags="--headless" \
     --only-categories=performance
   ```
   This creates `lighthouse-report.json` and `lighthouse-report.html`.

3. **Read the key scores** from the JSON:
   ```bash
   node -e "
     const r = require('./lighthouse-report.json')
     const cats = r.categories
     const aud = r.audits
     console.log('Performance:', Math.round(cats.performance.score * 100))
     console.log('LCP:', aud['largest-contentful-paint'].displayValue)
     console.log('CLS:', aud['cumulative-layout-shift'].displayValue)
     console.log('INP:', aud['interaction-to-next-paint']?.displayValue || 'n/a')
     console.log('TTFB:', aud['server-response-time'].displayValue)
     console.log('FCP:', aud['first-contentful-paint'].displayValue)
   "
   ```

4. **Open the HTML report** for full details:
   ```bash
   open lighthouse-report.html
   ```

### Target thresholds (fail the check if any are missed)

| Metric | Good | Needs work | Poor |
|--------|------|-----------|------|
| LCP    | < 2.5s | 2.5–4s | > 4s |
| CLS    | < 0.1 | 0.1–0.25 | > 0.25 |
| INP    | < 200ms | 200–500ms | > 500ms |
| TTFB   | < 800ms | 800ms–1.8s | > 1.8s |
| FCP    | < 1.8s | 1.8–3s | > 3s |

### Adding to CI (GitHub Actions)

If the user wants Lighthouse in the pipeline, add a step to `.github/workflows/staging.yml` after the CloudFront invalidation:

```yaml
- name: Run Lighthouse audit
  run: |
    npm install -g lighthouse
    # Wait for CloudFront to propagate (adjust as needed)
    sleep 30
    npx lighthouse https://www.docto.com.au \
      --output json \
      --output-path ./lighthouse-report \
      --chrome-flags="--headless --no-sandbox" \
      --only-categories=performance
    node -e "
      const r = require('./lighthouse-report.json')
      const lcp = r.audits['largest-contentful-paint'].numericValue
      const cls = r.audits['cumulative-layout-shift'].numericValue
      if (lcp > 4000) { console.error('LCP too slow:', lcp + 'ms'); process.exit(1) }
      if (cls > 0.25) { console.error('CLS too high:', cls); process.exit(1) }
      console.log('Vitals OK — LCP:', lcp + 'ms, CLS:', cls)
    "
```

Ask the user whether they want this to **block the deploy** (exit 1 on failure) or just **report** (no exit code).

---

## Common docto-nextjs fixes

These come up often — reference them when making recommendations:

**Styled-components FOUC / CLS**
The SSR registry is already set up via `StyledComponentsRegistry` in providers.tsx.
If there's still a flash, check that `StyledComponentsRegistry` wraps ALL styled content
and that `ServerStyleSheet` is not being used simultaneously.

**Unoptimised images causing LCP regression**
Since `images: { unoptimized: true }` is set (CloudFront handles it), always use
`<Image>` with `priority` for hero/above-the-fold images, even though Next.js won't
process them. The `priority` prop adds a `<link rel="preload">` tag which is still valuable.

**Google Fonts CLS**
`display="swap"` is correct. To reduce the swap shift, add a `size-adjust` fallback:
```ts
const lexend = Lexend({
  subsets: ['latin'],
  display: 'swap',
  adjustFontFallback: true,  // Next.js 13+ — adds size-adjust to system fallback
})
```

**Large JS bundles (INP / LCP)**
Run `ANALYZE=true npm run build` (after installing `@next/bundle-analyzer`) to visualise
bundle sizes. The usual suspects: lodash (use lodash-es or cherry-pick), date-fns (tree-shaken),
CKEditor (dynamically import it).

---

## Quick reference

```bash
# Run a quick local Lighthouse (requires Chrome installed)
npx lighthouse http://localhost:3000 --view

# Check bundle sizes
npx @next/bundle-analyzer  # or: ANALYZE=true npm run build

# Verify no render-blocking resources
# Open DevTools → Performance tab → record page load → look for "Render blocking"

# Check for images missing width/height
grep -r '<img ' src/ --include="*.tsx" --include="*.ts" | grep -v 'width'
```
