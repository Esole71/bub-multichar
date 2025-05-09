![preview_image](https://i.imgur.com/7OMbq7W.png)

# Edited bub-multichar and converted it to ESX with some UI changes.
NUI  EDIT CREDITS: Thomas - https://discord.gg/NQB95SgJ

# bub-multichar
 
added a UI using Mantine instead of using the [ox_lib](https://github.com/overextended/ox_lib).

# Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

# Feature Request & Issue Reporting
Please open an ticket in my discord to report an issue: https://discord.gg/K4VvR5utUs

# DELETE CURRENT USER SQL AND REPLACE WITH THIS:
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL,
  `dateofbirth` varchar(25) DEFAULT NULL,
  `sex` varchar(10) DEFAULT NULL,
  `height` int(11) DEFAULT 180,
  `job` varchar(50) DEFAULT 'unemployed',
  `job_grade` int(11) DEFAULT 0,
  `group` varchar(50) DEFAULT 'user',
  `nationality` varchar(50) DEFAULT NULL,
  `charinfo` longtext DEFAULT NULL,
  `accounts` longtext DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `is_dead` tinyint(1) DEFAULT 0,
  `status` longtext DEFAULT NULL,
  `skin` longtext DEFAULT NULL,
  `inventory` longtext DEFAULT NULL,
  `loadout` longtext DEFAULT NULL,
  `position` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
