-- Create a dedicated user and database for each application
-- This follows the principle of least privilege for better security.
-- On re-runs, "ERROR: role 'X' already exists" and "ERROR: database 'Y' already exists"
-- messages will appear, but are harmless and do not prevent successful completion.

CREATE USER convex_user WITH PASSWORD '${CONVEX_PASSWORD}';
CREATE USER vaultwarden_user WITH PASSWORD '${VW_PASSWORD}';
CREATE USER actualbudget_user WITH PASSWORD '${AB_PASSWORD}';
CREATE USER immich_user WITH PASSWORD '${IMMICH_PASSWORD}';
CREATE USER n8n_user WITH PASSWORD '${N8N_PASSWORD}';
CREATE USER firefly_user WITH PASSWORD '${FIREFLY_PASSWORD}';
CREATE USER forgejo_user WITH PASSWORD '${FORGEJO_PASSWORD}';
CREATE USER teleport_user WITH PASSWORD '${TELEPORT_DB_PASSWORD}';
CREATE USER cognee_user;
CREATE USER infisical_user;

ALTER USER convex_user WITH PASSWORD '${CONVEX_PASSWORD}';
ALTER USER vaultwarden_user WITH PASSWORD '${VW_PASSWORD}';
ALTER USER actualbudget_user WITH PASSWORD '${AB_PASSWORD}';
ALTER USER immich_user WITH PASSWORD '${IMMICH_PASSWORD}';
ALTER USER n8n_user WITH PASSWORD '${N8N_PASSWORD}';
ALTER USER firefly_user WITH PASSWORD '${FIREFLY_PASSWORD}';
ALTER USER forgejo_user WITH PASSWORD '${FORGEJO_PASSWORD}';
ALTER USER cognee_user WITH PASSWORD '${COGNEE_DB_PASSWORD}';
ALTER USER infisical_user WITH PASSWORD '${INFISICAL_PASSWORD}';


CREATE DATABASE convex_self_hosted OWNER convex_user;
CREATE DATABASE vaultwarden OWNER vaultwarden_user;
CREATE DATABASE actualbudget OWNER actualbudget_user;
CREATE DATABASE immich OWNER immich_user;
CREATE DATABASE n8n OWNER n8n_user;
CREATE DATABASE firefly OWNER firefly_user;
CREATE DATABASE forgejo OWNER forgejo_user;
CREATE DATABASE cognee OWNER cognee_user;
CREATE DATABASE infisical OWNER infisical_user;
CREATE DATABASE teleport OWNER teleport_user;
