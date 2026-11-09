---
name: get-started
description: Interactive setup for a new Blutui site. Interviews the user about the site they want, records a brief, then builds it and pushes to staging. Only use this skill when the user explicitly runs `/get-started`; never load it automatically. Run it from a project folder created with `courier create`.
disable-model-invocation: true
---

# Get Started with Blutui

Only run this when the user invokes `/get-started`. Keep replies short, ask a few questions at a time, and offer defaults the user can accept with "yes".

Follow the `blutui-project-guidelines` skill for how to build each piece, and the `blutui-canopy-blocks` skill for blocks. If they aren't installed, ask the user to run `npx skills add https://github.com/blutui/context` and restart you.

**Resume:** If `BLUTUI_BRIEF.md` exists, skip the interview and continue from its unticked items.

## 1. Preflight

Stop at the first failure and tell the user what to do.

1. `courier.json` exists in the working directory. If not, ask the user to run `courier create <handle> --context`, `cd` into it, restart you there, and run `/get-started` again.
2. The Blutui MCP responds (call `search_blutui_documentation`). If not, ask the user to run `courier mcp init` and restart you. If it returns an auth error, ask them to run `courier login`.

## 2. Interview

Ask in rounds, skipping anything already answered:

1. **Purpose** — What the site is for, who it's for, and the one thing a visitor should do. Do they have an existing site to learn from or migrate? Get the URL.
2. **Pages** — Propose a sitemap (URL, page, layout) for the user to confirm or edit.
3. **Content model** — Propose how repeating or frequently updated content is stored, and confirm:
   - Repeating, structured items (team, testimonials, events, products) → Collection, with fields
   - Articles or news → Blog
   - Contact, booking, or newsletter forms → Form, with fields and who receives submissions
   - Header and footer navigation → Menu
   - Detail pages for entries (e.g. `/events/{slug}`) → Route pattern
4. **Editing** — Which sections editors add and reorder themselves (Canopy blocks), which stay fixed in code, and which are shared across pages. Default: fixed header and footer, a `main` block area on content pages, and hero, text, image and text, card grid, and call to action blocks.
5. **Design** — Brand colours, fonts, logo (ask them to put files in `public/`), tone, reference sites, and a Figma file if they have one.
6. **Content** — Placeholder copy, copy they provide, or migrated from the URL in round 1.

Write the answers to `BLUTUI_BRIEF.md` in the project root and ask the user to confirm before building. Courier doesn't sync it, so it stays local.

```markdown
# Blutui Brief: <project name>

## Purpose
## Sitemap
## Content model
## Editing
## Design
## Content source

## Progress
- [ ] Content model
- [ ] Template and components
- [ ] Layouts and pages
- [ ] Canopy blocks
- [ ] Content
- [ ] Pushed to staging
```

## 3. Build

Build in this order so templates never reference content that doesn't exist yet, ticking each item in the brief as you go:

1. Content model — collections, blog, forms, menus, and route patterns via the MCP.
2. Template and components.
3. Layouts, then register each page with `create_page`.
4. Canopy blocks and block areas.
5. Content — collection entries and posts via the MCP.

## 4. Review

1. Run `courier push`. Never pass `--allow-active` without the user's confirmation.
2. Share the staging URL, `https://<handle>.blutui.com`.
3. List what's left for the user in the dashboard: menu items, placeholder content to replace, and images to upload.
4. Never publish. Publishing is a paid step the user does from the Blutui console.
