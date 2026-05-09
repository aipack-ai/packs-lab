# ssite Orchestration

This document defines the configuration and workflow for using `ssite` to orchestrate development and deployment in an `aipack-site` project.

## Overview

`ssite` is the high-level tool that bridges the gap between build artifacts (in `content/`) and the final distributed site (in `_site/`). It handles:
- Static asset management.
- Development runner orchestration (watchers, servers).
- Deployment to cloud storage (e.g., S3).

## Configuration (ssite.toml)

The `ssite.toml` file at the project root defines the source, destination, and execution environment.

### Source and Distribution

The `[source]` section defines where `ssite` looks for input and where it writes the final output.

```toml
[source]
content_dir = "content/"
dist_dir = "_site"
```

### Development Runners

Runners allow `ssite` to manage background processes for development.

- **CSS Runner**: Triggers the CSS watch mode (typically via the project's build orchestrator).
- **WebDev Runner**: Serves the distribution directory locally.

```toml
[runner.css]
cmd = "npm"
watch_args = ["run", "watch"]

[runner.webhere]
run_on = ["Dev"]
cwd = "./_site"
cmd = "webdev"
args = ["-l", "--public"]
```

### Deployment (Publish)

The `[publish]` section contains the credentials and target for deployment.

```toml
[publish]
bucket_type = "s3"
bucket_name = "your-bucket-name"
bucket_cred_type = "profile"
bucket_cred_profile = "your-aws-profile"
```

## Development Workflow

1. **Start Watch Mode**: Run the development command (e.g., `ssite dev`).
2. `ssite` starts the defined runners.
3. The CSS runner starts the project's `scripts/build.js -w`, which manages JS/TS (via Rolldown) and CSS (via Lightning CSS).
4. The web runner serves the `_site/` directory.
5. As files change in `src/` or `css/`, they are built into `content/`.
6. `ssite` detects changes in `content/` and updates `_site/`.

## Deployment Workflow

1. **Production Build**: Execute a one-time build to ensure all artifacts in `content/` are up to date.
2. **Publish**: Run `ssite publish`.
3. `ssite` synchronizes the `_site/` directory with the configured cloud bucket.
