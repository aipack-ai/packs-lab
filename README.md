# AIPACK Lab - Project Examples

Here is a list of AIPACK lab packs that can be ran from this repo. 

First, git clone this repo 
- `https://github.com/aipack-ai/aipack-lab.git`
Then, get into it
- Simplest option: Open this dir with IDE and integrated terminal
- In the integrated terminal
    - Make sure to have the API keys of the model provider you want to use. 
- do a `aip init .` to initial the root directory as the aiapack workspace `.aipack/` folder should be created. 

And then, a good first pack to start with is `ako` (Agentic Knowledge Optimizer)

```sh
aip run lab/ako --xp-tui
```

_`--xp-tui` is for the new Terminal UI (experimental in 0.7.x, will become default in 0.8.x)_

