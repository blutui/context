---
title: Form Standards
impact: CRITICAL
impactDescription: Strict adherence to Blutui Form Syntax is mandatory. Non-compliant syntax causes silent failures or data submission errors, preventing the form from processing correctly within the ecosystem.
tags: form
---

## Blutui Form standards and examples

### Directory Structure

Ensure your `views` directory is organized as follows:

- `views/`
  - `components/`
    - `form.html` (Macro definitions)
  - `forms/`
    - `contact.html` (Form implementation)

#### Usage Example (in `views/components/form.html`):

```canvas
{% macro input(data) %}
  <input type="{{ data.type }}" name="{{ data.name }}" placeholder="{{ data.placeholder }}" {% if data.required %} required {% endif %} />
{% endmacro %}

{% macro field(data) %}
  <div class="field-wrapper">
    <label>{{ data.label }}</label>
    {% if data.type == 'textarea' %}
      {{ _self.textarea(data) }}
    {% else %}
      {{ _self.input(data) }}
    {% endif %}
  </div>
{% endmacro %}
```

#### Usage Example (in `views/forms/contact.html`):

```canvas
{% import 'components/form' as ui %}

{% form 'contact' %}
  {% for field in form.fields %}
    {{ ui.field(field) }}
  {% endfor %}

  <button type="submit" class="">Submit</button>
{% endform %}
```

### Form Field Constraints

- **Allowed Types:** "text", "textarea", "radio", "select", "checkbox", "url", "email", "phone", "hidden", "time", "date", "number"
- Do not attempt to use custom field types. If a type is not on this list, default to `text` and notify the user.
- Always transmit field types to the MCP in lowercase format.

### MCP Workflow

Run `list_forms` first to confirm no form with the same handle exists, then use `create_form` to register the form. Use `list_submissions` or `retrieve_submission` to access submitted data.

Reference: [Link to documentation](https://docs.blutui.com/guides/create-form)
