# `db`
Database development and server tools.

## Requires
* `Ubuntu 22.04` or greater

## Build Components

### `mysql-client`
* Installs MySQL client tools via apt package manager
* Command line tools for connecting to MySQL databases
* Development utilities for MySQL database management

### `mysql-server`
* Installs MySQL server via apt package manager
* Full MySQL database server installation
* Includes configuration and service management
* After install, if the systemd manager is running and `mysql.service` is present, you are optionally prompted to `systemctl disable --now mysql` so the server stops immediately if running and does not start on boot (default **Y**)

### `postgres-client`
* Installs PostgreSQL client tools via apt package manager
* Command line tools for connecting to PostgreSQL databases
* Development utilities for PostgreSQL database management

### `postgres-server`
* Installs PostgreSQL server via apt package manager
* Full PostgreSQL database server installation
* Includes configuration and service management
* After install, if the systemd manager is running, you are optionally prompted to `systemctl disable --now` the `postgresql@<version>-<cluster>` unit derived from the **first row** of `pg_lsclusters` (typical fresh install: one default cluster; default **Y**). Multiple pre-existing clusters are not enumerated individually

## Build Arguments
* No additional arguments for this build 