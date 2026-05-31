# SpoddyCoder stack definitions

List stacks: `./wsl-stacker.sh spoddycoder`


| Stack | Components|
| ------|---------- |
| `dev.wslb` <br/>Base development build | **system:** update, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**devops:** docker <br/>**dev-bash:** shellcheck, bats                                                                      |
| `devops.wslb `<br/>DevOps build        | **system:** update, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**devops:** docker-desktop, terraform, kubectl, k9s, packer <br/>**devops-aws:** awscli, qol <br/>**dev-bash:** shellcheck, bats |
| `dev-ai.wslb` <br/>AI build            | **system:** update, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**devops:** docker <br/>**dev-bash:** shellcheck, bats <br/>**dev-python:** python3, conda <br/>**ai:** cuda132 <br/>**ai-agents:** setup-env, langchain |
| `dev-js.wslb` <br/>JavaScript build    | **system:** update, essentials, qol, symlinks, apt-mirror-switch <br/>**dev:** essentials, cursor <br/>**devops:** docker <br/>**dev-js:** essentials, node, npm, nvm, yarn <br/>**dev-ssg:** hugo <br/>**dev-bash:** shellcheck, bats       |


