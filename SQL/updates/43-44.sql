# Updates DB from 43 to 44
# Stores TG-style preferences that have no dedicated column, widens real_name and tts_seed

ALTER TABLE `player` ADD COLUMN `preferences` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL;
ALTER TABLE `characters` ADD COLUMN `preferences` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL;
ALTER TABLE `characters` MODIFY `real_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `characters` MODIFY `tts_seed` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL;
