# Housing Finder

*Full disclosure: a lot of this project was hacked together quickly with Claude, and this README also generated largely with Claude. This was purely meant to be a functional tool to help me find roommates so I did it very quickly in a couple days.*

A personal tool for finding a great place to live. It continuously scrapes housing
listings from Facebook Groups and Facebook Marketplace, uses Claude to read each post
(including the photos) and score how well it fits *your* specific tastes and needs, then surfaces the best matches in a browsable dashboard.

Instead of scrolling through hundreds of repetitive, vaguely-worded posts every day,
you open one page and see the handful of listings actually worth your attention —
ranked, summarized, and flagged.

Some filtering before the AI scoring is hard-coded.

## What it does

- **Scrapes automatically.** A daily cron job kicks off [Apify](https://apify.com)
  scrapers for your chosen Facebook Groups and Marketplace searches.
- **Ingests and dedupes.** Supabase Edge Functions pull in new posts, extract text and
  image URLs, and store them.
- **Scores with AI.** A `score-listing` Edge Function sends each post and its images to
  the Claude API, which returns a structured judgment: a 1–10 fit score, a one-line
  summary, the price, neighborhood, lease type, move-in date, and any flags
  (e.g. "Seeking housing", which gets filtered out).
- **Personalizes the scoring.** Everything lives in a single editable prompt
  ([`prompt.txt`](prompt.txt)), so the bar is tuned to one real person rather than a
  generic rubric.
- **Surfaces the best.** A Next.js dashboard shows scored listings with photos,
  sortable by most recent or best score, filterable to favorites or new-only, with
  one-click favoriting and lightbox image viewing. Low-scoring posts (below 4) are
  hidden automatically.

## How it works

```
Apify scrapers (Groups + Marketplace)
        │  daily cron
        ▼
ingest-groups / ingest-marketplace  ──►  Supabase (listings table)
        │
        ▼
score-listing (Claude API + prompt.txt)  ──►  ai_score, summary, flags, …
        │
        ▼
Next.js dashboard  ──►  you browse the best matches
```

Three cron jobs (defined in Supabase) drive everything: a daily Groups scrape, a daily
Marketplace scrape, and a score pass every 5 minutes that picks up any unscored
listings. The dashboard also exposes manual "scrape" and "score" buttons for on-demand
runs.

## Stack

- **Next.js 14** (App Router) + **TypeScript** + **Tailwind CSS** — dashboard and API routes
- **Supabase** — Postgres for storage, Edge Functions for ingestion and scoring, `pg_cron` for scheduling
- **Apify** — Facebook Groups and Marketplace scrapers
- **Anthropic Claude API** — reads posts and images, returns structured scores
- **Vercel** — hosting

## Project layout

| Path | What's there |
| --- | --- |
| [`app/page.tsx`](app/page.tsx) | Dashboard entry point |
| [`components/listings-dashboard.tsx`](components/listings-dashboard.tsx) | Listing grid, sorting, filtering, favoriting |
| [`components/listing-card.tsx`](components/listing-card.tsx) | Individual listing card + lightbox |
| [`app/api/trigger-groups`](app/api/trigger-groups/route.ts), [`app/api/trigger-marketplace`](app/api/trigger-marketplace/route.ts) | Kick off Apify scraper runs |
| [`app/api/score`](app/api/score/route.ts) | Queue unscored listings for the scoring function |
| [`supabase/functions`](supabase/functions) | `ingest-groups`, `ingest-marketplace`, `score-listing` Edge Functions |
| [`supabase/migrations`](supabase/migrations) | DB schema and cron job definitions |
| [`prompt.txt`](prompt.txt) | The scoring rubric / personal preferences sent to Claude |

## Environment variables

This project uses Supabase's modern key names:

```env
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=...   # publishable (not anon) key
SUPABASE_SECRET_KEY=...                    # secret (not service-role) key
APIFY_API_TOKEN=...
GROUP_IDS=...                              # comma-separated FB group IDs or URLs
ANTHROPIC_API_KEY=...                      # used by the score-listing Edge Function
```

## Local development

```bash
npm install
npm run dev
```

The dashboard runs at [localhost:3000](http://localhost:3000/). Edge Functions and cron
jobs run in Supabase; see the [Supabase local development docs](https://supabase.com/docs/guides/local-development)
to run the full stack locally.

## Tuning the scoring

Edit [`prompt.txt`](prompt.txt) to change what counts as a good listing — neighborhoods,
roommate vibe, aesthetic, budget, move-in dates, and the flag definitions. Use
[`scripts/set-prompt.sh`](scripts/set-prompt.sh) to push the updated prompt to the
scoring function.
