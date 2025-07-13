# `devops-aws`
AWS dev and ops tools for cloud infra management.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `awscli`
* Install AWS Command Line Interface (CLI) v2, system-wide and available to all users
* Installs required dependencies (curl, unzip)
* After installation, you'll need to configure your AWS credentials using `aws configure` or `aws-congure sso`

### `qol`
* Install quality of life bits
* Adds `aws-profile` function to switch between AWS profiles easily
  * Includes intelligent bash completion that reads your actual AWS profile names
  * Usage:
    - `aws-profile <profile-name>` - Switch to specified AWS profile
    - `aws-profile` - Show current AWS profile
    - `aws-profile <TAB>` - Tab completion with your actual AWS profile names

## Build Arguments
* No additional arguments for this build
