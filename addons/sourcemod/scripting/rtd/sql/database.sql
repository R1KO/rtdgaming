-- phpMyAdmin SQL Dump
-- version 3.2.0.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 20, 2010 at 11:07 PM
-- Server version: 5.1.36
-- PHP Version: 5.3.0

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `rtdbank`
--

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
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

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
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `data`
--

CREATE TABLE IF NOT EXISTS `data` (
  `name` text,
  `datatxt` text,
  `dataint` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
  PRIMARY KEY (`STEAMID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
