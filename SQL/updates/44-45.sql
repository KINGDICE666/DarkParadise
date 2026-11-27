# Updates DB from 44 to 45
# Widens IP columns to 45 characters: IPv6 addresses (web client players) did not fit and their logins failed to save

ALTER TABLE `player` MODIFY `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `admin_log` MODIFY `adminip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `ip2group` MODIFY `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `referral` MODIFY `referred_ip` varchar(45) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL;
ALTER TABLE `connection_log` MODIFY `ip` varchar(45) COLLATE utf8mb4_general_ci NOT NULL;
ALTER TABLE `ban` MODIFY `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL, MODIFY `a_ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL, MODIFY `serverip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL, MODIFY `unbanned_ip` varchar(45) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL;
