CREATE TABLE `pan_containers` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`label` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`coords` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`heading` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`target` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`lastupdated` TIMESTAMP NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
	`isdeleted` TINYTEXT NOT NULL DEFAULT 'false' COLLATE 'utf8mb3_general_ci',
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb3_general_ci'
ENGINE=InnoDB
;