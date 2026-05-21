---
name: 10-10-frontend
description: Polish a frontend design iteratively using real screenshots until every visual criterion scores 10/10.
---

# 10/10 Frontend

Iterate on a frontend using real screenshots until every visual criterion scores 8+ and the overall is 10/10.

## The Loop

### Step 1: Screenshot

```typescript
import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage();

// Desktop
await page.setViewportSize({ width: 1440, height: 900 });
await page.goto('http://localhost:PORT');
await page.screenshot({ path: 'screenshot-desktop.png', fullPage: true });

// Mobile
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: 'screenshot-mobile.png', fullPage: true });

await browser.close();
```

If the app requires auth, log in before screenshotting.

### Step 2: Evaluate

Read both screenshots and score each criterion 1–10:

| Criterion | What to assess |
|---|---|
| **Typography** | Font choices, size hierarchy, line height, letter spacing, readability |
| **Color** | Palette cohesion, contrast ratios, mood, whether it feels intentional |
| **Layout** | Visual flow, spatial rhythm, alignment, responsive quality |
| **Polish** | Hover states, transitions, loading states, micro-interactions, empty states |
| **Distinctiveness** | Does it have a clear identity, or does it look generated? |

Overall score = average. Be honest — do not round up.

### Step 3: Fix

For each criterion scoring below 8:
- Name the specific elements that are weak
- Make 1–3 targeted changes (do not overhaul everything at once)
- Follow the direction already established — don't switch aesthetic mid-polish

### Step 4: Re-screenshot

Go back to Step 1 with the updated code.

## Stop Condition

Stop when ALL criteria ≥ 8 AND overall = 10/10.

If stuck after 5 iterations:
- Step back — is the core aesthetic direction working?
- Try a different approach for the weakest criterion
- Show the user the screenshots and ask for direction

Maximum 10 iterations. If not 10/10 by then, report what remains and why.

## Log Each Iteration

```
Iteration N:
  Scores: Typography N | Color N | Layout N | Polish N | Distinctiveness N
  Overall: N/10
  Changes made: [list]
  Weakest area: [criterion]
```

## Rules
- Both desktop (1440×900) and mobile (390×844) every iteration
- Be honest in scoring — premature 10/10 declarations mean users get a 7/10 product
- Fix the weakest criterion each iteration, not the easiest
- Document every change made — this creates a record of what improved the design
