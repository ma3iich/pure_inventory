-- Pure Inventory - tables used with EVERY framework (standalone, QBCore, Qbox, ESX...).
-- The resource also creates them by itself at the first start: running this file is optional.

-- Stashes, police evidence lockers, dumpsters... (same table as ox_inventory: keep yours if you come from ox_inventory)
CREATE TABLE IF NOT EXISTS `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`, `name`)
);

-- Clothing slots: what each character took off / put on (one small row per character who used them).
CREATE TABLE IF NOT EXISTS `pure_inventory_clothing` (
  `owner` varchar(64) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`owner`)
);
