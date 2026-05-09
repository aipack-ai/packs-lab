# ssite Site Standard

## Overview

This directory contains the standards and best practices for building modern, high-performance web sites using the `ssite` architecture. The core philosophy is "DOM-first" and "Native-first", leveraging modern browser capabilities and a minimal, fast toolchain.

## Key Principles

- **Native First**: Rely on standard DOM APIs and Web Components (`dom-native`).
- **Minimal Toolchain**: Use high-performance tools like `rolldown` and `lightningcss`.
- **Fast Feedback**: Optimized build and watch cycles for immediate developer feedback.
- **Explicit Content Lifecycle**: Clear separation between source (`src/`, `css/`), staging (`content/`), and distribution (`_site`).

## Documentation Map

- **[doc-01-structure.md](doc-01-structure.md)**: Directory and file organization. Defines the role of `src/`, `css/`, `content/`, and `_site`.
- **[doc-02-toolchain.md](doc-02-toolchain.md)**: Build system and toolchain configuration. Details Node requirements (25.9), `rolldown`, and `lightningcss`.
- **[doc-03-dom-native.md](doc-03-dom-native.md)**: `dom-native` integration. Standard component patterns, naming conventions, and lifecycle management.
- **[doc-04-ssite.md](doc-04-ssite.md)**: `ssite` orchestration. Configuration and deployment patterns via `ssite.toml`.

## Runtime Requirements

- **Node.js**: 25.9 or higher (required for modern ESM and build orchestrator features).
