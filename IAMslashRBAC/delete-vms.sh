#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 --pattern <server-name-pattern>"
  exit 1
}

pattern=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --pattern)
      pattern="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

[[ -z "$pattern" ]] && usage

echo "Searching for servers matching pattern: $pattern"

openstack server list \
  | grep "$pattern" \
  | awk -F'|' '{gsub(/ /,"",$3); print $3}' \
  | while read -r server_name; do
      echo "Deleting server: $server_name"
    #   openstack server delete "$server_name"
    done