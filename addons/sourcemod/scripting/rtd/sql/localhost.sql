-- phpMyAdmin SQL Dump
-- version 3.4.10.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 19, 2012 at 11:07 PM
-- Server version: 5.5.8
-- PHP Version: 5.3.5

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `rtd_gamedb`
--
CREATE DATABASE `rtd_gamedb` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `rtd_gamedb`;

-- --------------------------------------------------------

--
-- Table structure for table `awards`
--

CREATE TABLE IF NOT EXISTS `awards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `begin_date` int(11) NOT NULL DEFAULT '0',
  `end_date` int(11) NOT NULL DEFAULT '0',
  `static_code` tinyint(1) NOT NULL DEFAULT '0',
  `code` varchar(255) NOT NULL,
  `times_awarded` int(2) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=19 ;

--
-- Dumping data for table `awards`
--

INSERT INTO `awards` (`id`, `name`, `begin_date`, `end_date`, `static_code`, `code`, `times_awarded`) VALUES
(1, 'BearTrap', 0, 0, 1, 'rtd-0-grrrrbeartrappin', 1),
(2, 'Backpack', 0, 0, 1, 'rtd-0-iunderstandhowthebackpackworks', 1),
(3, 'Amplifier', 0, 0, 1, 'rtd-0-ampmeup', 1),
(4, 'HumanDispenser', 0, 0, 1, 'rtd-0-heyheyputadispenserhere', 1),
(5, 'TestDynamic', 1277967600, 1278140400, 0, 'TestDynamic', 1),
(6, 'Anniversary-01', 1278226800, 1278313200, 0, 'kicasso', 1),
(7, 'Anniversary-02', 1278313200, 1278399600, 0, 'yatzeeeeee', 1),
(8, 'Anniversary-03', 1278399600, 1278486000, 0, 'itstimetorollthedice', 1),
(9, 'Anniversary-04', 1278486000, 1278572400, 0, 'bigmoney', 1),
(10, 'Anniversary-05', 1278572400, 1278658800, 0, 'goingtheduration', 1),
(11, 'Anniversary-06', 1279350000, 1279522800, 0, 'discountonislecredits', 1),
(12, 'Anniversary-07', 1279350000, 1279522800, 0, 'bagfullofcookies', 1),
(13, 'starterpack', 1285916400, 1599548400, 1, 'rtd-0-imanoob', 1),
(14, 'Camouflage', 0, 0, 1, 'rtd-0-camo', 1),
(15, 'Blizzard', 0, 0, 1, 'rtd-0-blizzard', 1),
(16, 'Christmas2010_01', 1293091200, 1293264000, 1, 'rtd-0-xmas1', 1),
(17, 'Christmas2010_02', 1293177600, 1293350400, 1, 'rtd-0-xmas2', 1),
(18, 'Christmas2010_03', 1293350400, 1293436800, 1, 'rtd-0-mas3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `awards_received`
--

CREATE TABLE IF NOT EXISTS `awards_received` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(128) NOT NULL,
  `code` varchar(255) NOT NULL,
  `award` int(11) NOT NULL,
  `awarded` int(2) NOT NULL DEFAULT '0',
  `date` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `steamid` (`steamid`),
  KEY `code` (`code`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1195 ;

-- --------------------------------------------------------

--
-- Table structure for table `data`
--

CREATE TABLE IF NOT EXISTS `data` (
  `name` text,
  `datatxt` text,
  `dataint` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `data`
--

INSERT INTO `data` (`name`, `datatxt`, `dataint`) VALUES
('dbversion', NULL, 7);

-- --------------------------------------------------------

--
-- Table structure for table `player`
--

CREATE TABLE IF NOT EXISTS `player` (
  `STEAMID` varchar(25) NOT NULL,
  `NAME` varchar(30) NOT NULL,
  `CREDITS` int(25) NOT NULL DEFAULT '0',
  `DICE` int(25) NOT NULL DEFAULT '0',
  `OPTION1` tinyint(1) NOT NULL DEFAULT '0',
  `OPTION2` tinyint(1) NOT NULL DEFAULT '0',
  `OPTION3` tinyint(1) NOT NULL DEFAULT '0',
  `OPTION4` tinyint(1) NOT NULL DEFAULT '0',
  `HUDXPOS` int(11) NOT NULL DEFAULT '0',
  `HUDYPOS` int(11) NOT NULL DEFAULT '0',
  `LASTONTIME` int(11) NOT NULL DEFAULT '0',
  `HUDXPOS2` int(11) NOT NULL DEFAULT '0',
  `HUDYPOS2` int(11) NOT NULL DEFAULT '0',
  `OPTION5` tinyint(1) NOT NULL DEFAULT '0',
  `SCOREENABLED` tinyint(1) NOT NULL DEFAULT '0',
  `VOICEOPTIONS` tinyint(1) NOT NULL DEFAULT '0',
  `BETATESTING` tinyint(1) NOT NULL DEFAULT '0',
  `TALENTPOINTS` int(25) NOT NULL DEFAULT '-1',
  `DICEPERKS` text NOT NULL,
  `TRINKETS` text NOT NULL,
  PRIMARY KEY (`STEAMID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `player`
--

INSERT INTO `player` (`STEAMID`, `NAME`, `CREDITS`, `DICE`, `OPTION1`, `OPTION2`, `OPTION3`, `OPTION4`, `HUDXPOS`, `HUDYPOS`, `LASTONTIME`, `HUDXPOS2`, `HUDYPOS2`, `OPTION5`, `SCOREENABLED`, `VOICEOPTIONS`, `BETATESTING`, `TALENTPOINTS`, `DICEPERKS`, `TRINKETS`) VALUES
('STEAM_0:0:15175229', 'RTD{A} Fox', 3539, 4827, 1, 0, 0, 0, 64, 94, 1334851837, 64, 97, 0, 1, 2, 1, 34, 'a16:0,a00:0,a01:0,a50:0,a03:0,a06:0,a07:0,a08:0,a09:0,a10:0,a11:0,a12:0,a13:0,a14:0,a15:0,a17:0,a18:0,a19:1,z01:0,z02:0,z03:0,a21:2,a22:0,a24:0,a25:0,a26:0,a27:0,a28:0,a29:0,a30:0,a31:0,a32:1,a33:1,a34:0,a35:0,a38:0,a41:0,a42:0,a43:0,a44:0,a46:1,a47:0,a48:0,a49:0,a52:0,a53:0,a51:0,a54:1,a55:1,a56:0', 't02:3:0,t05:2:0,t04:2:0,t09:2:0,t01:2:1,t08:2:0,t05:1:0,t05:1:0,t02:1:0,t05:1:0,t01:1:0,t09:1:0,t09:1:0,t12:0:0,t01:0:0,t08:0:0,t08:0:0,t09:0:0,t07:0:0,t05:0:0,t05:0:0,t02:0:0,t06:0:0,t05:0:0,t01:0:0,t12:0:0,t05:0:0,t05:0:0,t05:0:0,t01:0:0'),
('STEAM_0:0:36152250', '-RTD- Toaster', 56, 0, 0, 0, 0, 0, 70, 94, 1318297805, 70, 97, 0, 0, 0, 1, 0, 'a16:0,a00:0,a01:0,a50:0,a03:0,a06:0,a07:0,a08:0,a09:0,a10:0,a11:0,a12:0,a13:0,a14:0,a15:0,a17:0,a18:0,a19:0,a20:0,z01:0,z02:0,z03:0,a21:0,a22:0,a24:0,a25:0,a26:0,a27:0,a28:0,a29:0,a30:0,a31:0,a32:0,a33:0,a34:0,a35:0,a38:0,a41:0,a42:0,a43:0,a44:0,a45:0,a46:0,a47:0,a48:0,a49:0,a52:0,a53:0,a51:0,a54:0', '-1');

-- --------------------------------------------------------

--
-- Table structure for table `player_perks`
--

CREATE TABLE IF NOT EXISTS `player_perks` (
  `STEAMID` varchar(25) NOT NULL,
  `DICEPERKS` text NOT NULL,
  PRIMARY KEY (`STEAMID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `player_perks`
--

INSERT INTO `player_perks` (`STEAMID`, `DICEPERKS`) VALUES
('STEAM_0:0:15175229', 'a00:0,a01:1,a02:3,a03:3,a05:0,a06:0,a07:0,a08:3,a09:0,a10:0,a11:2');

-- --------------------------------------------------------

--
-- Table structure for table `trinkets`
--

CREATE TABLE IF NOT EXISTS `trinkets` (
  `STEAMID` varchar(25) NOT NULL,
  `TRINKETRAW` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `trinkets`
--

INSERT INTO `trinkets` (`STEAMID`, `TRINKETRAW`) VALUES
('STEAM_0:0:15175229', 't04:1:1316999599:1,t03:3:1317445815:0,t05:3:1318097165:0,t06:3:1317497398:0,t07:2:1318054397:0,t02:1:1317489460:0,t04:0:1318814035:0,t04:2:-1:0,t03:2:-1:0,t03:2:-1:0,t03:2:-1:0,t03:2:-1:0,t06:0:-1:0,t05:0:-1:0');

-- --------------------------------------------------------

--
-- Table structure for table `trinkets_v2`
--

CREATE TABLE IF NOT EXISTS `trinkets_v2` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `STEAMID` varchar(25) NOT NULL,
  `TRINKET` varchar(5) NOT NULL,
  `TIER` tinyint(4) NOT NULL,
  `EXPIRE` bigint(20) NOT NULL,
  `EQUIPPED` tinyint(4) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `trinkets_v2`
--

INSERT INTO `trinkets_v2` (`ID`, `STEAMID`, `TRINKET`, `TIER`, `EXPIRE`, `EQUIPPED`) VALUES
(1, 'STEAM_0:0:15175229', 't10', 0, 1334108239, 0),
(2, 'STEAM_0:0:15175229', 't10', 0, 1334108239, 0),
(3, 'STEAM_0:0:15175229', 't02', 1, 1334108307, 0);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
