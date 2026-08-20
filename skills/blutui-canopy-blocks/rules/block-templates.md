---
title: Block Templates
impact: CRITICAL
impactDescription: Block templates define every section editors can add to a page. An invalid config section or missing template section silently breaks the block in the Canopy editor.
tags: block templates, config, canopy sections
---

## Block Templates

### File structure

Block templates live in the `canopy` folder inside the project's `views` directory. Each template is a single `.canvas` file. The filename becomes the template's name unless the config sets a `name`:

```
views/
└── canopy/
    ├── hero.canvas
    ├── features.canvas
    └── cta.canvas
```

Every template in `views/canopy/` automatically appears in the Canopy editor for editors to add — don't put work-in-progress or internal-only templates there unless they're ready for editors, or set `"hidden": true` in their config to keep them out of the Add Block picker.

### Sections

A block template is made of named sections wrapped in `{% canopy %}` / `{% endcanopy %}` tags. Sections can appear in **any order**:

| Section    | Required | Description                                                            |
| ---------- | -------- | ---------------------------------------------------------------------- |
| `config`   | no       | JSON object describing the block and the settings editors can change  |
| `template` | **yes**  | Canvas code rendered for each block                                   |
| `head`     | no       | Markup added to the page head when the block is used                  |
| `scripts`  | no       | Markup added to the end of the page when the block is used            |

### The config section

A JSON object with these properties:

| Property              | Description                                                                     | Data Type |
| --------------------- | -------------------------------------------------------------------------------- | --------: |
| `title`               | The name of the block shown to editors in the Canopy editor                    |    String |
| `name` (optional)     | Unique identifier for the block template. Generated from the title if omitted  |    String |
| `settings` (optional) | An array of settings editors can change for each block                         |     Array |
| `hidden` (optional)   | Set to true to keep the template out of the Add Block picker                   |   Boolean |

**`hidden` blocks and `allow`:** a template with `"hidden": true` never appears in the Add Block picker — **unless** an area's `allow` list names it, in which case it is addable in that area only (`{{ canopy.blocks('footer', { allow: ['cta_banner'] }) }}`). Use this for special-purpose blocks that only make sense in specific areas. `hidden` is the whole story in the block config — the area-side constraints (`allow`, `limit`, `locked`) are **never** written in block config; they belong exclusively on the `canopy.blocks()` area call (see `rules/rendering.md`).

**The config section must be valid JSON:**

- Keys and string values use double quotes — never single quotes.
- No trailing commas.
- No comments.
- Settings with a missing `name`, a missing `type`, or an unknown `type` are **silently ignored**. A typo in a setting definition produces no error — the field simply never appears in the editor. If a setting doesn't show up, check the config JSON first.

Every setting requires a `name` and a `type`. See `rules/settings.md` for the full setting-type reference.

### The template section

The template section is regular Canvas code. It receives a `settings` variable containing the values for the block, with the editor's content merged over the defaults from the config. Each setting is available under its `name`:

```canvas
<p>{{ settings.description }}</p>
```

The shape of each value depends on the setting type — text settings give a string, while `url`, `file`, and `heading` give an object with multiple properties. `rules/settings.md` documents the value shape for every type.

### The head and scripts sections

If a block needs its own CSS or JavaScript, put it in `head` and `scripts` sections rather than inlining it in the template:

```canvas
{% canopy head %}
<link rel="stylesheet" href="/css/hero.css" />
{% endcanopy %}

{% canopy scripts %}
<script src="/js/hero.js"></script>
{% endcanopy %}
```

These are output wherever the layout calls `canopy.head(handle)` and `canopy.scripts(handle)`. Each template's head and scripts sections are included **once per area**, no matter how many blocks in the area use the same template — so they're safe for stylesheets and script tags that must not be duplicated.

### Complete example

```canvas
{% canopy config %}
{
    "title": "Hero",
    "name": "hero",
    "settings": [
        { "name": "heading", "type": "heading", "default": { "value": "Welcome to our site", "element": "h1" } },
        { "name": "description", "type": "textarea", "placeholder": "Add a short introduction..." },
        { "name": "cta", "type": "url", "label": "Call to action" }
    ]
}
{% endcanopy %}

{% canopy template %}
<section class="mx-auto max-w-7xl px-6 py-20">
  <{{ settings.heading.element }}>{{ settings.heading.value }}</{{ settings.heading.element }}>
  <p>{{ settings.description }}</p>
  {% if settings.cta.url %}
    <a href="{{ settings.cta.url }}" target="{{ settings.cta.target }}">{{ settings.cta.text }}</a>
  {% endif %}
</section>
{% endcanopy %}

{% canopy head %}
<link rel="stylesheet" href="/css/hero.css" />
{% endcanopy %}

{% canopy scripts %}
<script src="/js/hero.js"></script>
{% endcanopy %}
```

This file is the authoritative reference for block templates — only consult the [Canopy Blocks documentation](https://docs.blutui.com/docs/canopy/canopy-blocks) for something genuinely not covered here.
