#!/usr/bin/env bash

SCRIPT_DIR="db"

if [ -n "$INSTALL_MYSQL_CLIENT" ]; then
    if ! isComponentInstalled "mysql-client" "$@"; then
        # shellcheck source=db/install_mysql_client.sh
        source ${SCRIPT_DIR}/install_mysql_client.sh
        recordComponentSuccess "mysql-client"
    else
        warnComponentAlreadyInstalled "mysql-client"
    fi
fi

if [ -n "$INSTALL_MYSQL_SERVER" ]; then
    if ! isComponentInstalled "mysql-server" "$@"; then
        # shellcheck source=/dev/null # install_mysql_server.sh not yet implemented
        source ${SCRIPT_DIR}/install_mysql_server.sh
        recordComponentSuccess "mysql-server"
    else
        warnComponentAlreadyInstalled "mysql-server"
    fi
fi

if [ -n "$INSTALL_POSTGRES_CLIENT" ]; then
    if ! isComponentInstalled "postgres-client" "$@"; then
        # shellcheck source=/dev/null # install_postgres_client.sh not yet implemented
        source ${SCRIPT_DIR}/install_postgres_client.sh
        recordComponentSuccess "postgres-client"
    else
        warnComponentAlreadyInstalled "postgres-client"
    fi
fi

if [ -n "$INSTALL_POSTGRES_SERVER" ]; then
    if ! isComponentInstalled "postgres-server" "$@"; then
        # shellcheck source=/dev/null # install_postgres_server.sh not yet implemented
        source ${SCRIPT_DIR}/install_postgres_server.sh
        recordComponentSuccess "postgres-server"
    else
        warnComponentAlreadyInstalled "postgres-server"
    fi
fi
