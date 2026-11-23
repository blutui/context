---
title: Canopy Editor Pitfalls
impact: HIGH
impactDescription: Site JavaScript and CSS that assume a static, top-level page break the Canopy editor preview — sections grow without limit, content stays invisible, clicks load other sites into the frame, or new blocks miss their behaviour.
tags: canopy, editor, preview, iframe, javascript, css, vh, links
---

## Canopy Editor Pitfalls

Every block template and every site-wide script must work in the Canopy editor preview as well as on the public site. Use this file when writing block markup, site JavaScript, or full-height, animated or linked sections.

Everything below was tested in the Canopy editor on a real project (November 2026). The editor isn't formally documented, so its behaviour can change between releases.

### How the editor runs your page

- **The page loads in an iframe on the same origin**, with these query params:
  - `blutui_editor`
  - `blutui_editor_mode`: `viewport` for the "Screen" view, `page` for "Full page"
  - `blutui_editor_vh`: the screen height in px (`800` in testing)
- **Each block is wrapped** in `div[data-canopy-block][data-canopy-block-template][data-canopy-block-name]`. These wrappers only exist in the editor; the public page renders blocks without them. Never use them as hooks the live site depends on.
- **The editor talks to the frame through `window.top.canopyBus`** (`on`, `off`, `emit`, `all`). Events seen during editing: `frame-reload-start`, `load-elements`, `frame-loaded`, `route-change`, `close-options`, `cancel-tree`, `update-page-dropdown`.
- **Apply stages, Save publishes.** The settings panel says "Changes are staged here. Click Save in the toolbar to publish them."
  - Editing a setting and clicking **Apply** doesn't change the preview.
  - **Save** reloads the whole iframe.
  - **Adding** a block inserts it into the existing page with no reload. Reordering shows immediately. A staged **delete** hides the block's wrapper with `display: none`.
- **Every `<script>` inside `<body>` is removed after load.** Scripts that already ran keep working, but nothing can read a body `<script>` later (inline JSON config, `document.currentScript` lookups). `<head>` scripts are left alone, so put editor-detection and config scripts there.

### Pitfalls

1. **`vh` / `dvh` sections grow without limit in Full page mode.** In Full page mode the frame is sized to the document, so `min-height: 100vh` (or `dvh`) grows with the frame. A hero measured **69,394px tall**, with its text pushed out of view.
   - The editor tries to rewrite viewport units, but it can't read stylesheets served from the Blutui CDN (`asset()` → `cdn.blutui.com`). Reading their rules throws a `SecurityError` because they're cross-origin, so their `vh` values are never rewritten.
   - Fix: never use raw `vh` for section heights. Use a custom property with a fallback, set from `blutui_editor_vh` in a `<head>` script (see the pattern below): `min-height: var(--screen-h, 100dvh);`

2. **Links navigate the preview, and other sites break it.** Clicking a link makes the editor route the preview to its `href` (`route-change`). Links with `target="_blank"` are skipped. **An absolute link to another site loads that site into the frame. A site that refuses to be framed (rga.com did) shows a broken-page icon, and editing stops.**
   - Fix: in the editor, set `target="_blank"` on links to other origins and call `preventDefault()` in a capture listener. Block selection still works.

3. **Stopping click propagation breaks the editor's link handling.** The editor listens for link clicks on `document`. When a site handler on an ancestor calls `stopPropagation()`, the editor never sees the click. The browser then navigates the frame normally, and the preview **drops out of editor mode**: the editor params, the block wrappers and the editor script are all gone.
   - Fix: don't `stopPropagation()` on clicks that can reach a link. Use `preventDefault()` when you only need to cancel the navigation.

4. **Clicking inside a block selects it, so widgets don't respond.** Clicking an accordion header in the preview opened the block's settings panel instead of the accordion. Accordions, tabs, sliders and "load more" buttons can't be operated while editing.
   - Fix: make the default state show the content editors need to see, or add a setting such as "Open first item". Don't hide editable content behind an interaction.

5. **Content hidden until JS reveals it can stay hidden.** A hero using `opacity: 0` plus an IntersectionObserver rendered invisible after a preview reload. The editor force-shows only `[data-aos]`, `[data-sal]` and `.wow` (opacity 1, no transform). Custom reveal attributes and classes stay hidden.
   - Fix: in the editor, show everything immediately (`.is-canopy-editor [data-reveal] { opacity: 1; transform: none; }`) and skip the observer.

6. **A fixed header covers whatever block an editor moves to the top.** The design assumed a hero with large top padding always comes first. A Careers CTA dragged to the top sat under the fixed header.
   - Fix: offset any first block that isn't designed to sit under the header, in both the public markup and the editor wrapper. For example: `#main > h1 + section:not(.hero), #main > h1 + [data-canopy-block] > section:not(.hero) { margin-top: <header height>; }`

7. **`transitionend` never fires in Full page mode.** Full page mode sets transition durations to `0s`, so no `transitionend` event fires. Code that waits for it, such as an accordion switching to `height: auto`, gets stuck. Animations are shortened to `0.001s`, so `animationend` still fires. Screen mode keeps normal durations.
   - Fix: always pair `transitionend` with a timeout fallback.

8. **Blocks added in the editor miss one-shot initialisation.** A staged add inserts the new block into the running page with no reload. Code that only runs once on `DOMContentLoaded` never sets up the new block.
   - Fix: write each feature's setup per root and make it safe to repeat (mark what's set up). Watch `#main` with a MutationObserver and run setup on added nodes. Prefer event delegation from the block root.

9. **Autoplaying media keeps playing in the preview.** A muted autoplay video ran in the editor, so content moved under the cursor while editors tried to select it.
   - Fix: in the editor, remove `autoplay`, call `pause()`, and don't start timers that move or re-render content.

10. **`canopy.blocks(area, [templates])` is a seed, not a lock.** Until an editor saves, the area renders those templates with their defaults. Editors can still add, reorder and delete blocks, and after Save the saved editor state renders on the public page (an added block and the new order both appeared).
    - Use the list to ship a page that looks complete before anyone edits it. Use plain `canopy.blocks('main')` when the page should start empty.
    - Add `{ locked: true }` only when the structure really must not change.

11. **The site errors for about a minute after `courier push`.** While files sync, requests intermittently returned **HTTP 500** ("Something's gone wrong", `file_get_contents(…/views/layouts/home.canvas): Failed to open stream: No such file or directory`). Errors came and went for roughly a minute after the push finished, then stopped.
    - That's propagation, not broken code. Wait a minute and reload before debugging.

### Detecting the editor

Blutui doesn't document a Canvas variable or JS API for "in the editor". The `blutui_editor` query param on the frame URL works. If Blutui adds a supported flag, prefer it.

### Defensive pattern

`templates/default.canvas`, in `<head>`, so it runs before first paint and isn't removed with the body scripts:

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

function initVideos(root) {
  each(root, 'video[autoplay]', 'video', (v) => { if (EDITOR) { v.removeAttribute('autoplay'); v.pause() } })
}

function initReveal(root) {
  each(root, '[data-reveal]', 'reveal', (el) => {
    if (EDITOR) return el.classList.add('is-revealed')
    observeReveal(el)
  })
}

// Links to other origins: the editor skips target="_blank", so the preview stays on the page being edited.
const isExternal = (a) => { try { return new URL(a.href).origin !== location.origin } catch { return false } }
function guardLinks(root) {
  if (!EDITOR) return
  each(root, 'a[href]', 'link-guard', (a) => { if (isExternal(a)) a.target = '_blank' })
}
if (EDITOR) document.addEventListener('click', (e) => {
  const a = e.target.closest?.('a[href]')
  if (a && isExternal(a)) e.preventDefault()   // never stopPropagation (pitfall 3)
}, true)

const FEATURES = [guardLinks, initReveal, initVideos /*, … */]
function init(root) {
  FEATURES.forEach((fn) => { try { fn(root) } catch (e) { console.error(fn.name, e) } })
}

document.addEventListener('DOMContentLoaded', () => {
  init(document)
  // Blocks added in the editor arrive without a reload (pitfall 8).
  new MutationObserver((ms) => ms.forEach((m) => m.addedNodes.forEach((n) => n.nodeType === 1 && init(n))))
    .observe(document.getElementById('main') || document.body, { childList: true, subtree: true })
})
```

For transitions: pair every `transitionend` with `setTimeout(finish, durationMs + 100)` (pitfall 7).
