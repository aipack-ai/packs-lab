# Site Creation Standards

## Overview

This set of documents defines the standards and best practices for creating and maintaining sites using the `aipack-site` architecture. This architecture is built on a "DOM-first" and "Native-first" philosophy, leveraging modern browser primitives and a high-performance, minimal toolchain.

### Core Goals

- **Performance**: Minimal overhead using modern bundling tools like `rolldown` and `lightningcss`.
- **Native-first**: Use native Web Components and DOM APIs via `dom-native`.
- **Simplicity**: Clear separation between source, content, and distribution.
- **Maintainability**: Consistent project structure and naming conventions.

## Documentation Map

- **[doc-01-structure.md](doc-01-structure.md)**: Project Directory Structure
  Overview of the root layout, the dual role of the `content/` directory, and git management.

- **[doc-02-toolchain.md](doc-02-toolchain.md)**: Build Toolchain
  Configuration for `rolldown`, `lightningcss`, and the `scripts/build.js` orchestrator.

- **[doc-03-dom-native.md](doc-03-dom-native.md)**: dom-native Integration
  Standards for `BaseHTMLElement`, custom element naming, and event/hub binding.

- **[doc-04-ssite.md](doc-04-ssite.md)**: ssite Orchestration
  Deployment and local development workflows using `ssite.toml`.

- **[doc-05-cdk.md](doc-05-cdk.md)**: Infrastructure as Code (AWS CDK)
  Infrastructure provisioning for S3, CloudFront, and Route 53.

## Runtime Requirement

- **Node.js**: 25.9 or higher (required for modern ESM and build features).
