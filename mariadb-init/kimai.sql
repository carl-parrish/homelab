-- Create admin user
DROP USER IF EXISTS 'admin'@'%';
CREATE USER 'admin'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;

-- Create Kimai database & user
CREATE DATABASE IF NOT EXISTS kimai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS 'kimai'@'%';
CREATE USER 'kimai'@'%' IDENTIFIED BY '${KIMAI_PASSWORD}';
GRANT ALL PRIVILEGES ON kimai.* TO 'kimai'@'%';

FLUSH PRIVILEGES;
