#!/usr/bin/env fish
# ~/workspace/homelab/init-dbs.fish
# Idempotent DB initializer with retries

switch "$argv[1]"
    case "postgres"
        echo "Initializing PostgreSQL database..."
        envsubst '${CONVEX_PASSWORD} ${VW_PASSWORD} ${AB_PASSWORD} ${IMMICH_PASSWORD} ${N8N_PASSWORD} ${FIREFLY_PASSWORD}' \
          < postgres-init/init-databases.sql \
          | docker exec -i postgres-main psql -U admin

    case "mariadb"
        echo "Waiting for MariaDB to be ready..."
        for i in (seq 1 30)
            if docker exec mariadb-main mariadb -uroot -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1
                echo "MariaDB is ready!"
                break
            else
                echo "MariaDB not ready yet... retrying ($i/30)"
                sleep 2
            end
        end

        echo "Initializing MariaDB database..."
        set sqlfile (mktemp)
        envsubst '${MYSQL_PASSWORD} ${KIMAI_PASSWORD}' < mariadb-init/kimai.sql > $sqlfile

        docker exec -i mariadb-main mariadb -uroot -p"$MYSQL_PASSWORD" < $sqlfile
        rm $sqlfile

    case "*"
        echo "Error: You must specify a database (postgres or mariadb)."
        exit 1
end

echo "Database initialization complete."
