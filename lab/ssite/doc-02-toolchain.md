# Build Toolchain

This document defines the build system and configuration standards for `aipack-site` projects. The toolchain is designed for performance, using modern ESM and a minimal, high-speed set of tools.

## Runtime Requirement

- **Node.js 25.9 or higher**: Required for modern ESM support (`import.meta.url`), high-performance `node:fs` APIs, and the build orchestration scripts.

## Dependencies

The core toolchain relies on three primary packages:

- **rolldown**: A fast Rust-based bundler for JavaScript and TypeScript.
- **lightningcss**: A fast CSS transformer and bundler.
- **chokidar**: Used for watching CSS files in the development loop.

### package.json Scripts

```json
{
  "type": "module",
  "scripts": {
    "build": "node scripts/build.js",
    "watch": "node scripts/build.js -w"
  }
}
```

## TypeScript Configuration

`tsconfig.json` must be configured for modern ESM output and must enable experimental decorators to support the `dom-native` event and hub binding system.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "strict": true,
    "sourceMap": true,
    "esModuleInterop": true,
    "experimentalDecorators": true
  }
}
```

## JavaScript Bundling (Rolldown)

`rolldown` is used to bundle `src/main.ts` into `content/js/all-bundle.js`. The configuration uses the `iife` format for browser compatibility and includes sourcemaps.

### rolldown.config.js

```javascript
import { defineConfig } from "rolldown";

export default defineConfig({
  input: new URL("./src/main.ts", import.meta.url).pathname,
  platform: "browser",
  tsconfig: new URL("./tsconfig.json", import.meta.url).pathname,
  output: {
    file: new URL("./content/js/all-bundle.js", import.meta.url).pathname,
    format: "iife",
    sourcemap: true,
  },
});
```

## CSS Processing (Lightning CSS)

Styles are processed from `css/main.css` to `content/css/all-bundle.css`. This handles nesting, browser prefixes, and bundling of imported CSS files.

### lightningcss.config.js

The configuration uses `bundleAsync` and includes a resolver to handle external (https) imports as external links.

```javascript
import { bundleAsync } from "lightningcss";
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";

const cssInputPath = new URL("./css/main.css", import.meta.url).pathname;
const cssOutputPath = new URL("./content/css/all-bundle.css", import.meta.url).pathname;

// ... bundling logic ...
```

## Build Orchestration

A centralized orchestrator (`scripts/build.js`) manages the execution of `rolldown` and `lightningcss`.

### scripts/build.js

The orchestrator provides two primary modes:

- **One-time Build**: Executes both JS and CSS build steps sequentially.
- **Watch Mode**:
    - Delegates JS/TS watching to `rolldown -w`.
    - Uses `chokidar` to watch the `css/` directory and re-trigger the CSS build script.

### scripts/build-utils.js

This file contains utility functions for running commands and copying files, providing a consistent way to manage sub-processes across different project environments.
