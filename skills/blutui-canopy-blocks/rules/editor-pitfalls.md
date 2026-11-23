---
title: Canopy Editor Pitfalls
impact: HIGH
impactDescription: Site JavaScript and CSS that assume a static, top-level page break the Canopy editor preview — sections grow without limit, content stays invisible, clicks load other sites into the frame, or widgets stop responding.
tags: canopy, editor, preview, iframe, javascript, css, vh, links
---

## Canopy Editor Pitfalls

Every block template and every site-wide script must work in the Canopy editor preview as well as on the public site. Use this file when writing block markup, site JavaScript, or full-height / animated / linked sections.

Each finding is marked:

- **[verified]** — reproduced in the editor (Nov 2026).
- **[client source]** — read from the editor's in-frame script (`/_/assets/canopy-client-*.js`) and not exercised directly.
- **[unverified]** — general guidance that hasn't been tested against the editor.

The editor is not formally documented. Re-check these findings when the editor changes.

### How the editor runs your page

- **[verified]** The page loads in an **iframe** on the same origin, with these query params: `blutui_editor`, `blutui_editor_mode` (`viewport` = "Screen", `page` = "Full page") and `blutui_editor_vh` (screen height in px, default `800`).
- **[verified]** In the preview each block is wrapped in `div[data-canopy-block][data-canopy-block-template][data-canopy-block-name]`. **The wrappers only exist in the editor.** The public page renders blocks without them, so never use them as styling or JS hooks the live site depends on.
- **[verified]** The editor talks to the frame through `window.top.canopyBus` (mitt-style: `on`, `off`, `emit`, `all`). Events seen: `frame-reload-start`, `load-elements`, `frame-loaded`, `route-change`, `close-options`, `cancel-tree`, `update-page-dropdown`. **[client source]** Also `form-submitted`, `select-tree`, `canopy-options`, `click-element`.
- **[verified] Apply stages, Save publishes.** The settings panel says so ("Changes are staged here. Click Save in the toolbar to publish them."). Editing a setting and clicking **Apply** does not change the preview. **Save** reloads the whole iframe. Adding, reordering and deleting blocks *does* show before Save; a staged delete hides the wrapper with `display: none`. This is designed behaviour, not a bug.
- **[client source]** On `DOMContentLoaded` the editor script **removes every `<script>` inside `<body>`**. Scripts that already ran keep working, but anything that reads a body `<script>` later (inline JSON config, `document.currentScript` lookups) finds nothing. Put editor-detection and config scripts in `<head>`.
- **[client source]** Form submits are intercepted and reported as `form-submitted`. Forms never really submit in the preview.

### Pitfalls

1. **`vh` / `dvh` sections grow without limit in Full page mode.** [verified] In Full page mode the frame is sized to the document, so `min-height: 100vh` (or `dvh`/`svh`/`lvh`) keeps growing. A hero measured **69,394px tall** with its text pushed out of view. The editor tries to rewrite viewport units to px, but only by reading `document.styleSheets`. **Stylesheets served from the Blutui CDN (`asset()` → `cdn.blutui.com`) are cross-origin, so their rules can't be read and are never rewritten.** It also only runs in Full page mode, and `vw` is never rewritten.
   - Fix: never rely on raw `vh` for section heights. Use a custom property with a fallback, and set it from `blutui_editor_vh` in a `<head>` script (see the pattern below):
     `min-height: var(--screen-h, 100dvh);`

2. **Links navigate the preview, and other sites break it.** [verified] The editor catches clicks on any `<a>` and routes the preview to its `href` (`route-change`). The exceptions are `#` links and `target="_blank"`. Internal relative links open that page in the editor, which is intended. **Absolute links to another site load that site into the frame. Most sites refuse to be framed, so editors get a broken-page icon and can't keep editing.**
   - Fix: in the editor, set `target="_blank"` on links to other origins (the editor skips those) and `preventDefault()` in a capture listener.
   - Don't `stopPropagation()` on link clicks. Block selection is also click-driven.

3. **Clicking inside a block selects the block, so widgets don't respond.** [verified] Clicking an accordion header in the preview opened the block's settings panel instead of the accordion. Tabs, accordions, sliders and "load more" buttons can't be operated while editing.
   - Fix: make the default state show the content editors need to see, or add a setting such as "Open first item" or "Show all slides in editor". Don't hide editable content behind an interaction.

4. **Content hidden until JS reveals it stays hidden.** [verified] A hero using `opacity: 0` + IntersectionObserver rendered **invisible** after a preview reload, with the frame restored to a mid-page scroll position. The editor script only force-shows its own list: [client source] `[data-aos]`, `[data-sal]` and `.wow`. Custom reveal classes aren't covered.
   - Fix: in the editor, show everything immediately (`.is-canopy-editor [data-reveal] { opacity: 1; transform: none; }`) and skip the observer. Outside the editor, never hide content that has no JS fallback.

5. **A fixed header covers whatever block an editor moves to the top.** [verified] The design assumed a hero with large top padding comes first. When a Careers CTA was dragged to the top, the fixed header covered it.
   - Fix: offset any first block that isn't designed to sit under the header, and cover both the public markup and the editor wrapper, e.g. `#main > h1 + section:not(.hero), #main > h1 + [data-canopy-block] > section:not(.hero) { margin-top: <header height>; }`.

6. **Code waiting for `transitionend` never finishes in Full page mode.** [client source; observed `transition-duration: 0s` in the frame] Full page mode sets all transition and animation durations to ~0, so `transitionend` doesn't fire. Accordions that switch to `height: auto` on `transitionend` get stuck at a fixed px height.
   - Fix: always pair `transitionend` with a timeout fallback.

7. **Autoplaying media and carousels.** Slides and videos change under the cursor, so editors can't select what they're looking at.
   - Fix: turn autoplay off in the editor (remove `autoplay`, call `pause()`), and keep timers that reorder or re-render content (shuffles, marquees) off too.
   - The editor itself doesn't stop video autoplay. [verified: muted autoplay video ran in the preview before the fix]

8. **One-shot, document-wide initialisation.** [partly verified] Save does a full iframe reload, so plain `DOMContentLoaded` init survived every Save in testing. Staged adds and reorders update the preview without Save, though, and future editor versions may redraw blocks in place.
   - Fix: write init per root and make it idempotent (mark initialised elements). Watch for added nodes and initialise them, and delegate events from the block root rather than binding to each child.

9. **One uncaught error stops every later feature.** [general] A throw in a shared script skips everything initialised after it, and the preview looks broken.
   - Fix: wrap each feature's init in `try/catch` and log the error.

10. **`canopy.blocks(area, [templates])` is a seed, not a lock.** [verified — corrects earlier advice that it renders a fixed sequence]
    - With a template list, the area renders those templates (with defaults) until an editor saves.
    - Editors can still add, reorder and delete blocks. After Save, the **saved editor state renders on the public page**: an added block and the new order both appeared.
    - Use the list to ship a page that looks complete before anyone edits it. Use plain `canopy.blocks('main')` when the page should start empty.
    - Use `{ locked: true }` only when the structure really must not change.
    - Untested: what renders if an editor deletes every block and saves.

11. **Embeds that refuse to be framed.** [verified for links; unverified for embeds] A site that sends `X-Frame-Options` / `frame-ancestors` shows an error screen inside the preview. Privacy-restricted Vimeo/YouTube and domain-locked maps behave the same way.
    - Fix: check the embed's allowed domains (both `*.blutui.com` staging and the live domain), or render a poster/fallback in the editor.

12. **Changes don't appear immediately after `courier push`.** [unverified here] For a few seconds after a push the site can return "Templates not found". That's propagation; reload before debugging.

### Unverified (general guidance)

- `window.top`, `parent` or `document.referrer` reads, and frame-busting scripts, fail or misfire inside the preview.
- Scroll-jacking and smooth-scroll libraries fight the editor's scrolling and its `scrollIntoView` on selection.
- `preventDefault` / `stopPropagation` on document-level click handlers can swallow the editor's clicks. The editor's own link router listens on `document` in the bubble phase. [client source]
- Content injected client-side (from an API, or built in JS) isn't inside a block. It can't be edited and may duplicate on re-render.
- Analytics, chat widgets and cookie banners load in the preview, add overlays and record editor traffic. Skip them when the editor is detected.
- A CSP or `X-Frame-Options` that blocks same-origin framing stops the preview from loading at all.

### Detecting the editor

There's no documented Canvas variable or JS API for "in the editor" (searched Nov 2026). The reliable signal is the `blutui_editor` query param on the frame URL. `window.self !== window.top` is a fallback only, because it's also true when the site is embedded anywhere else. If Blutui adds a supported flag, prefer it.

### Defensive pattern

`templates/default.canvas`, in `<head>`, so it runs before first paint and survives the body-script removal:

```canvas
<script>
  (function () {
    var p = new URLSearchParams(location.search);
    if (!p.has('blutui_editor')) return;
    var root = document.documentElement;
    root.classList.add('is-canopy-editor');
    root.style.setProperty('--screen-h', (parseInt(p.get('blutui_editor_vh'), 10) || 800) + 'px');
  })();
</script>
```

CSS:

```css
.hero { min-height: var(--screen-h, 100dvh); }            /* never raw 100vh for section heights */
.is-canopy-editor [data-reveal] { opacity: 1; transform: none; transition: none; }
```

Site JS:

```js
const EDITOR = document.documentElement.classList.contains('is-canopy-editor')

// Run fn once per matching element inside root (root included).
function each(root, selector, key, fn) {
  const nodes = root.matches?.(selector) ? [root] : []
  root.querySelectorAll(selector).forEach((el) => nodes.push(el))
  nodes.forEach((el) => {
    const ready = (el.dataset.jsReady || '').split(' ')
    if (ready.includes(key)) return
    el.dataset.jsReady = [...ready.filter(Boolean), key].join(' ')
    fn(el)
  })
}

function initSliders(root) {
  each(root, '[data-slider]', 'slider', (el) => startSlider(el, { autoplay: !EDITOR }))
}

function initReveal(root) {
  each(root, '[data-reveal]', 'reveal', (el) => {
    if (EDITOR) return el.classList.add('is-revealed')
    observeReveal(el)
  })
}

// Links to other origins: let the editor skip them and stay on the page being edited.
const isExternal = (a) => { try { return new URL(a.href).origin !== location.origin } catch { return false } }
function guardLinks(root) {
  if (!EDITOR) return
  each(root, 'a[href]', 'link-guard', (a) => { if (isExternal(a)) a.target = '_blank' })
}
if (EDITOR) document.addEventListener('click', (e) => {
  const a = e.target.closest?.('a[href]')
  if (a && isExternal(a)) e.preventDefault()   // no stopPropagation: block selection needs the click
}, true)

const FEATURES = [guardLinks, initReveal, initSliders /*, … */]
function init(root) {
  FEATURES.forEach((fn) => { try { fn(root) } catch (e) { console.error(fn.name, e) } })
}

document.addEventListener('DOMContentLoaded', () => {
  init(document)
  new MutationObserver((ms) => ms.forEach((m) => m.addedNodes.forEach((n) => n.nodeType === 1 && init(n))))
    .observe(document.getElementById('main') || document.body, { childList: true, subtree: true })
})
```

For animations: pair every `transitionend` with `setTimeout(finish, durationMs + 100)`.
