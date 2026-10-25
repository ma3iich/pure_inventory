-- Pure Inventory - ONLY for the standalone mode (no framework).
-- The resource also creates them by itself at the first start: running this file is optional.

-- Inventory of each player (identifier = license by default, see Config.Standalone.Identifier).
CREATE TABLE IF NOT EXISTS `pure_inventory_players` (
  `identifier` varchar(64) NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`identifier`)
);

-- Trunks and gloveboxes, by plate. Rows not used for Config.Standalone.VehicleStorageDays days are deleted at start.
CREATE TABLE IF NOT EXISTS `pure_inventory_vehicles` (
  `plate` varchar(16) NOT NULL,
  `trunk` longtext DEFAULT NULL,
  `glovebox` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`plate`)
);
