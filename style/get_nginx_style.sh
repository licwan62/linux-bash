#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

function header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "=========================================="
    echo "${1}"
    echo "=========================================="
    echo -e "${NC}"
}

function step() {
    echo -e "\n${YELLOW}${BOLD}==> ${1}...${NC}"
}

function success() {
    echo -e "\n${GREEN}${BOLD}✅  ${1}${NC}"
}

function error() {
    echo -e "\n${RED}${BOLD}❌  ${1}${NC}"
}

function warn() {
    echo -e "\n${YELLOW}${BOLD}🤚  ${1}${NC}"
}