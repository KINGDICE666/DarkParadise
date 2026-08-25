# Updates DB from 41 to 42
# Adds a new table linking Steam accounts from the launcher to BYOND ckeys

DROP TABLE IF EXISTS `launcher_link`;
CREATE TABLE `launcher_link`
(
	`steamid64` BIGINT UNSIGNED NOT NULL,
	`ckey` VARCHAR(32) NOT NULL,
	`nickname` VARCHAR(32) NULL DEFAULT NULL,
	`first_seen` DATETIME DEFAULT now() NOT NULL,
	`last_seen` DATETIME DEFAULT now() NOT NULL,
	PRIMARY KEY (`steamid64`),
	KEY `ckey` (`ckey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
