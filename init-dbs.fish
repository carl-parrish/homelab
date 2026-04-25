#!/usr/bin/env fish
# ~/workspace/homelab/init-dbs.fish
# Idempotent DB initializer with retries and clearer logging

switch "$argv[1]"
    case "postgres"
        echo "🔧 Initializing PostgreSQL databases..."

        # Run SQL after envsubst
        set tmpfile (mktemp)
        envsubst '${CONVEX_PASSWORD} ${VW_PASSWORD} ${AB_PASSWORD} ${IMMICH_PASSWORD} ${N8N_PASSWORD} ${FIREFLY_PASSWORD} ${FORGEJO_PASSWORD} ${INFISICAL_PASSWORD} ${COGNEE_DB_PASSWORD} ${TELEPORT_DB_PASSWORD} ${DOCMOST_DB_PASSWORD} ${NOCODB_DB_PASSWORD} ${PLANE_DB_PASSWORD}' \
          < postgres-init/init-databases.sql > $tmpfile

        # Use -f - to ensure psql reads from stdin, allowing for the SQL to be piped
        # This will show "ERROR: role 'X' already exists" and "ERROR: database 'Y' already exists" on re-runs, which is harmless.
        docker exec -i postgres-main psql -U admin -f - < $tmpfile

        echo "✅ PostgreSQL databases initialized (harmless errors for existing roles/databases on re-runs)."
        rm $tmpfile

    case "mariadb"
        echo "⏳ Waiting for MariaDB to be ready..."
        for i in (seq 1 30)
            if docker exec mariadb-main mariadb -uroot -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1
                echo "✅ MariaDB is ready!"
                break
            else
                echo "❌ MariaDB not ready yet... retrying ($i/30)"
                sleep 2
            end
        end

        echo "🔧 Initializing MariaDB databases..."
        set sqlfile (mktemp)
        envsubst '${MYSQL_PASSWORD} ${KIMAI_PASSWORD}' < mariadb-init/kimai.sql > $sqlfile

        docker exec -i mariadb-main mariadb -uroot -p"$MYSQL_PASSWORD" < $sqlfile
        rm $sqlfile
        echo "✅ MariaDB databases initialized (idempotent)."

    case "*"
        echo "Error: You must specify a database (postgres or mariadb)."
        exit 1
end
