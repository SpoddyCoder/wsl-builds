#!/usr/bin/env bash
# print formatted messages

NC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

printInfo() {
    echo -e "${GREEN}INFO:${NC} $1"
}

printWarning() {
    echo -e "${YELLOW}WARN:${NC} $1"
}

printError() {
    echo -e "${RED}ERROR:${NC} $1"
}