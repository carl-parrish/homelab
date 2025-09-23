-- Raspberry Pi local Postgres init script
-- Creates isolated DBs for Plane, NocoDB, and Docmost
-- On re-runs, "ERROR: role 'X' already exists" and "ERROR: database 'Y' already exists"
-- messages will appear, but are harmless and do not prevent successful completion.

CREATE USER plane_user WITH PASSWORD '${PLANE_PASSWORD}';
CREATE USER nocodb_user WITH PASSWORD '${NOCODB_PASSWORD}';
CREATE USER docmost_user WITH PASSWORD '${DOCMOST_PASSWORD}';

CREATE DATABASE plane OWNER plane_user;
CREATE DATABASE nocodb OWNER nocodb_user;
CREATE DATABASE docmost OWNER docmost_user;
