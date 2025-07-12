# `devops-aws`
AWS dev and ops tools for cloud infra management.

## Requires
* `Ubuntu 22.04` or greater

## Build Options
### `awscli`
* Install AWS Command Line Interface (CLI) v2
* Installs required dependencies (curl, unzip)

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

## Usage Examples
```bash
# Install AWS CLI only
./build.sh devops-aws awscli

# Install quality of life improvements only
./build.sh devops-aws qol

# Install both AWS CLI and QOL improvements
./build.sh devops-aws awscli,qol

# After installation, configure your AWS credentials:
aws configure

# Use the aws-profile function (if qol option was installed):
aws-profile my-dev-profile
aws-profile my-prod-profile
aws-profile <TAB>  # Tab completion with your actual profiles
```

## Notes
* AWS CLI v2 is installed system-wide and available to all users
* After installation, you'll need to configure your AWS credentials using `aws configure` or `aws-congure-sso`
