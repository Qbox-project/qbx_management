CREATE TABLE IF NOT EXISTS `player_jobs_activity` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) COLLATE utf8mb4_unicode_ci,
  `job` varchar(255) NOT NULL,
  `last_checkin` int NOT NULL,
  `last_checkout` int NULL DEFAULT NULL,
  FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `id` (`id` DESC) USING BTREE,
  INDEX `last_checkout` (`last_checkout` ASC) USING BTREE,
  INDEX `citizenid_job` (`citizenid`, `job`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci;