---
title: File Structure
impact: CRITICAL
impactDescription: Structural Integrity - Adherence to the Blutui file structure is mandatory. Deviating from these conventions breaks core system compatibility, rendering the project non-functional and preventing deployment.
tags: project, file structure, public, views, assets, layouts, templates, components
---

## File structure

### "/public" directory

Store assets including compiled JS/CSS, images and static PDFs.

### "/views" directory

This folder is the primary environment for UI development. Follow these sub-directory conventions:

- "templates/": Has files with reusable design bases and system views.
  - "default.html": The foundational template for a Blutui project. This file forms the outermost structure of a Blutui project. It features essential sections like the head, where style definitions reside, and the body, where content gets placed. The most efficient way to build upon this file is by using inheritance, capitalising on the block tag.
  - "404.html": A template for handling "Page Not Found" errors.
- "layouts/": The layouts folder is the **only** way to create pages in a project. Each layout file maps to a page registered via the Blutui dashboard or MCP tools. **Do not create a `pages/` directory.** All page content belongs in layout files.
- "components/": Contains atomic, reusable UI fragments. Always create components for repeated UI elements (headers, footers, hero sections, CTAs, cards, etc.) and include them in layouts using `{{ include('components/filename.html') }}`.

Develop the project using a **component-first approach**. Always break the UI into reusable components in `views/components/`. Include components in layouts using `{{ include() }}` and use `{% block %}` tags for template inheritance. This minimizes duplicate work and ensures design updates stay consistent across all project views.

#### Understanding inheritance in Blutui

Hierarchy:

- Parent: templates/default.html (Defines the overall structure).
- Child: layouts/index.html (Extends the template and provides specific page content).

To implement this, ensure the child layout file begins with the `{% extends 'templates/default.html' %}` declaration. Map your content to the parent's placeholders by wrapping your HTML in matching `block` names. Include reusable components within those blocks.

#### Style System Detection

Before generating any HTML or component code, the agent must detect the project's existing style system:

1. Check for `tailwind.config.*` or `postcss.config.*` files in the project root.
2. Check for CSS framework CDN links (e.g., Bootstrap, Bulma) in `views/templates/default.html`.
3. Check for CSS files in the `/public` directory.

- If a style system is found (e.g., TailwindCSS), **always use its utility classes and conventions** in all generated HTML and components.
- If no style system is detected, **ask the user** which style approach they want before generating any HTML.
- Never generate unstyled or bare HTML when a style system is available in the project.

### Migrating a `pages/` Directory

If a `pages/` directory is found in the project, treat every file in it as a static page that needs to be migrated to the Blutui layout system. Follow this sequence for each file:

1. **Create a layout file** — Copy the page content into a new file at `views/layouts/<page-name>.html`. Wrap the content in the correct template inheritance structure:

```canvas
{% extends 'templates/default.html' %}

{% block content %}
  {# content from the original page file goes here #}
{% endblock %}
```

2. **Register the page via MCP** — Run `list_pages` first to confirm no page with the same handle already exists, then call `create_page` with the layout path relative to `views/` (e.g. `layouts/about.html`).

3. **Delete the original file** — Once the layout is created and the page is registered, remove the file from `pages/`.

4. **Repeat** until the `pages/` directory is empty, then delete the directory itself.

Never leave a `pages/` directory in the project. If the migration cannot be completed in one pass, notify the user of which files remain.

Reference: [Link to documentation](https://docs.blutui.com/docs/getting-started/folder-structure)
