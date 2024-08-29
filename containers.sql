CREATE TABLE IF NOT EXISTS `pan_containers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uuid` int(11) NOT NULL DEFAULT floor(10000 + rand() * (99999 - 10000 + 1)),
  `label` longtext DEFAULT NULL,
  `coords` longtext DEFAULT NULL,
  `heading` longtext DEFAULT NULL,
  `target` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `uuid` (`uuid`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;