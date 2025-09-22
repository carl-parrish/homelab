-- Create a dedicated user and database for each application
-- This follows the principle of least privilege for better security.

CREATE USER convex_user WITH PASSWORD '${CONVEX_PASSWORD}';
CREATE USER vaultwarden_user WITH PASSWORD '${VW_PASSWORD}';
CREATE USER actualbudget_user WITH PASSWORD '${AB_PASSWORD}';
CREATE USER immich_user WITH PASSWORD '${IMMICH_PASSWORD}'; 
CREATE USER n8n_user WITH PASSWORD '${N8N_PASSWORD}'; 
CREATE USER firefly_user WITH PASSWORD '${FIREFLY_PASSWORD}'; 

CREATE DATABASE convex_self_hosted OWNER convex_user;
CREATE DATABASE vaultwarden OWNER vaultwarden_user;
CREATE DATABASE actualbudget OWNER actualbudget_user;
CREATE DATABASE immich OWNER immich_user;
CREATE DATABASE n8n OWNER n8n_user;
CREATE DATABASE firefly OWNER firefly_user;
