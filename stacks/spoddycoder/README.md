# SpoddyCoder Stacks

List stacks: `./wsl-stacker.sh spoddycoder`


| Stack                             | Components                                                                                                                                                                                                     |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dev.wslb` Base development build | **system:** update, essentials, qol, apt-mirror-switch **dev:** essentials, qol, cursor **devops:** docker **dev-bash:** shellcheck, bats                                                                      |
| `devops.wslb` DevOps build        | **system:** update, essentials, qol, apt-mirror-switch **dev:** essentials, qol, cursor **devops:** docker-desktop, terraform, kubectl, k9s, packer **devops-aws:** awscli, qol **dev-bash:** shellcheck, bats |
| `dev-ai.wslb` AI build            | **system:** update, essentials, qol, apt-mirror-switch **dev:** essentials, qol, cursor **devops:** docker **dev-bash:** shellcheck, bats **ai:** cuda132, ollama **dev-python:** python3, conda               |
| `dev-js.wslb` JavaScript build    | **system:** update, essentials, qol, apt-mirror-switch **dev:** essentials, qol, cursor **devops:** docker **dev-js:** essentials, node, npm, nvm, yarn **dev-ssg:** hugo **dev-bash:** shellcheck, bats       |


