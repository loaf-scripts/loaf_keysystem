CREATE TABLE IF NOT EXISTS `loaf_keys` ( -- incase of a table already called keys 
    `identifier` varchar(255) NOT NULL,
    `keys` LONGTEXT,
    PRIMARY KEY (`identifier`)
);

CREATE TABLE IF NOT EXISTS `unique_keys` (
    `unique_id` varchar(15) NOT NULL,
    PRIMARY KEY (`unique_id`)
);