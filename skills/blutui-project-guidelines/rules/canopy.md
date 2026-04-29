---
title: Canopy
impact: MEDIUM
impactDescription: Editor Integration - Critical for CMS-to-Frontend interactivity. Canopy allows developers to register components as editable assets; failure to implement correctly disables the in-page editing interface for the user.
tags: in-page editor
---

## Canopy

Canopy is Blutui's in-page editor. Canopy elements define editable regions in a layout so content editors can manage text, images, buttons, and more directly from the dashboard without touching code.

**Important:** Canopy elements are **page-specific** — their content is tied to the page they appear on. For reusable global content (e.g. footer text, announcement banners), use a Collection instead.

Each Canopy element requires a **unique handle** as its first argument. Handles must be unique within each page.

### Available Elements

#### `cms_text(name, options?)`

Editable text content.

| Argument | Required | Description |
| -------- | -------- | ----------- |
| `name` | yes | Unique handle |
| `value` | no | Default text content |
| `class` | no | CSS classes |

```canvas
{{ cms_text('text-description', {
  value: 'Lorem ipsum dolor sit amet.',
  class: 'text-lg text-slate-600'
}) }}
```

---

#### `cms_heading(name, options?)`

Editable heading (h1–h6). The element renders its own HTML tag.

| Argument | Required | Description |
| -------- | -------- | ----------- |
| `name` | yes | Unique handle |
| `element` | no | HTML tag: `h1`, `h2`, `h3`, `h4`, `h5`, `h6` |
| `value` | no | Default heading text |
| `class` | no | CSS classes |

```canvas
{{ cms_heading('heading-hero', {
  element: 'h1',
  value: 'Welcome to Our Site',
  class: 'text-3xl md:text-5xl font-semibold'
}) }}
```

---

#### `cms_image(name, options?)`

Editable image. Renders an `<img>` tag.

| Argument | Required | Description |
| -------- | -------- | ----------- |
| `name` | yes | Unique handle |
| `url` | no | Default image URL |
| `alt_text` | no | Alt text for accessibility and SEO |
| `class` | no | CSS classes |

```canvas
{{ cms_image('image-hero', {
  url: 'https://placehold.co/1200x900',
  alt_text: 'Hero Image',
  class: 'w-full h-auto object-cover'
}) }}
```

---

#### `cms_button(name, options?)`

Editable link styled as a button.

| Argument | Required | Description |
| -------- | -------- | ----------- |
| `name` | yes | Unique handle |
| `text` | no | Button label |
| `url` | no | Button href |
| `opens_new_tab` | no | `true` to open in a new tab |
| `class` | no | CSS classes |

```canvas
{{ cms_button('button-cta', {
  text: 'Get Started',
  url: '#contact',
  opens_new_tab: false,
  class: 'inline-flex items-center bg-slate-900 text-white px-5 py-3'
}) }}
```

---

For `cms_list`, `cms_quote`, and `cms_code` — use `search_blutui_documentation` to get their full signatures and options.

### Complete Example

```canvas
{% block body %}
<section class="bg-white text-slate-900">
  <div class="mx-auto max-w-7xl px-6 py-20">
    {{ cms_heading('heading-hero', {
      element: 'h1',
      value: 'Welcome to Our Site',
      class: 'text-3xl md:text-5xl font-semibold'
    }) }}

    {{ cms_text('text-description', {
      value: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      class: 'text-lg text-slate-600'
    }) }}

    {{ cms_button('button-cta', {
      text: 'Get Started',
      url: '#contact',
      opens_new_tab: false,
      class: 'inline-flex items-center bg-slate-900 text-white px-5 py-3'
    }) }}

    {{ cms_image('image-hero', {
      url: 'https://placehold.co/1200x900',
      alt_text: 'Hero Image',
      class: 'w-full h-auto object-cover'
    }) }}
  </div>
</section>
{% endblock %}
```

### Usage Notes

- Only use Canopy elements for **page-specific** content that editors need to change per page.
- Static structural elements (nav, footer chrome, layout scaffolding) should not use Canopy elements.
- For **global** or **shared** content, use a Collection.

Reference: [Link to documentation](https://docs.blutui.com/docs/canopy/getting-started)
