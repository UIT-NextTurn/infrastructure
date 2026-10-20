-- ==============================================================================
-- NextTurn Relational Database Initialization Script
-- Khởi tạo các lược đồ (schemas) và cấp quyền cho Backend & Keycloak IAM
-- ==============================================================================

-- 1. Create Central Master Schema (NextTurn Core Management)
CREATE DATABASE IF NOT EXISTS `nextturn_master`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 2. Create IAM Schema (Keycloak Authentication Server)
CREATE DATABASE IF NOT EXISTS `keycloak_iam`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 3. Dedicated User for Keycloak IAM
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY 'keycloak_dev_secret';
GRANT ALL PRIVILEGES ON `keycloak_iam`.* TO 'keycloak'@'%';

-- 4. Dedicated User for NextTurn Application Backend (Multi-tenant Enabled)
CREATE USER IF NOT EXISTS 'nextturn'@'%' IDENTIFIED BY 'nextturn_dev_secret';

-- 4.1. Cấp quyền tạo Schema mới khi kích hoạt Tenant
GRANT CREATE ON *.* TO 'nextturn'@'%';

-- 4.2. Cấp toàn quyền trên Master Schema
GRANT ALL PRIVILEGES ON `nextturn_master`.* TO 'nextturn'@'%';

-- 4.3. Cấp toàn quyền trên toàn bộ các Schema Tenant hiện tại và sinh ra sau này
GRANT ALL PRIVILEGES ON `tenant\_%`.* TO 'nextturn'@'%';

-- 5. Cho phép root kết nối từ các container nội bộ (Dùng cho migration / debug tool)
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;