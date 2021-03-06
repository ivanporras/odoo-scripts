#!/bin/bash

# Exit script if command fails
set -e

# Display Help
Help() {
  echo
  echo "odoo-restore"
  echo "############"
  echo
  echo "Description: Restore odoo database."
  echo "Syntax: odoo-restore [-p|-n|-f|-h|-d|help]"
  echo "Example: odoo-restore -p secret -n odoo -f /tmp/odoo.zip -h https://odoo.example.org"
  echo "options:"
  echo "  -p    Odoo master password. Defaults to \$ODOO_MASTER_PASSWORD env var."
  echo "  -n    Database name."
  echo "  -f    Odoo database backup file. Defaults to '/var/tmp/odoo.zip'"
  echo "  -h    Odoo host. Defaults to 'http://localhost:8069'"
  echo "  -d    Delete existing database."  
  echo "  help  Show odoo-restore manual."
  echo
}

# Show help and exit
if [[ $1 == 'help' ]]; then
    Help
    exit
fi

# Initialise option flag with a false value
DELETE='false'

# Process params
while getopts ":d :p: :n: :f: :h:" opt; do
  case $opt in
    d) DELETE='true'
    ;;
    h) HOST="$OPTARG"
    ;;
    p) PASSWORD="$OPTARG"
    ;;
    n) DATABASE="$OPTARG"
    ;;
    f) FILE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    Help
    ;;
  esac
done

# Fallback to environment vars and default values
: ${PASSWORD:=${ODOO_MASTER_PASSWORD:='admin'}}
: ${FILE:='/var/tmp/odoo.zip'}
: ${HOST:='http://localhost:8069'}

# Verify variables
[[ -z "$DATABASE" ]] && { echo "Parameter -n|database is empty" ; exit 1; }
[[ -z "$FILE" ]] && { echo "Parameter -f|file is empty" ; exit 1; }
[[ -z "$HOST" ]] && { echo "Parameter -h|host is empty" ; exit 1; }

# Validate zip file
unzip -q -t $FILE

if $DELETE ; then
  echo "Deleting Odoo database $DATABASE ..."

  curl \
    --silent \
    -F "master_pwd=${PASSWORD}" \
    -F "name=${DATABASE}" \
    ${HOST}/web/database/drop | grep -q 'Internal Server Error'
fi

# Start restore
echo "Requesting restore for Odoo database $DATABASE ..."

# Request restore with curl
curl \
  --silent \
  -F "master_pwd=${PASSWORD}" \
  -F "name=${DATABASE}" \
  -F backup_file=@$FILE \
  -F 'copy=true' \
  ${HOST}/web/database/restore | grep -q 'Redirecting...'

# Notify if restore has finished
echo "The restore for Odoo database $DATABASE has finished."