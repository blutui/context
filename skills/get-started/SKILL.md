---
name: get-started
description: Interactive setup for a new Blutui site. Interviews the user about the site they want, records a brief, then builds the content model, templates, layouts, pages, and Canopy blocks and pushes to staging. Only use this skill when the user explicitly runs `/get-started`; never load it automatically. Run it from a project folder created with `courier create`.
disable-model-invocation: true
license: MIT
metadata:
  author: Blutui
  version: '1.0.0'
---

# Get Started with Blutui

This skill only runs when the user invokes it with `/get-started`. Never start it on your own. The expected order is:

1. The user installs Courier and runs `courier login`.
2. The user runs `courier create <handle>` (with `--context` to install the Blutui MCP server and skills), then `cd <handle>`.
3. The user starts their agent in that folder and runs `/get-started`.

If the user includes extra context with the command (project name, handle, cassette, staging URL), use it during preflight and the interview.

Running `/get-started` again in a project that already has a `BLUTUI_BRIEF.md` resumes setup. See [Resuming](#resuming).

**Rules:** This skill sets the order of work. For how to do each step, load the `blutui-project-guidelines` skill and the rule files it names (e.g. `collections.md` is `rules/collections.md` in that skill). For Canopy blocks, also load the `blutui-canopy-blocks` skill. If those skills aren't installed, ask the user to run `npx skills add https://github.com/blutui/context` and restart you.

Setup runs in four phases:

1. **Preflight** — Confirm the project folder, Courier, and the Blutui MCP are ready.
2. **Interview** — Ask what the user is building and record the answers in a brief.
3. **Build** — Create the content model, templates, layouts, and pages.
4. **Review** — Run the site locally, push it to staging, and hand over.

Before starting, tell the user they can stop at any time and pick up later by running `/get-started` again.

### Communication Style

- Keep replies short. Say what you did, not what you are about to do: "Created the `team` collection with name, role, and photo."
- Ask direct questions, a few at a time. Never send the whole interview as one long questionnaire.
- Offer sensible defaults the user can accept with "yes" instead of asking open-ended questions where possible.
- Don't explain Blutui concepts unless the user asks or a decision depends on it.

---

## Phase 1: Preflight

Run every check before asking any interview question. Stop at the first failure and tell the user exactly what to do.

1. **Project folder.** Confirm `courier.json` exists in the working directory. If the prompt gave a project handle, confirm `courier.json` has the same `handle`.
   - If `courier.json` is missing, stop. Ask the user to run `courier create <handle>` (or `courier init` in an existing folder), `cd` into the project, restart you there, and run `/get-started` again.
   - If the handle doesn't match, stop and ask which project they meant. Never edit `handle` to make it match.
2. **Courier.** Run `courier version`. If it fails, stop and send the user to the [Courier installation guide](https://docs.blutui.com/docs/courier/getting-started).
3. **Blutui MCP.** Call `search_blutui_documentation` with a simple query.
   - If the tool is unavailable, ask the user to run `courier mcp init`, then restart you. Do not continue without the MCP — pages, collections, and forms can't be registered without it.
   - If the MCP returns an authentication error, ask the user to run `courier login`, then retry.
4. **Style system.** Detect the project's style system as described in `foundation-file-structure.md` (`tailwind.config.*`, `postcss.config.*`, a `package.json` with a build script, CDN links in `views/templates/default.canvas`). Note what you find for the interview.
5. **Existing work.** Run `list_pages`, `list_collections`, `list_forms`, and `list_menus`, and list the files in `views/`. If the project already has custom layouts, pages, or collections, show the user a one-line summary and ask whether to build on it or start the setup fresh around it. Never delete existing work.

When all checks pass, reply with one line, for example: "Project `acme` is connected. Let's plan your site."

---

## Phase 2: Interview

Ask the questions in the rounds below, in order. Skip any question the user has already answered, and skip a round entirely when its answers are obvious from earlier answers. Fill gaps with defaults and say which defaults you chose.

### Round 1: Purpose

- What is the site for? (business, product, portfolio, event, community, etc.)
- Who is it for, and what is the one thing a visitor should do? (book, buy, enquire, sign up, read)
- Do they have an existing website you can learn from or migrate content from? If yes, ask for the URL.

### Round 2: Pages

Propose a sitemap based on Round 1 and ask the user to confirm or edit it. For example, for a restaurant:

```text
/            Home
/menu        Menu
/about       About
/contact     Contact
```

For each page, decide whether it needs its own layout or can share one (for example, About and Contact sharing a `standard.canvas` layout). Every page must be backed by a layout in `views/layouts/` — see `foundation-templates-and-layouts.md`.

### Round 3: Content model

From the sitemap, identify content that repeats or that editors will update often. Propose how each should be stored and ask the user to confirm:

| Content | Store as | Rule |
| ------- | -------- | ---- |
| Repeating, structured items (team, testimonials, events, products, menu items) | Collection | `collections.md` |
| Articles or news | Blog | `blog.md` |
| Contact, enquiry, booking, or newsletter forms | Form | `forms.md` |
| Header and footer navigation | Menu | `menus.md` |
| Page sections editors arrange themselves | Canopy block area | `canopy.md` |
| Detail pages for collection entries (e.g. `/events/{slug}`) | Route pattern | `route-patterns.md` |

For each collection, propose its fields using only the supported field types in `collections.md`. For each form, propose its fields and who receives submissions.

### Round 4: Editing

- Which sections should editors be able to add, remove, and reorder themselves? These become Canopy blocks.
- Which sections should stay fixed in code? (usually the header, footer, and anything legally required)
- Should any sections be shared across every page (for example a footer call to action)? These become shared block areas.

Default when the user has no preference: fixed header and footer in the template, a page-scoped `main` block area on content pages, and blocks for hero, text, image and text, card grid, and call to action.

### Round 5: Design

- Brand colours, fonts, and logo. Ask the user to put logo and image files in `public/` (or a subfolder of it) and tell you the paths.
- Tone and feel, in a few words (e.g. "warm and rustic", "clean corporate").
- Reference sites they like.
- A Figma file, if they have one. If a Figma MCP server is connected, use it to read the design; otherwise ask for screenshots.

If no style system was found in preflight, ask which approach they want before writing any HTML (see `foundation-file-structure.md`).

### Round 6: Content

Ask where the content will come from:

- **Placeholder** — Write realistic, on-brand placeholder copy and sample entries so the site looks complete. Mark placeholder entries clearly so editors can find them.
- **Provided** — The user pastes or points you to the copy.
- **Migrate** — Read the existing site from Round 1 and carry its copy, structure, and entries across. Only migrate content from the URL the user gave you.

### The brief

After the interview, write the answers to `BLUTUI_BRIEF.md` in the project root and show the user a short summary. Ask them to confirm before you start building.

Courier doesn't sync this file (only `views/` and `public/` are synced), so it stays local. It's how you and future sessions know what was agreed. Use this structure:

```markdown
# Blutui Brief: <project name>

## Purpose
<who the site is for and the main call to action>

## Sitemap
| URL | Page | Layout |
| --- | ---- | ------ |

## Content model
- Collections: <handle> — <fields>
- Blog: <yes/no>
- Forms: <handle> — <fields> — <recipient>
- Menus: <handles>
- Route patterns: <patterns>

## Editing
- Block areas: <areas and whether shared>
- Blocks: <list>

## Design
<colours, fonts, logo path, tone, references, Figma URL>

## Content source
<placeholder / provided / migrate from URL>

## Progress
- [ ] Content model created
- [ ] Templates and components
- [ ] Layouts and pages registered
- [ ] Canopy blocks
- [ ] Content added
- [ ] Pushed to staging
```

Update the **Progress** checklist as you complete each step.

---

## Phase 3: Build

Build in this order, so templates never reference content that doesn't exist yet. Load the rule for each step before doing it, and use `search_blutui_documentation` whenever you're unsure.

1. **Content model** (`collections.md`, `blog.md`, `forms.md`, `menus.md`, `route-patterns.md`, `mcp.md`)
   - Create collections, the blog, forms, menus, and route patterns with the MCP `create_*` tools. Always run the matching `list_*` tool first to check the handle is free.
   - The MCP can't update or delete resources. If something already exists with the wrong shape, ask the user to change it in the dashboard instead of creating a near-duplicate.
   - If a menu needs items the MCP can't add, list the items and ask the user to add them in the dashboard.
2. **Template and components** (`foundation-templates-and-layouts.md`, `templating-canvas.md`, `templating-including-templates.md`)
   - Set up `views/templates/default.canvas` with the brand styles, fonts, header, and footer. Render menus with `cms.menu()` — never hardcode navigation.
   - Break repeated UI into `views/components/`.
3. **Layouts and pages** (`foundation-templates-and-layouts.md`)
   - Create one layout per page type in `views/layouts/`, extending the template.
   - Register each page with `create_page`, using a layout path relative to `views/` (e.g. `layouts/home.canvas`). The homepage is `/`.
4. **Canopy blocks** (`canopy.md` and the `blutui-canopy-blocks` skill)
   - Create the agreed blocks in `views/canopy/`, each with sensible defaults.
   - Add block areas to the layouts, pairing every `canopy.blocks` with `canopy.head` and `canopy.scripts` using the same handle.
5. **Content**
   - Add collection entries and blog posts with the MCP, following the content source from the brief.
   - Page content inside Canopy block areas is added by editors in the Canopy editor. Tell the user which blocks to add to which pages, or leave the block defaults to show a complete page.

After each step, tick it off in the brief and tell the user in one line what was created.

---

## Phase 4: Review

1. **Run locally.** If the project has a `package.json`, run `npm install` and the dev script (usually `npm run dev`) to compile assets into `public/`. Then ask the user to run `courier dev` in a separate terminal and open `https://localhost:8080`. Ask whether anything looks wrong and fix it before pushing.
2. **Push.** Run `courier push`. If Courier refuses because the cassette is active, follow `cassettes.md` — never pass `--allow-active` without the user's explicit confirmation.
3. **Hand over.** Tell the user:
   - The staging URL, `https://<handle>.blutui.com` (or the site URL in `courier.json` if one is set). Staging is protected by the project's development password, shown in the Blutui console.
   - What was built: pages, collections, forms, menus, and blocks.
   - What's left for them: menu items or settings to add in the dashboard, placeholder content to replace, and images to upload.
   - That publishing the site to the public is done from the Blutui console and is a paid step. Never attempt to publish.
   - They can run `/get-started` again to pick up unfinished steps, or ask for changes at any time.

---

## Resuming

When `/get-started` runs in a project that has already been set up, or partly set up:

1. Re-run the Phase 1 preflight.
2. Read `BLUTUI_BRIEF.md`. If it exists, find the first unticked item in **Progress** and confirm with the user before continuing from there.
3. If there is no brief, work out where the project stands:
   - No custom layouts in `views/layouts/` and no pages from `list_pages` → start at Phase 2.
   - Layouts or collections exist → summarise what you found, ask the user to confirm what the site is for, write a brief from what exists plus their answers, then continue building.
4. Never rebuild or overwrite work that already exists without asking.

Reference: [AI Assisted Development](https://docs.blutui.com/docs/getting-started/agentic-development)
