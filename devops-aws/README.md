# `devops-aws`
AWS dev and ops tools for cloud infra management.

## Requires
* `Ubuntu 22.04` or greater

## Build Components
### `awscli`
* Install AWS Command Line Interface (CLI) v2, system-wide
* Installs required dependencies (curl, unzip)
* After install, you'll want to configure your AWS credentials: `aws configure sso`, or you could add a snippet...
```
mkdir -p /home/me/.aws
touch /home/me/.aws/config
echo "[profile me]" >> /home/me/.aws/config
echo "sso_session = me" >> /home/me/.aws/config
echo "sso_account_id = 1234567890" >> /home/me/.aws/config
echo "sso_role_name = DevAccess" >> /home/me/.aws/config
echo "region = us-east-1" >> /home/me/.aws/config
echo "[sso-session me]" >> /home/me/.aws/config
echo "sso_start_url = https://d-1a2b3c4d.awsapps.com/start" >> /home/me/.aws/config
echo "sso_region = us-east-1" >> /home/me/.aws/config
echo "sso_registration_scopes = sso:account:access" >> /home/me/.aws/config
```

### `qol`
* Install quality of life bits
* `aws-profile` function to switch between AWS profiles easily
  * Intelligent bash completion that reads your AWS profile names
  * Added to `~/.bashrc` 
  * Usage:
    - `aws-profile <profile-name>` - Switch to specified AWS profile
    - `aws-profile` - Show current AWS profile
    - `aws-profile <TAB>` - Tab completion with your AWS profile names

## Build Arguments
* No additional arguments for this build
