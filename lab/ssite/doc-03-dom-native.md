# dom-native Integration

This document defines the standards for building Web Components using the `dom-native` library within the `aipack-site` architecture.

## Overview

The `dom-native` library provides a thin, opinionated layer over native browser APIs, focusing on:
- Native custom elements via `BaseHTMLElement`.
- Safe event binding and cleanup.
- Lightweight pub/sub via hubs.
- Direct DOM-first rendering patterns.

## Component Naming Conventions

To ensure clarity and avoid collisions with standard HTML elements or other logic files, custom elements must follow a suffix-based naming pattern:

- **`-v`**: Views (e.g., `home-v`, `settings-v`). These are typically top-level page components.
- **`-c`**: General components (e.g., `button-c`, `card-c`). Reusable UI elements.
- **`-popup`**: Overlays and modals (e.g., `login-popup`, `confirm-popup`).

## BaseHTMLElement and Lifecycle

Every custom element should extend `BaseHTMLElement`. This base class manages lifecycle hooks and automatic event cleanup.

### Lifecycle Hooks

- **`init()`**: Called once when the element is first connected. Use it for one-time DOM creation, cloning templates, and caching key elements.
- **`preDisplay(firstCall: boolean)`**: Called synchronously during `connectedCallback`. Use it for final state-to-DOM updates before the first paint.
- **`postDisplay(firstCall: boolean)`**: Called in `requestAnimationFrame`. Use it for async loading, measurements, or post-render work.

## Standard Component Pattern

The recommended pattern for creating components involves declaring static structure at the module scope and cloning it during initialization.

```typescript
import { BaseHTMLElement, customElement, first, html } from "dom-native";

const HTML = html`
<section class="profile-v">
	<h2 class="title"></h2>
	<div class="content"></div>
</section>
`;

@customElement("profile-v")
export class ProfileView extends BaseHTMLElement {
	#titleEl!: HTMLElement;

	init() {
		// Clone the module-level fragment
		const content = document.importNode(HTML, true);
		// Query and cache key nodes
		this.#titleEl = first(content, ".title")!;
		// Attach to the DOM
		this.replaceChildren(content);
	}

	postDisplay() {
		this.refresh();
	}

	refresh() {
		this.#titleEl.textContent = "Profile Title";
	}
}
```

## Event and Hub Binding

### DOM Event Decorators

Use decorators for clean, declarative event binding. `BaseHTMLElement` automatically handles the binding and unbinding based on the component's lifecycle.

- **`@onEvent(type, selector?)`**: Binds to the element itself (or `shadowRoot` if present).
- **`@onDoc(type, selector?)`**: Binds to the `document`.
- **`@onWin(type)`**: Binds to the `window`.

### Hub Event Decorator

Use `@onHub` for reacting to application-level events via the `dom-native` hub system.

- **`@onHub(hubName, topic, label?)`**: Subscribes a method to a specific hub topic/label.

### TypeScript Requirement

To use these decorators, `experimentalDecorators` must be enabled in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "experimentalDecorators": true
  }
}
```

## Best Practices

- **Keep Handlers Thin**: Event and hub handlers should typically call a focused `refresh()` or action method rather than containing complex logic.
- **Namespace Cleanup**: `BaseHTMLElement` uses the component's unique namespace for cleanup. If manually binding root events, ensure they are namespaced or cleaned up in `disconnectedCallback`.
- **DOM Builders**: Use `html`, `elem`, and `frag` helpers to keep DOM manipulation readable and efficient.
