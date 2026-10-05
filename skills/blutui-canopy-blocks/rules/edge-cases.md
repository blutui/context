---
title: Edge Cases & Gotchas
impact: HIGH
impactDescription: These behaviours fail silently — templates render without errors but show fallback values, escaped HTML, or content that vanishes in the Canopy editor. Knowing them up front avoids debugging sessions that look like data problems.
tags: block scope, page title, route, request, query string, apply, editor re-render, javascript, seeding content, form default
---

## Edge Cases & Gotchas

### 1. Block templates only see `settings`, `canopy`, and `cms`

A block's `{% canopy template %}` section is rendered in its own scope. Its context contains **only** `settings`, `canopy`, and `cms`:

```canvas
<!-- {{ _context|keys|join(',') }} -->   {# → settings,canopy,cms #}
```

These are **not** available inside a block template, even though the layout around it has them:

- `page` (title, name, description)
- `route` (`route.url`, `route.data`)
- `request` (`request.path`, `request.params`, `request.host`)
- any variable the layout `set`s before calling `canopy.blocks()`

Global **functions and filters still work**: `cms.collection()`, `cms.menu()`, `recaptcha()`, `image_url`, `slug`, `date`, and so on.

**It fails silently.** `page.title ?? 'Fallback'` doesn't error — it just always renders `'Fallback'`. If a block shows default text where page data was expected, check scope first. Debug with the `_context|keys` comment above.

**Patterns that work:**

- **Page title or URL inside a block:** have the block output a token, then swap it in the template that wraps the block area, where `page`/`route` are available:

  ```canvas
  {# block template #}
  {% set pageTitle = settings.title ?: '[[page-title]]' %}
  <h1>{{ pageTitle }}</h1>
  <input type="hidden" name="redirect" value="[[page-url]]?sent=1">
  ```

  ```canvas
  {# templates/default.canvas #}
  <main>
    {% apply replace({ '[[page-title]]': (page.title ?? page.name ?? '')|e, '[[page-url]]': (route.url ?? '/')|e })|raw %}
      {% block body %}{% endblock %}
    {% endapply %}
  </main>
  ```

  Escape the replacement values with `|e` — they're inserted into already-rendered HTML.

- **Query-string state** (e.g. a `?sent=1` form success message): render both states, hide one, and toggle them in the block's `{% canopy scripts %}` with `URLSearchParams`. The block can't read `request.params` server-side.
- **Per-page variants:** give editors a setting (`radio`/`select`) instead of detecting the page or URL in the block.

### 2. `{% apply %}` around block output needs `|raw`

`canopy.blocks()` output passed through `{% apply %}` is **auto-escaped**. Without `|raw` the whole area prints as literal `&lt;div …&gt;` text:

```canvas
{% apply replace({...}) %}{{ canopy.blocks('main') }}{% endapply %}        {# ✗ escaped HTML #}
{% apply replace({...})|raw %}{{ canopy.blocks('main') }}{% endapply %}    {# ✓ #}
```

### 3. The Canopy editor replaces block DOM — JavaScript must cope with new nodes

When an editor edits, adds, or reorders blocks (or child blocks), the editor re-renders that block and **swaps in new DOM nodes**. Site JavaScript that ran once on `DOMContentLoaded` never sees the new nodes.

Anything hidden until JavaScript acts on it then **stays hidden**. A common case: scroll-reveal effects that start elements at `opacity: 0` and add an `is-visible` class from an `IntersectionObserver`. To editors it looks like cards "disappear" when they reorder them.

Rules for JavaScript that touches block markup:

- **Never leave content invisible pending JS** unless new nodes are picked up too. Observe the document for added nodes and initialise them:

  ```js
  function scan(root) {
    if (root.nodeType !== 1) return;
    if (root.matches('[data-reveal]')) track(root);
    root.querySelectorAll('[data-reveal]').forEach(track);
  }
  scan(document.body);
  new MutationObserver((mutations) => {
    mutations.forEach((m) => m.addedNodes.forEach(scan));
  }).observe(document.body, { childList: true, subtree: true });
  ```

- **Prefer event delegation** (`document.addEventListener('click', …)` and a `closest()` check) over binding listeners to elements at load. Delegated handlers keep working on re-rendered markup.
- **Make initialisers idempotent:** mark nodes you've set up (`el.dataset.ready = 'true'`) so re-scanning doesn't double-bind.
- **Don't assume a block's `{% canopy scripts %}` section runs again** after a re-render. Write it so one run handles both the initial markup and anything added later.

### 4. Seeding page-specific content

You can't pass per-block data through an explicit template list. `canopy.blocks('main', ['hero', 'text'])` only seeds those templates with their **config defaults**, which are the same on every page that uses the template.

To make a fresh page start with real, page-specific content:

- **Nested blocks:** a parent's `children.default` entries accept `data`, so a parent can seed several fully-written children (feature cards, finance options, FAQ items).
- **Distinct templates:** when two pages need different seed content for the same kind of section, two clearly named templates (`tractor-brands`, `machinery-brands`) beat one generic template with a mode setting. Each gets its own defaults.
- **Page titles:** use the token pattern from section 1 rather than a hard-coded default.

### 5. `form` settings accept a handle as `default`

Like `collection`, a `form` setting can default to a form **handle string**, so the block renders the right form as soon as it's added:

```json
{ "name": "form", "type": "form", "label": "Form", "default": "contact-form" }
```

Still null-check `settings.form` in the template — the form may be deleted later.
