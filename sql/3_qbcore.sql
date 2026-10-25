-- Pure Inventory - ONLY for QBCore / Qbox.
-- The default QBCore tables already have these columns; the resource adds them by itself if they are missing.
-- Run this file only if your server refuses ALTER TABLE at runtime.
-- `ADD COLUMN IF NOT EXISTS` works on MariaDB; on MySQL 8 remove `IF NOT EXISTS` (and skip a column that already exists).

-- Inventory of each character (already in the default `players` table of QBCore).
ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `inventory` longtext DEFAULT NULL;

-- Trunks and gloveboxes of owned vehicles.
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `trunk` longtext DEFAULT NULL;
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `glovebox` longtext DEFAULT NULL;
