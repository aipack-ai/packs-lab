# AIPACK Lab

Here is a list of AIPACK lab packs that can be run from this repo.

You have two ways to learn these lab packs/examples.

Both require:
- AIPACK installed (see https://aipack.ai)
- API keys set in the terminal

## 1) Install and run the pack

The simplest way to run lab AI Packs is to install and run them.

For example

```sh
# good practice
mkdir my-aip-test
cd my-aip-test

# Install the lab@ako (agentic knowledge optimization)
aip install lab@ako

# Make sure to have your LLM provider API keys in the terminal

# Recommendation: Use an editor with an integrated terminal
#                 to have terminal + file explorer/viewer in one interface.

# Run the pack (make sure to have your API keys)
aip run lab@ako --xp-tui

# --xp-tui is the new Terminal UI (will be default from 0.8.0)
```

> NOTE: In the case of `lab@ako`, it will ask you to edit the generated `ako-config.jsonc` and then just press `r` to run it with your settings.

## 2) Via the lab repo

The second way is to run them via the lab repo directly.

This is a good way when you want to play with the agent code and learn how it works.

```sh
git clone https://github.com/aipack-ai/aipack-lab.git
cd aipack-lab

# Make sure to have your LLM provider API keys in the terminal

# Recommendation: Use an editor with an integrated terminal
#                 to have terminal + file explorer/viewer in one interface.

# Run the agent from folder
aip run lab/ako --xp-tui

# --xp-tui is the new Terminal UI (will be default from 0.8.0)
```

<br />

[This Repo](https://github.com/aipack-ai/aipack-lab)