---
title: Menus
impact: HIGH
impactDescription: Navigation Impact - Menus are the primary way to render site navigation. Incorrect usage breaks header and footer navigation across every page.
tags: menu, navigation, header, footer, dropdown
---

## Menus

Menus are managed in the Blutui dashboard and accessed in templates via `cms.menu('handle')`. Use them for all site navigation — never hardcode nav links in templates.

### Basic Usage

```canvas
{% set nav = cms.menu('main') %}
<ul>
  {% for item in nav.items %}
    <li><a href="{{ item.href }}">{{ item.label }}</a></li>
  {% endfor %}
</ul>
```

### Dropdown / Nested Navigation

Menu items can have children for dropdown menus. Check `item.items` before rendering a dropdown:

```canvas
{% set nav = cms.menu('main') %}
{% for item in nav.items %}
  {% if item.items %}
    <div>
      <button>{{ item.label }}</button>
      <ul>
        {% for child in item.items %}
          <li><a href="{{ child.href }}">{{ child.label }}</a></li>
        {% endfor %}
      </ul>
    </div>
  {% else %}
    <a href="{{ item.href }}">{{ item.label }}</a>
  {% endif %}
{% endfor %}
```

### Common Menu Handles

Projects typically have multiple menus for different regions:

```canvas
{% set nav = cms.menu('main') %}       {# Primary navigation #}
{% set footer = cms.menu('footer') %}  {# Footer navigation #}
```

### MCP Workflow

- Run `list_menus` before `create_menu` to avoid duplicates.
- Use `create_menu` to register a new menu in the dashboard.
- After creating a menu, add items via the dashboard or the relevant MCP tool.

Reference: [Link to documentation](https://docs.blutui.com/docs/menus/getting-started)
