# Contributing
Requests, advice and PR's are welcome. 

Only two rules for PR submissions;

1. The PR fixes a bug, security flaw, addresses an open issue or adds a new feature that is inline with the project and its ethos.
2. It is your responsibility to have reviewed AI generated changes before submitting a PR. Human readable docs and code are very important.

## Things To Note
* Simple by design
* This is not a package manager!
* Ultimately, this is just a collection simple bash scripts to install / configure common components and useful helpers.
  * Saves looking up install instructions
  * Automates the install procedure
  * Acts as an NB for quality of life additions

### Linting
* Bash scripts are linted with [ShellCheck](https://www.shellcheck.net/).
* `./test/lint.sh` — lint the whole repo
* `./test/lint.sh path/to/script.sh` — lint specific files
* Install ShellCheck `./wsl-builder.sh dev-bash shellcheck`

### Testing
* [Bats](https://bats-core.readthedocs.io/en/stable/) is used as a testing framework for the bash scripts.
* Bats tests are run in an isolated Docker container for safety and consistency.
* `./test/run-tests.sh` to run all tests.
* See **[`test/README.md`](test/README.md)** for more info.
* Install Bats `./wsl-builder.sh dev-bash bats`

### CI
* Lint + Bats tests are run on every push and PR.
* See: [`.github/workflows`](.github/workflows)

### Automated Component Reviews
* Requirements: `jq,curl` (`./wsl-builder.sh dev essentials`)
* [Docs](review/README.md).

---

## Contributing builds / components
* Each registered component’s install script is `builds/<build-dir>/<slug>/install.sh` (CSV token hyphens map to underscores in `slug`); build roots hold `conf.sh`, top-level `install.sh`, and `README.md` only. See [.cursor/rules/bash-component-patterns.mdc](.cursor/rules/bash-component-patterns.mdc).
* This project is AI assisted. With human controlled quality and structure. Human readable docs and code are very important.
* [Rules](./.cursor/rules) help the AI agent understand the project and its conventions.
* In almost all cases, you can simply ask the AI agent to use the [skills](./.cursor/skills) to add new things.
  * [add-wsl-build-dir](./.cursor/skills/add-wsl-build-dir/SKILL.md)
  * [add-wsl-build-component](./.cursor/skills/add-wsl-build-component/SKILL.md)
  * [review-wsl-build-component](./.cursor/skills/review-wsl-build-component/SKILL.md)
  * [spitball-new-feature](./.cursor/skills/spitball-new-feature/SKILL.md)
* In addition to adding the new builds / components, it should automatically take care of docs and tests etc.
* If you want to understand the project architecture (it's pretty simple tbh), ask the AI agent for an overview.
  * Or review the [Cursor rules and skills files directly](./.cursor).

---

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
