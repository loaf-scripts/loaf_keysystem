CREATE TABLE IF NOT EXISTS `loaf_keys` (
   `unique_id` VARCHAR(15) NOT NULL,
   `key_id` VARCHAR(255) NOT NULL,
   `identifier` VARCHAR(255) NOT NULL,
   `key_data` LONGTEXT,
   PRIMARY KEY (`unique_id`)
);
