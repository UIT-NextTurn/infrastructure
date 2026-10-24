-- ==============================================================================
-- NextTurn Relational Database Initialization Script
-- Initialize schemas and grant permissions for Backend and Keycloak IAM
-- Target Engine: MySQL 8.4 LTS
-- ==============================================================================

-- 1. Create Central Master Schema for NextTurn Core Platform Management
CREATE DATABASE IF NOT EXISTS `nextturn_master`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

-- 2. Create IAM Schema for Keycloak Authentication Server
CREATE DATABASE IF NOT EXISTS `keycloak_iam`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

-- 3. Dedicated User for Keycloak IAM
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY 'keycloak_dev_secret';
GRANT ALL PRIVILEGES ON `keycloak_iam`.* TO 'keycloak'@'%';

-- 4. Dedicated User for NextTurn Application Backend
CREATE USER IF NOT EXISTS 'nextturn'@'%' IDENTIFIED BY 'nextturn_dev_secret';

-- 4.1. Grant permission to create new schemas dynamically upon tenant onboarding
GRANT CREATE ON *.* TO 'nextturn'@'%';

-- 4.2. Grant all privileges on the Central Master Schema
GRANT ALL PRIVILEGES ON `nextturn_master`.* TO 'nextturn'@'%';

-- 4.3. Grant all privileges on all current and future tenant schemas
GRANT ALL PRIVILEGES ON `tenant\_%`.* TO 'nextturn'@'%';

-- 5. Grant root permissions for internal container health checks and operations
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- 6. Enable MySQL Event Scheduler for automated partition management
SET GLOBAL event_scheduler = ON;