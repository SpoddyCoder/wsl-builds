# SpoddyCoder stack definitions

List stacks: `./wsl-stacker.sh spoddycoder`

| Stack | Components |
| ------|---------- |
| `dev.wslb` <br/>Base development build | **system:** update, systemd, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**dev-bash:** shellcheck, bats <br/>**devops:** docker |
| `dev-js.wslb` <br/>JavaScript build | **system:** update, systemd, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**dev-bash:** shellcheck, bats <br/>**dev-js:** essentials, node, npm, nvm, yarn <br/>**dev-ssg:** hugo <br/>**devops:** docker |
| `dev-ai.wslb` <br/>AI build | **system:** update, systemd, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**dev-bash:** shellcheck, bats <br/>**dev-python:** python3, conda <br/>**devops:** docker <br/>**ai:** cuda132 |
| `dev-ai-agents.wslb` <br/>AI agents build | **system:** update, systemd, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**dev-bash:** shellcheck, bats <br/>**dev-python:** python3, conda <br/>**devops:** docker <br/>**ai:** cuda132, llama-cpp, huggingface-cli <br/>**ai-agents:** setup-env, langchain, langraph, langchain-llama-cpp, langsmith, langfuse, openai-agents, mcp, mcp-inspector |
| `devops.wslb` <br/>DevOps build | **system:** update, systemd, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**dev-bash:** shellcheck, bats <br/>**devops-aws:** awscli, qol <br/>**devops:** docker-desktop, terraform, kubectl, k9s, packer |
