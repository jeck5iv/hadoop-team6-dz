#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./00_vars.sh

ssh "${SSH_USER}@${HN_DN01}" bash -lc "'
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y postgresql-${PG_VERSION}

sudo -i -u postgres psql <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = \'${PG_DB}\') THEN
    CREATE DATABASE ${PG_DB};
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = \'${PG_USER}\') THEN
    CREATE USER ${PG_USER} WITH PASSWORD \'${PG_PASSWORD}\';
  ELSE
    ALTER USER ${PG_USER} WITH PASSWORD \'${PG_PASSWORD}\';
  END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE \"${PG_DB}\" TO ${PG_USER};
ALTER DATABASE ${PG_DB} OWNER TO ${PG_USER};
SQL

CONF=/etc/postgresql/${PG_VERSION}/main/postgresql.conf
HBA=/etc/postgresql/${PG_VERSION}/main/pg_hba.conf

sudo sed -i "s/^#\?listen_addresses\s*=.*/listen_addresses = '\*'/" \"\${CONF}\"

LINE="host    ${PG_DB}       ${PG_USER}      192.168.1.27/32         password"
sudo grep -Fqx "\${LINE}" "\${HBA}" || echo "\${LINE}" | sudo tee -a "\${HBA}" >/dev/null

sudo systemctl restart postgresql
'"
