---
title: Block Settings
impact: CRITICAL
impactDescription: Settings define the fields editors fill in for each block. Wrong types or unguarded value shapes produce broken markup or fields that silently never appear in the editor.
tags: settings, setting types, config
---

## Block Settings

Settings are declared in the `settings` array of a block template's config section. Their values are available in the template section through the `settings` variable, with editor content merged over defaults.

### Shared attributes

All setting types accept:

| Attribute            | Description                                                                     | Data Type |
| -------------------- | -------------------------------------------------------------------------------- | --------: |
| `name`               | **Required.** The setting identifier — accesses the value as `settings.<name>` |    String |
| `type`               | **Required.** One of the types below                                            |    String |
| `label` (optional)   | The field label shown in the Canopy editor. Generated from the name if omitted |    String |
| `default` (optional) | The value used until an editor provides one                                     |     Mixed |

A setting with a missing `name`, missing `type`, or unknown `type` is **silently ignored** — no error, the field just never appears.

### Type reference

#### `text` — single line of plain text

Value: String. Built-in default: `"New text"`. Extra attributes: `placeholder`.

```canvas
<p>{{ settings.subtitle }}</p>
```

#### `textarea` — multiple lines of plain text

Value: String, empty by default. Extra attributes: `placeholder`.

#### `richtext` — formatted text (rich text editor)

Value: **HTML String — always output with the `raw` filter**, otherwise the markup is escaped and shown as literal text. Extra attributes: `placeholder`.

```canvas
<div class="prose">{{ settings.body|raw }}</div>
```

#### `select` — dropdown of predefined options

Value: the selected option's `value` as a String. Extra attributes: `options` — an array of objects, each with a `value` and an optional `label`.

```json
{
    "name": "alignment",
    "type": "select",
    "options": [
        { "value": "left", "label": "Left" },
        { "value": "center", "label": "Center" },
        { "value": "right", "label": "Right" }
    ],
    "default": "center"
}
```

```canvas
<div class="text-{{ settings.alignment }}">...</div>
```

#### `radio` — radio buttons

Works exactly like `select`, with the same `options` attribute, but shows every option at once in the editor. Prefer `radio` for 2–4 options an editor should see at a glance; `select` for longer lists.

#### `checkbox` — on/off toggle

Value: Boolean, `false` by default.

```canvas
{% if settings.show_title %}
  <h2>{{ settings.title }}</h2>
{% endif %}
```

#### `file` — file picked from the site's assets

Extra attributes: `accept` — a MIME type filter for the picker (e.g. `application/pdf`, `image/*` style MIME types).

Value: an object —

| Property | Description            | Data Type |
| -------- | ----------------------- | --------: |
| `path`   | The file URL           |    String |
| `name`   | The filename           |    String |
| `type`   | The file's MIME type   |    String |
| `size`   | The file size in bytes |    Number |

```canvas
{% if settings.brochure.path %}
  <a href="{{ settings.brochure.path }}" download>{{ settings.brochure.name }}</a>
{% endif %}
```

#### `url` — link with editable text and target

Extra attributes: `placeholder`.

Value: an object —

| Property | Description                          | Data Type |
| -------- | ------------------------------------ | --------: |
| `url`    | The link URL                        |    String |
| `text`   | The link text                       |    String |
| `target` | The link target, `_self` or `_blank`|    String |

```canvas
<a href="{{ settings.cta.url }}" target="{{ settings.cta.target }}">{{ settings.cta.text }}</a>
```

#### `date` — date picker

Value: formatted date String. Extra attributes: `format` — the date format to store and output, defaults to `Y-m-d`.

#### `color` — color picker

Value: hex color String, `#000000` by default.

```canvas
<section style="background-color: {{ settings.background }}">...</section>
```

#### `heading` — heading with editable text and element

Extra attributes: `elements` — the elements editors can choose from, each with a `value` and an optional `label`. Defaults to `h1` through `h6`. Constrain this when the page structure demands it (e.g. only `h2`/`h3` for mid-page sections).

Value: an object —

| Property  | Description                    | Data Type |
| --------- | ------------------------------- | --------: |
| `value`   | The heading text               |    String |
| `element` | The HTML element, such as `h2` |    String |

```canvas
<{{ settings.heading.element }}>{{ settings.heading.value }}</{{ settings.heading.element }}>
```

#### `number` — numeric input

Value: Number. Extra attributes: `min`, `max`, `placeholder`.

#### `list` — repeatable list of text items

Value: Array of Strings, empty by default.

```canvas
<ul>
  {% for item in settings.features %}
    <li>{{ item }}</li>
  {% endfor %}
</ul>
```

#### `media-sources` — media files for HTML5 audio/video

Value: Array of objects, each with a `url` and a `type` (the MIME type). Extra attributes: `placeholder`.

```canvas
<video controls>
  {% for source in settings.video_sources %}
    <source src="{{ source.url }}" type="{{ source.type }}" />
  {% endfor %}
</video>
```

### Choosing types

- Single line of copy → `text`; paragraph → `textarea`; formatted body content → `richtext`
- A link or button → `url` (never separate `text` settings for href and label)
- Editor-controlled variants (alignment, theme, columns) → `select`/`radio` with fixed `options`, so editors can't enter invalid values
- Optional sections → `checkbox` toggle guarding the markup
- Images, PDFs, downloads → `file` with an `accept` filter
- Short repeatable items (feature bullets, tags) → `list`
- Anything more structured or shared across pages → a Collection, not block settings

Reference: [Canopy Block Settings documentation](https://docs.blutui.com/docs/canopy/canopy-block-settings)
