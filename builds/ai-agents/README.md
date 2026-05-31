# `ai-agents`

LangChain and agent tooling on a shared conda environment named `agents`.

Recommended install order: **setup-env** → **langchain** → **langsmith** / **langfuse**.

Example:

```bash
./wsl-builder.sh ai-agents setup-env,langchain,langsmith
```

## Requires

* `Ubuntu 22.04` or greater
* `./wsl-builder.sh dev-python conda`
* For optional LangChain integrations with local models, pair with the [ai](../ai/) build (**cuda124** / **cuda132**, **ollama**, **llama-cpp**) when you need CUDA or Ollama backends

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
* Installs LangChain with `pip install -U langchain` (core dependencies are pulled transitively).
* Optional Ollama integration: when you accept `Install LangChain Ollama integration (langchain-ollama)`, the install runs `pip install langchain-ollama`. If the `ollama` CLI is not on `PATH`, the script prints a warning but still installs the package. For Ollama itself, install **ollama** from the [ai](../ai/) build.
* Optional llama.cpp integration: when you accept `Install LangChain llama.cpp integration (langchain-community and llama-cpp-python)`, the install adds `cmake` and `build-essential`, then `pip install langchain-community llama-cpp-python`. This is not the same as the **llama-cpp** component in the [ai](../ai/) build, which builds native llama.cpp binaries from source.
* When `nvcc` is available (`/usr/local/cuda/bin/nvcc` or on `PATH` after **cuda124** / **cuda132** from the [ai](../ai/) build), accepting the llama.cpp integration prompts whether to `Build llama-cpp-python with CUDA support` (default **Y**). **Y** sets `CMAKE_ARGS=-DGGML_CUDA=on` and `FORCE_CMAKE=1` for the pip install; **n** installs CPU-only wheels.
* After install: `conda activate agents`.

### `langsmith`

* Requires **setup-env**. **langchain** is recommended when you want LangChain tracing workflows (installs the LangSmith Python SDK into the existing conda `agents` env; does not create that env).
* Requires `./wsl-builder.sh dev-python conda` (Anaconda). Exits with an error if `~/anaconda3/etc/profile.d/conda.sh` is missing.
* If the `agents` conda env does not exist, exits with an error pointing to `./wsl-builder.sh ai-agents setup-env`.
* Installs the official [LangSmith Python SDK](https://docs.smith.langchain.com/) with `pip install -U langsmith` inside `agents`.
* **LangSmith Cloud (no self-hosted server in this component):** sign up at [LangSmith](https://smith.langchain.com), create an API key under Settings, and set credentials in your shell (or project env file) before tracing:
  * `LANGSMITH_API_KEY` — API key from LangSmith Settings
  * `LANGCHAIN_TRACING_V2` — set to `true` to send LangChain runs to LangSmith (see [trace with LangChain](https://docs.smith.langchain.com/observability/how_to_guides/tracing/trace_with_langchain))
  * `LANGCHAIN_PROJECT` — optional project name for traces in the LangSmith UI
* After install: `conda activate agents`, then run LangChain apps with tracing enabled via the env vars above, or use LangSmith client APIs directly — see the [LangSmith docs](https://docs.smith.langchain.com/).

### `langfuse`

* Requires **setup-env**. **langchain** is recommended when you want LangChain tracing workflows (installs the Langfuse Python SDK into the existing conda `agents` env; does not create that env).
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
