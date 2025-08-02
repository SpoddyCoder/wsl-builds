#!/usr/bin/env bash

SCRIPT_DIR="db"

if [ ! -z $INSTALL_MYSQL_CLIENT ]; then
    if ! isComponentInstalled "mysql-client" "$@"; then
        source ${SCRIPT_DIR}/install_mysql_client.sh
        recordComponentSuccess "mysql-client"
    else
        warnComponentAlreadyInstalled "mysql-client"
    fi
fi

if [ ! -z $INSTALL_MYSQL_SERVER ]; then
    if ! isComponentInstalled "mysql-server" "$@"; then
        source ${SCRIPT_DIR}/install_mysql_server.sh
        recordComponentSuccess "mysql-server"
    else
        warnComponentAlreadyInstalled "mysql-server"
    fi
fi

if [ ! -z $INSTALL_POSTGRES_CLIENT ]; then
    if ! isComponentInstalled "postgres-client" "$@"; then
        source ${SCRIPT_DIR}/install_postgres_client.sh
        recordComponentSuccess "postgres-client"
    else
        warnComponentAlreadyInstalled "postgres-client"
    fi
fi

if [ ! -z $INSTALL_POSTGRES_SERVER ]; then
    if ! isComponentInstalled "postgres-server" "$@"; then
        source ${SCRIPT_DIR}/install_postgres_server.sh
        recordComponentSuccess "postgres-server"
    else
        warnComponentAlreadyInstalled "postgres-server"
    fi
fi 