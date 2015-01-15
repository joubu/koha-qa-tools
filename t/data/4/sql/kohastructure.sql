-- MySQL dump 10.9
--
-- Host: localhost    Database: koha30test
-- ------------------------------------------------------
-- Server version    4.1.22

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auth_header`
--

DROP TABLE IF EXISTS `auth_header`;
CREATE TABLE `auth_header` (
  `authid` bigint(20) unsigned NOT NULL auto_increment,
  `authtypecode` varchar(10) NOT NULL default '',
  `datecreated` date default NULL,
  `datemodified` date default NULL,
  `origincode` varchar(20) default NULL,
  `authtrees` mediumtext,
  `marc` blob,
  `linkid` bigint(20) default NULL,
  `marcxml` longtext NOT NULL,
  PRIMARY KEY  (`authid`),
  KEY `origincode` (`origincode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `auth_subfield_structure`
--

DROP TABLE IF EXISTS `auth_subfield_structure`;
CREATE TABLE `auth_subfield_structure` (
  `authtypecode` varchar(10) NOT NULL default '',
  `tagfield` varchar(3) NOT NULL default '',
  `tagsubfield` varchar(1) NOT NULL default '',
  `liblibrarian` varchar(255) NOT NULL default '',
  `libopac` varchar(255) NOT NULL default '',
  `repeatable` tinyint(4) NOT NULL default 0,
  `mandatory` tinyint(4) NOT NULL default 0,
  `tab` tinyint(1) default NULL,
  `authorised_value` varchar(10) default NULL,
  `value_builder` varchar(80) default NULL,
  `seealso` varchar(255) default NULL,
  `isurl` tinyint(1) default NULL,
  `hidden` tinyint(3) NOT NULL default 0,
  `linkid` tinyint(1) NOT NULL default 0,
  `kohafield` varchar(45) NULL default '',
  `frameworkcode` varchar(10) NOT NULL default '',
  `defaultvalue` TEXT DEFAULT '',
  PRIMARY KEY  (`authtypecode`,`tagfield`,`tagsubfield`),
  KEY `tab` (`authtypecode`,`tab`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
