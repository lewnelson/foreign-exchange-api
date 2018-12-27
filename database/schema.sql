-- -----------------------------------------------------
-- Schema foreign_exchange
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `foreign_exchange` DEFAULT CHARACTER SET utf8 ;
USE `foreign_exchange` ;

-- -----------------------------------------------------
-- Table `foreign_exchange`.`currencies`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `foreign_exchange`.`currencies` ;

CREATE TABLE IF NOT EXISTS `foreign_exchange`.`currencies` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `currency_code` CHAR(3) NOT NULL COMMENT 'Currency code in ISO 4217 format',
  PRIMARY KEY (`id`),
  UNIQUE (`currency_code`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `foreign_exchange`.`exchange_rates_against_base_currency`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `foreign_exchange`.`exchange_rates_against_base_currency` ;

CREATE TABLE IF NOT EXISTS `foreign_exchange`.`exchange_rates_against_base_currency` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `rate` FLOAT NOT NULL,
  `date_recorded` DATE NOT NULL,
  `currency_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `currency_id__currencies_id`
    FOREIGN KEY (`currency_id`)
    REFERENCES `foreign_exchange`.`currencies` (`id`))
ENGINE = InnoDB;

ALTER TABLE `exchange_rates_against_base_currency` ADD UNIQUE `unique_currency_rate`(`rate`, `date_recorded`, `currency_id`);
