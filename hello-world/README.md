# AIPACK - Hello World Project

See the [AIPACK Tutorial Post with Video](https://news.aipack.ai/p/aipack-tutorial-from-hello-world) for a full walkthrough.

#### A Few Additions from the Video

- The `my-agent.aip` from the video has been split into `hello-world.aip` and `html-optimizer.aip` so they can be run independently.
- `hello-world.aip`
    - Uses the `gemini-flash-2.5...-zero` model from [.aipack/config.toml](./.aipack/config.toml).
    - Updated output directory to `_data-hello-world/`.
- `html-optimizer.aip`
    - Added the `# Options` stage, which allows you to configure the GenAI options for that agent only and use the full `gemini-flash-2.5...` model.
    - Updated output directory to `_data-html-optimizer/` and updated path building.

Feel free to change these models to any desired ones.

#### Usage

```sh
# If you haven't already, make sure you are in the `hello-world/` directory
cd hello-world
# Make sure you have the keys

# Run hello-world agent (with or without the .aip extension)
aip run my-agent
# Or, run with multiple inputs
aip run my-agent -i "My name is Jen" -i "I am Jon"

# Run html-optimizer
aip run html-optimizer
```