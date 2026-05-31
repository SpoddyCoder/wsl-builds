# `ai-agents`

LangChain, LangGraph, OpenAI Agents SDK, and related tooling on a shared conda environment named `agents`.

Recommended install order: **setup-env** → **langchain** and/or **openai-agents** → optional **langchain-ollama** / **langchain-llama-cpp** for local models → **langgraph** when you need graph workflows → **langsmith** / **langfuse** for observability.

**Migration:** If you previously relied on optional prompts inside **langchain** for Ollama or llama.cpp integrations, install **langchain-ollama** and/or **langchain-llama-cpp** separately (or use a stack under `stacks/` that lists those components).

Examples:

```bash
./wsl-builder.sh ai-agents setup-env,langchain,langsmith
./wsl-builder.sh ai-agents setup-env,langchain,langchain-ollama
./wsl-builder.sh ai-agents setup-env,langchain,langchain-llama-cpp
./wsl-builder.sh ai-agents setup-env,langchain,langgraph
./wsl-builder.sh ai-agents setup-env,openai-agents
```

Pair **langchain-ollama** with `./wsl-builder.sh ai ollama`. Pair **langchain-llama-cpp** with `./wsl-builder.sh ai cuda132` (or **cuda124**) when you want GPU-backed `llama-cpp-python` wheels.

## Requires

* `Ubuntu 22.04` or greater
* `./wsl-builder.sh dev-python conda`
* For local model backends, pair with the [ai](../ai/) build (**cuda124** / **cuda132**, **ollama**, **llama-cpp**) when you need CUDA or Ollama

## Build Components

### `setup-env`

* Requires `./wsl-builder.sh dev-python conda` (Anaconda). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* Creates a conda environment named `agents` with Python 3.11 when it does not already exist.
* If an `agents` env already exists, you are prompted `Recreate existing agents conda environment` (default **N** keeps the existing env).
* Installs shared Python packages with pip: `python-dotenv`, `httpx`, `jupyter`, `pydantic`.
* After install: `conda activate agents`.

### `langchain`

* Requires **setup-env** (and thus `./wsl-builder.sh dev-python conda`). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs LangChain core with `pip install -U langchain` (transitive dependencies are pulled as needed).
* For Ollama or llama.cpp LangChain integrations, install **langchain-ollama** and/or **langchain-llama-cpp** separately.
* After install: `conda activate agents`.

### `langchain-ollama`

* Requires **setup-env**. **langchain** is recommended first.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs `langchain-ollama` with pip inside `agents`.
* If the `ollama` CLI is not on `PATH`, the script prints a warning but still installs the package. For Ollama itself, install **ollama** from the [ai](../ai/) build.
* After install: `conda activate agents`.

### `langchain-llama-cpp`

* Requires **setup-env**. **langchain** is recommended first.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs `cmake` and `build-essential` via apt, then `pip install langchain-community llama-cpp-python` inside `agents`.
* This is not the same as the **llama-cpp** component in the [ai](../ai/) build, which builds native llama.cpp binaries from source.
* When `nvcc` is available (`/usr/local/cuda/bin/nvcc` or on `PATH` after **cuda124** / **cuda132** from the [ai](../ai/) build), you are prompted whether to `Build llama-cpp-python with CUDA support` (default **Y**). **Y** sets `CMAKE_ARGS=-DGGML_CUDA=on` and `FORCE_CMAKE=1` for the pip install; **n** installs CPU-only wheels. Without `nvcc`, the install uses CPU-only wheels.
* After install: `conda activate agents`.

### `langgraph`

* Requires **setup-env**. **langchain** is recommended when you use LangChain types alongside graphs.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs LangGraph with `pip install -U langgraph` inside `agents`.
* After install: `conda activate agents`.

### `openai-agents`

* Requires **setup-env** (and thus `./wsl-builder.sh dev-python conda`). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs the official [OpenAI Agents SDK](https://openai.github.io/openai-agents-python/) with `pip install -U openai-agents` inside `agents`.
* Set your OpenAI API key in your shell (or project env file) before calling OpenAI models: `OPENAI_API_KEY` — see the [Agents SDK guide](https://developers.openai.com/api/docs/guides/agents).
* Optional pip extras (not installed by this component): `openai-agents[voice]` for voice support, `openai-agents[redis]` for Redis session support — see the [SDK repository](https://github.com/openai/openai-agents-python).
* After install: `conda activate agents`.

### `langsmith`

* Requires **setup-env**. **langchain** and/or **langgraph** are recommended when you want LangChain tracing workflows (installs the LangSmith Python SDK into the existing conda `agents` env; does not create that env).
* Requires `./wsl-builder.sh dev-python conda` (Anaconda). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs the official [LangSmith Python SDK](https://docs.smith.langchain.com/) with `pip install -U langsmith` inside `agents`.
* **LangSmith Cloud (no self-hosted server in this component):** sign up at [LangSmith](https://smith.langchain.com), create an API key under Settings, and set credentials in your shell (or project env file) before tracing:
  * `LANGSMITH_API_KEY` — API key from LangSmith Settings
  * `LANGCHAIN_TRACING_V2` — set to `true` to send LangChain runs to LangSmith (see [trace with LangChain](https://docs.smith.langchain.com/observability/how_to_guides/tracing/trace_with_langchain))
  * `LANGCHAIN_PROJECT` — optional project name for traces in the LangSmith UI
* After install: `conda activate agents`, then run LangChain apps with tracing enabled via the env vars above, or use LangSmith client APIs directly — see the [LangSmith docs](https://docs.smith.langchain.com/).

### `langfuse`

* Requires **setup-env**. **langchain** and/or **langgraph** are recommended when you want LangChain tracing workflows (installs the Langfuse Python SDK into the existing conda `agents` env; does not create that env).
* Requires `./wsl-builder.sh dev-python conda` (Anaconda). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs the official [Langfuse Python SDK](https://langfuse.com/docs/observability/sdk/overview) with `pip install -U langfuse` inside `agents`.
* **Langfuse Cloud (no self-hosted server in this component):** sign up at [Langfuse Cloud](https://cloud.langfuse.com) (Hobby free tier), create a project, and copy the project API keys. Set credentials in your shell (or project env file) before using the SDK:
  * `LANGFUSE_PUBLIC_KEY` — project public key (`pk-lf-...`)
  * `LANGFUSE_SECRET_KEY` — project secret key (`sk-lf-...`)
  * `LANGFUSE_BASE_URL` — cloud host for your data region (default EU: `https://cloud.langfuse.com`; US: `https://us.cloud.langfuse.com`; see [Langfuse docs](https://langfuse.com/docs/observability/get-started) for other regions)
* After install: `conda activate agents`, then use the SDK directly or trace LangChain runs with `from langfuse.langchain import CallbackHandler` and pass `config={"callbacks": [langfuse_handler]}` to your chain — see the [LangChain integration guide](https://langfuse.com/integrations/frameworks/langchain).

## Build Arguments

* No additional arguments for this build
