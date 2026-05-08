-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 08, 2026 at 03:28 PM
-- Server version: 8.0.44
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `liftright_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `recompute_trainer_summary` (IN `p_trainer_id` INT)   BEGIN
  INSERT INTO trainer_rating_summary (trainer_id, avg_rating, review_count)
  SELECT
    p_trainer_id,
    COALESCE(ROUND(AVG(r.rating), 2), 0),
    COUNT(*)
  FROM trainer_reviews r
  WHERE r.trainer_id = p_trainer_id
    AND r.status = 'approved'
  ON DUPLICATE KEY UPDATE
    avg_rating   = VALUES(avg_rating),
    review_count = VALUES(review_count);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `auth_audit_logs`
--

CREATE TABLE `auth_audit_logs` (
  `event_id` bigint NOT NULL,
  `user_id` int DEFAULT NULL,
  `event_type` enum('login_success','login_fail','login_blocked','otp_sent','otp_verify_success','otp_verify_fail','email_verify_sent','email_verify_success','email_verify_fail','register_pending','trainer_application_approved','trainer_application_rejected','profile_change_approved','profile_change_rejected','admin_set_role','admin_set_status','admin_unlink_trainer','admin_delete_user','password_reset_requested','password_reset_success','password_reset_failed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_audit_logs`
--

INSERT INTO `auth_audit_logs` (`event_id`, `user_id`, `event_type`, `ip_address`, `user_agent`, `meta`, `created_at`) VALUES
(1, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-03-31 09:05:44'),
(2, 1, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"admin\"}', '2026-03-31 09:05:54'),
(3, NULL, 'email_verify_sent', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"mode\": \"pending_registration\", \"email\": \"zacgames.tv@gmail.com\", \"pending_id\": 4}', '2026-03-31 09:27:08'),
(4, 10, 'email_verify_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"mode\": \"pending_registration\", \"pending_id\": 4}', '2026-03-31 09:27:19'),
(5, 2, 'login_blocked', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"reason\": \"email_not_verified\"}', '2026-03-31 09:34:54'),
(6, 2, 'email_verify_sent', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"mode\": \"existing_user\", \"email\": \"trainer@liftright.local\"}', '2026-03-31 09:34:55'),
(7, 2, 'login_blocked', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"reason\": \"email_not_verified\"}', '2026-03-31 09:34:59'),
(8, 2, 'login_blocked', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"reason\": \"email_not_verified\"}', '2026-03-31 09:36:01'),
(9, 1, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"admin\"}', '2026-03-31 09:36:05'),
(10, 1, 'admin_set_role', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"before\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_role\": \"user\", \"target_user_id\": 10}', '2026-03-31 09:36:09'),
(11, 1, 'admin_set_role', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"before\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_role\": \"user\", \"target_user_id\": 10}', '2026-03-31 09:36:13'),
(12, 1, 'admin_set_role', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"before\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_role\": \"user\", \"target_user_id\": 10}', '2026-03-31 09:36:22'),
(13, 1, 'admin_set_status', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"approved\"}, \"before\": {\"role\": \"user\", \"email\": \"zacgames.tv@gmail.com\", \"user_id\": 10, \"full_name\": \"Test\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_status\": \"approved\", \"target_user_id\": 10}', '2026-03-31 09:36:27'),
(14, 3, 'login_blocked', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"reason\": \"email_not_verified\"}', '2026-03-31 09:54:02'),
(15, 3, 'email_verify_sent', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"mode\": \"existing_user\", \"email\": \"user@liftright.local\"}', '2026-03-31 09:54:03'),
(16, 3, 'login_blocked', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"reason\": \"email_not_verified\"}', '2026-03-31 09:54:27'),
(17, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-03-31 09:59:01'),
(18, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-01 05:31:43'),
(19, 2, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"trainer\"}', '2026-04-01 06:29:25'),
(20, NULL, 'login_fail', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"email\": \"crispino.zyrus@gmail.com\", \"reason\": \"user_not_found\"}', '2026-04-01 06:29:32'),
(21, NULL, 'login_fail', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"email\": \"crispino.zyrus@gmail.com\", \"reason\": \"user_not_found\"}', '2026-04-01 06:29:46'),
(22, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-01 06:30:08'),
(23, 2, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"trainer\"}', '2026-04-01 06:30:17'),
(24, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-01 06:54:21'),
(25, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-04 03:44:23'),
(26, 1, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"admin\"}', '2026-04-06 06:24:43'),
(27, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-06 06:42:40'),
(28, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-06 07:58:42'),
(29, 3, 'login_success', '129.227.97.105', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-06 08:16:16'),
(30, 2, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"trainer\"}', '2026-04-06 08:18:31'),
(31, 10, 'login_fail', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"email\": \"zacgames.tv@gmail.com\", \"reason\": \"bad_password\"}', '2026-04-06 08:19:21'),
(32, 10, 'login_fail', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"email\": \"zacgames.tv@gmail.com\", \"reason\": \"bad_password\"}', '2026-04-06 08:19:32'),
(33, 10, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-06 08:19:37'),
(34, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-06 08:19:54'),
(35, 1, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"admin\"}', '2026-04-06 08:20:03'),
(36, 1, 'profile_change_approved', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"request_id\": 7, \"admin_notes\": \"\", \"target_user_id\": 2}', '2026-04-06 08:20:09'),
(37, 2, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"trainer\"}', '2026-04-06 08:20:14'),
(38, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-06 08:25:56'),
(39, NULL, 'email_verify_sent', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"mode\": \"pending_registration\", \"email\": \"crispino.zyrus@gmail.com\", \"pending_id\": 2}', '2026-04-06 08:29:35'),
(40, NULL, 'register_pending', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\", \"email\": \"crispino.zyrus@gmail.com\", \"pending_id\": 5}', '2026-04-06 08:31:14'),
(41, NULL, 'email_verify_sent', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"mode\": \"pending_registration\", \"email\": \"crispino.zyrus@gmail.com\", \"pending_id\": 5}', '2026-04-06 08:31:15'),
(42, 11, 'email_verify_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"mode\": \"pending_registration\", \"pending_id\": 5}', '2026-04-06 08:31:27'),
(43, 1, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"admin\"}', '2026-04-06 08:31:34'),
(44, 1, 'admin_set_status', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"crispino.zyrus@gmail.com\", \"user_id\": 11, \"full_name\": \"Zyrus Crispino\", \"trainer_id\": null, \"account_status\": \"approved\"}, \"before\": {\"role\": \"user\", \"email\": \"crispino.zyrus@gmail.com\", \"user_id\": 11, \"full_name\": \"Zyrus Crispino\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_status\": \"approved\", \"target_user_id\": 11}', '2026-04-06 08:31:40'),
(45, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-07 05:58:04'),
(46, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-07 06:04:03'),
(47, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-07 07:38:20'),
(48, 1, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"admin\"}', '2026-04-07 09:02:02'),
(49, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-07 09:02:05'),
(50, 3, 'login_success', '103.16.168.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-08 00:03:05'),
(51, 3, 'login_fail', '103.16.168.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"email\": \"user@liftright.local\", \"reason\": \"bad_password\"}', '2026-04-08 01:13:49'),
(52, 3, 'login_success', '103.16.168.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-08 01:14:00'),
(53, 3, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-08 03:30:27'),
(54, 3, 'login_success', '111.125.92.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-08 04:56:50'),
(55, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-08 09:17:40'),
(56, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 05:34:46'),
(57, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 06:24:24'),
(58, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 11:49:14'),
(59, 3, 'login_fail', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"email\": \"user@liftright.local\", \"reason\": \"bad_password\"}', '2026-04-09 12:34:43'),
(60, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 12:34:51'),
(61, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 12:51:54'),
(62, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 12:56:59'),
(63, 3, 'login_success', '123.253.51.42', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-09 14:10:15'),
(64, NULL, 'register_pending', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\", \"email\": \"diamondthekidrs44@gmail.com\", \"pending_id\": 6}', '2026-04-09 16:18:14'),
(65, NULL, 'email_verify_sent', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"mode\": \"pending_registration\", \"email\": \"diamondthekidrs44@gmail.com\", \"pending_id\": 6}', '2026-04-09 16:18:15'),
(66, 12, 'email_verify_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"mode\": \"pending_registration\", \"pending_id\": 6}', '2026-04-09 16:18:31'),
(67, 1, 'login_fail', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"email\": \"admin@liftright.local\", \"reason\": \"bad_password\"}', '2026-04-09 16:19:23'),
(68, 1, 'login_fail', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"email\": \"admin@liftright.local\", \"reason\": \"bad_password\"}', '2026-04-09 16:20:01'),
(69, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-09 16:21:02'),
(70, 1, 'admin_set_status', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"after\": {\"role\": \"user\", \"email\": \"diamondthekidrs44@gmail.com\", \"user_id\": 12, \"full_name\": \"Febrilo par\", \"trainer_id\": null, \"account_status\": \"approved\"}, \"before\": {\"role\": \"user\", \"email\": \"diamondthekidrs44@gmail.com\", \"user_id\": 12, \"full_name\": \"Febrilo par\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_status\": \"approved\", \"target_user_id\": 12}', '2026-04-09 16:22:06'),
(71, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-09 16:22:33'),
(72, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-09 16:24:20'),
(73, 1, 'profile_change_approved', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"request_id\": 8, \"admin_notes\": \"yes, sure thing lmao\", \"target_user_id\": 12}', '2026-04-09 16:24:32'),
(74, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-09 16:24:40'),
(75, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-09 16:26:55'),
(76, 2, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"trainer\"}', '2026-04-09 16:36:39'),
(77, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-09 16:39:24'),
(78, 1, 'profile_change_approved', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"request_id\": 9, \"admin_notes\": \"\", \"target_user_id\": 12}', '2026-04-09 16:39:34'),
(79, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-09 16:40:17'),
(80, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-10 00:13:11'),
(81, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-10 00:13:29'),
(82, 1, 'admin_unlink_trainer', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"trainer_id\": 2, \"target_user_id\": 12}', '2026-04-10 00:13:47'),
(83, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-10 00:13:58'),
(84, NULL, 'login_fail', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"email\": \"trainer@liftiright.local\", \"reason\": \"user_not_found\"}', '2026-04-10 00:14:19'),
(85, NULL, 'login_fail', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"email\": \"trainer@liftiright.local\", \"reason\": \"user_not_found\"}', '2026-04-10 00:14:30'),
(86, 2, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"trainer\"}', '2026-04-10 00:14:58'),
(87, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-10 00:15:08'),
(88, 11, 'password_reset_requested', '131.226.107.215', 'Mozilla/5.0 (Android 14; Mobile; rv:149.0) Gecko/149.0 Firefox/149.0', '{\"email\": \"crispino.zyrus@gmail.com\"}', '2026-04-10 07:27:06'),
(89, 3, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-11 01:48:47'),
(90, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-13 02:16:19'),
(91, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-13 03:11:02'),
(92, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-13 11:55:22'),
(93, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-13 11:56:18'),
(94, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-13 11:56:53'),
(95, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.47 Mobile/15E148 Safari/604.1', '{\"role\": \"user\"}', '2026-04-15 13:40:06'),
(96, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-15 14:17:02'),
(97, NULL, 'register_pending', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"pending_id\": 7}', '2026-04-16 08:58:40'),
(98, NULL, 'email_verify_sent', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"mode\": \"pending_registration\", \"email\": \"nicolecfmartin21@gmail.com\", \"pending_id\": 7}', '2026-04-16 08:58:41'),
(99, 13, 'email_verify_success', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"mode\": \"pending_registration\", \"pending_id\": 7}', '2026-04-16 08:59:09'),
(100, 13, 'login_blocked', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"reason\": \"account_not_approved\", \"account_status\": \"pending\"}', '2026-04-16 08:59:24'),
(101, 13, 'login_blocked', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"reason\": \"account_not_approved\", \"account_status\": \"pending\"}', '2026-04-16 08:59:42'),
(102, 1, 'login_success', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"admin\"}', '2026-04-16 09:03:29'),
(103, 1, 'admin_set_role', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"before\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_role\": \"user\", \"target_user_id\": 13}', '2026-04-16 09:03:39'),
(104, 1, 'admin_set_role', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"before\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_role\": \"user\", \"target_user_id\": 13}', '2026-04-16 09:03:54'),
(105, 1, 'admin_set_status', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"after\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"approved\"}, \"before\": {\"role\": \"user\", \"email\": \"nicolecfmartin21@gmail.com\", \"user_id\": 13, \"full_name\": \"nicolecfmartin21@gmail.com\", \"trainer_id\": null, \"account_status\": \"pending\"}, \"new_status\": \"approved\", \"target_user_id\": 13}', '2026-04-16 09:03:59'),
(106, 13, 'login_success', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-16 09:06:03'),
(107, 2, 'login_success', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"trainer\"}', '2026-04-16 09:11:39'),
(108, 13, 'login_success', '103.60.171.154', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-16 13:38:46'),
(109, 2, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"trainer\"}', '2026-04-16 15:54:13'),
(110, 2, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"trainer\"}', '2026-04-17 10:26:59'),
(111, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 10:27:04'),
(112, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 11:00:06'),
(113, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 11:03:18'),
(114, 1, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"admin\"}', '2026-04-17 11:33:43'),
(115, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 11:35:57'),
(116, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 11:52:42'),
(117, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 11:56:58'),
(118, 3, 'login_success', '131.226.104.59', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 12:29:19'),
(119, 3, 'login_success', '131.226.104.59', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 12:47:10'),
(120, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 12:51:20'),
(121, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 12:54:50'),
(122, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 13:18:44'),
(123, 3, 'login_success', '131.226.107.200', 'Mozilla/5.0 (Android 14; Mobile; rv:149.0) Gecko/149.0 Firefox/149.0', '{\"role\": \"user\"}', '2026-04-17 13:34:59'),
(124, 3, 'login_success', '131.226.107.200', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 13:48:36'),
(125, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 13:59:32'),
(126, 12, 'login_success', '149.30.134.67', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 14:01:42'),
(127, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 14:11:12'),
(128, 3, 'login_success', '123.253.51.86', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 OPR/129.0.0.0', '{\"role\": \"user\"}', '2026-04-17 15:16:33'),
(129, 12, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-17 23:57:45'),
(130, 12, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-18 00:50:56'),
(131, 12, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-18 02:01:17'),
(132, 2, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"trainer\"}', '2026-04-18 02:21:04'),
(133, 12, 'login_success', '103.91.142.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-18 02:21:58'),
(134, 3, 'login_success', '103.16.168.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{\"role\": \"user\"}', '2026-04-18 03:43:39'),
(135, 2, 'login_success', '103.16.168.18', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{\"role\": \"trainer\"}', '2026-04-18 03:48:05'),
(136, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36 OPR/130.0.0.0', '{\"role\": \"user\"}', '2026-05-08 03:02:53');

-- --------------------------------------------------------

--
-- Table structure for table `email_verifications`
--

CREATE TABLE `email_verifications` (
  `verif_id` bigint NOT NULL,
  `user_id` int DEFAULT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `consumed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `pending_id` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_verifications`
--

INSERT INTO `email_verifications` (`verif_id`, `user_id`, `token_hash`, `expires_at`, `consumed_at`, `created_at`, `pending_id`) VALUES
(5, NULL, '$2y$10$7D8RlS.l66JGEdTAhCOqQ.N/RtMZSsVOTuvZt5K9EwQhn7zrkyj1G', '2026-02-24 16:42:26', '2026-04-06 08:29:35', '2026-02-24 08:27:26', 2),
(6, NULL, '$2y$10$/K/RBzmCpxFgaIQ3a4lkr.1iqTiexgAGfBGjK.6gp/9ZLcedheiFa', '2026-02-24 16:45:20', '2026-02-24 16:31:13', '2026-02-24 08:30:20', 3),
(7, 1, '$2y$10$a/3D6AMT6GqzWDEYPGpGFu3Wkg3Jm7kN3C5CT6pXHw.iUGgw.laEK', '2026-02-24 16:46:28', '2026-02-24 16:31:32', '2026-02-24 08:31:28', NULL),
(8, 1, '$2y$10$68UyPTekFMgso8oewREF2eSVU4AVqAJPGOFqe01xCFwj6exTGSA.m', '2026-02-24 16:46:32', '2026-02-24 16:33:35', '2026-02-24 08:31:32', NULL),
(9, 1, '$2y$10$5uzTDwJrGysyYBEc3WuWceDghuAoXCl2DJKwCzC.eNsZ6b8ZBtSPq', '2026-02-24 16:48:35', '2026-02-24 16:34:46', '2026-02-24 08:33:35', NULL),
(10, 1, '$2y$10$D7Xn9fFJeXibtvk2TgVtM.Co45VTD0t0/6elj0JAh66pUGUARcH06', '2026-02-24 16:49:46', '2026-02-24 16:34:50', '2026-02-24 08:34:46', NULL),
(11, 1, '$2y$10$t4z7y.Lq2C372JKX0.rfrO4Sc2V4m1C3bs.I3cZe6mqvw2VoJSHuq', '2026-02-24 16:49:50', '2026-02-24 16:37:21', '2026-02-24 08:34:50', NULL),
(12, 1, '$2y$10$GlvjgIkpnioi3S/NFRCAk.Du5LH2NkRQikFfTYf5uWnQ4lnnKTxRq', '2026-02-24 16:52:21', '2026-02-24 16:37:23', '2026-02-24 08:37:21', NULL),
(13, 1, '$2y$10$4F24yGnzJukej1z21OCReuLT01SZyJH6PIz1J0u3eoqfvOIJj94GG', '2026-02-24 16:52:23', '2026-02-24 16:37:41', '2026-02-24 08:37:23', NULL),
(14, 1, '$2y$10$xva3SCtDuIGXJztiVYVM7.Rzf61LDOSIGW4CdK6SjQvyo4GH8B9Hm', '2026-02-24 16:52:41', '2026-02-24 16:37:43', '2026-02-24 08:37:41', NULL),
(15, 1, '$2y$10$84qFUPpwOWPkgeqDNjA1mOjH7s076hQ9oJq3Qce98yKuvOq1E0xqe', '2026-02-24 16:52:43', '2026-02-24 16:37:44', '2026-02-24 08:37:43', NULL),
(16, 1, '$2y$10$ZvRTlvXoPdJrPR5vCFqiouGYCUs8xlISD7gITONx0U31GmxebqNG2', '2026-02-24 16:52:44', '2026-02-24 16:37:51', '2026-02-24 08:37:44', NULL),
(17, 2, '$2y$10$HqnWX8iq8i51v3hTa0g/.us6TxPEL5aIXSyB1du61UgATnTYHsrAy', '2026-02-24 16:52:47', '2026-03-31 17:34:54', '2026-02-24 08:37:47', NULL),
(18, 1, '$2y$10$onngAYfbYQxTpBGRNLAFseoHQ.q6pqcc34UzJfNYwoGDixSq.R8mG', '2026-02-24 16:52:51', NULL, '2026-02-24 08:37:51', NULL),
(19, NULL, '$2y$10$onlCch3r3GZAoRP771.gOuW3wY2UwGRSBfvSKuiJ5O8.CgU15he0a', '2026-03-31 17:42:07', '2026-03-31 17:27:19', '2026-03-31 09:27:07', 4),
(20, 2, '$2y$10$kOufRA6T0wQrNFOwr/KbtuvjhjcuYd6klG9HbU8A./fC13DgKvnSy', '2026-03-31 17:49:54', NULL, '2026-03-31 09:34:54', NULL),
(21, 3, '$2y$10$UqrzALdbYEJAaUtHpFOBzuzKNisuH6lIZ/K9jUGOGe2Xt8UMit6ii', '2026-03-31 18:09:02', NULL, '2026-03-31 09:54:02', NULL),
(22, NULL, '$2y$10$WLPr25M/vRbEy5sWZhkOO.j6kj1okHguTmc4MXdr5fT6ZereZE6b6', '2026-04-06 08:44:35', NULL, '2026-04-06 08:29:35', 2),
(23, NULL, '$2y$10$7ecSXtE.hXXKGy.sXWZ.zOs9WsV5GIvs7aD8Aw23Q4jzdD2FRSI8C', '2026-04-06 08:46:14', '2026-04-06 08:31:27', '2026-04-06 08:31:14', 5),
(24, NULL, '$2y$10$nuD31Qt3xvbdaQ2hohPHJey9BVvpb/KdgnuzP3M8SNdxxjWA/xEhG', '2026-04-09 16:33:15', '2026-04-09 16:18:31', '2026-04-09 16:18:15', 6),
(25, NULL, '$2y$10$RQAzSodcdLRGPTK7Ov/b/ugWrNPmG7.9ws9WqPA01xnGFuBtLy.Mm', '2026-04-16 09:13:40', '2026-04-16 08:59:09', '2026-04-16 08:58:40', 7);

--
-- Triggers `email_verifications`
--
DELIMITER $$
CREATE TRIGGER `trg_ev_bi` BEFORE INSERT ON `email_verifications` FOR EACH ROW BEGIN
  IF (NEW.user_id IS NULL AND NEW.pending_id IS NULL)
     OR (NEW.user_id IS NOT NULL AND NEW.pending_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'email_verifications: set exactly one of user_id or pending_id';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_ev_bu` BEFORE UPDATE ON `email_verifications` FOR EACH ROW BEGIN
  IF (NEW.user_id IS NULL AND NEW.pending_id IS NULL)
     OR (NEW.user_id IS NOT NULL AND NEW.pending_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'email_verifications: set exactly one of user_id or pending_id';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `error_thresholds`
--

CREATE TABLE `error_thresholds` (
  `threshold_id` int NOT NULL,
  `exercise_type` enum('bicep_curl','shoulder_press','lateral_raise') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `metric_key` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `compare_op` enum('>','>=','<','<=') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '>',
  `metric_value` float NOT NULL,
  `severity` enum('info','warning','danger') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'warning',
  `enabled` tinyint(1) NOT NULL DEFAULT '1',
  `notes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `error_thresholds`
--

INSERT INTO `error_thresholds` (`threshold_id`, `exercise_type`, `metric_key`, `compare_op`, `metric_value`, `severity`, `enabled`, `notes`, `updated_at`) VALUES
(1, 'bicep_curl', 'trunk_sway', '>', 0.25, 'warning', 1, 'Fatigue proxy: sway rising', '2025-12-16 14:10:24'),
(2, 'shoulder_press', 'trunk_sway', '>', 0.3, 'warning', 1, 'Fatigue proxy: sway rising', '2025-12-16 14:10:24'),
(3, 'lateral_raise', 'trunk_sway', '>', 0.28, 'warning', 1, 'Fatigue proxy: sway rising', '2025-12-16 14:10:24'),
(4, 'bicep_curl', 'rom_score', '<', 0.6, 'warning', 1, 'ROM degradation', '2025-12-16 14:10:24'),
(5, 'shoulder_press', 'rom_score', '<', 0.55, 'warning', 1, 'ROM degradation', '2025-12-16 14:10:24'),
(6, 'lateral_raise', 'rom_score', '<', 0.55, 'warning', 1, 'ROM degradation', '2025-12-16 14:10:24');

-- --------------------------------------------------------

--
-- Table structure for table `expert_reviews`
--

CREATE TABLE `expert_reviews` (
  `review_id` bigint NOT NULL,
  `log_id` bigint NOT NULL,
  `trainer_id` int NOT NULL,
  `rating` tinyint DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `marked_good_reps` int DEFAULT NULL,
  `marked_bad_reps` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `expert_reviews`
--

INSERT INTO `expert_reviews` (`review_id`, `log_id`, `trainer_id`, `rating`, `notes`, `marked_good_reps`, `marked_bad_reps`, `created_at`) VALUES
(1, 97, 2, 5, 'Testing', NULL, NULL, '2026-02-23 03:57:35'),
(2, 96, 2, 4, 'Testing review notes.', NULL, NULL, '2026-02-23 06:39:18'),
(3, 95, 2, 5, 'TESTING', NULL, NULL, '2026-02-23 06:50:35'),
(4, 162, 2, 4, 'Ayos yan pagpatuloy mo pa', NULL, NULL, '2026-03-18 09:46:04'),
(5, 194, 2, 4, 'Needs bits of improvements in form, but overall, an okay session :)', NULL, NULL, '2026-04-09 16:39:12'),
(6, 247, 2, 3, 'Needs improvement!', NULL, NULL, '2026-04-18 02:21:43'),
(7, 251, 2, 3, 'pwede na', NULL, NULL, '2026-04-18 03:49:38');

-- --------------------------------------------------------

--
-- Table structure for table `feedback`
--

CREATE TABLE `feedback` (
  `feedback_id` bigint NOT NULL,
  `log_id` bigint NOT NULL,
  `feedback_type` enum('posture','fatigue','system','tip') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'posture',
  `severity` enum('info','warning','danger') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'info',
  `feedback_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `feedback_meta` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `feedback`
--

INSERT INTO `feedback` (`feedback_id`, `log_id`, `feedback_type`, `severity`, `feedback_text`, `created_at`, `feedback_meta`) VALUES
(1, 1, 'posture', 'warning', 'Keep elbows close to the torso to reduce swinging.', '2025-12-16 15:18:44', NULL),
(2, 1, 'tip', 'info', 'Control the negative phase for better form consistency.', '2025-12-16 15:18:44', NULL),
(3, 2, 'fatigue', 'warning', 'Trunk sway rising - consider reducing load or resting.', '2025-12-16 15:18:44', NULL),
(4, 2, 'posture', 'danger', 'Lockout path inconsistent - keep wrists stacked over elbows.', '2025-12-16 15:18:44', NULL),
(5, 3, 'posture', 'warning', 'Avoid shrugging during lateral raises; keep shoulders down.', '2025-12-16 15:18:44', NULL),
(6, 3, 'fatigue', 'warning', 'ROM degrading across reps - stop set before form breaks down.', '2025-12-16 15:18:44', NULL),
(7, 6, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-16 15:42:01', NULL),
(8, 6, 'posture', 'info', 'Rep 2: GOOD', '2025-12-16 15:42:01', NULL),
(9, 6, 'posture', 'info', 'Rep 3: GOOD', '2025-12-16 15:42:01', NULL),
(10, 6, 'posture', 'info', 'Rep 4: GOOD', '2025-12-16 15:42:01', NULL),
(11, 6, 'posture', 'warning', 'Rep 5: POSSIBLE DEVIATION', '2025-12-16 15:42:01', NULL),
(12, 6, 'posture', 'warning', 'Rep 6: POSSIBLE DEVIATION', '2025-12-16 15:42:01', NULL),
(13, 6, 'posture', 'info', 'Rep 7: GOOD', '2025-12-16 15:42:01', NULL),
(14, 6, 'posture', 'warning', 'Rep 8: POSSIBLE DEVIATION', '2025-12-16 15:42:01', NULL),
(15, 6, 'posture', 'warning', 'Rep 9: POSSIBLE DEVIATION', '2025-12-16 15:42:01', NULL),
(16, 6, 'posture', 'info', 'Rep 10: GOOD', '2025-12-16 15:42:01', NULL),
(17, 6, 'posture', 'info', 'Rep 11: GOOD', '2025-12-16 15:42:01', NULL),
(18, 7, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-16 15:44:27', NULL),
(19, 7, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-16 15:44:27', NULL),
(20, 7, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2025-12-16 15:44:27', NULL),
(21, 9, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-16 16:05:50', NULL),
(22, 9, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-16 16:05:50', NULL),
(23, 9, 'posture', 'info', 'Rep 3: GOOD', '2025-12-16 16:05:50', NULL),
(24, 9, 'posture', 'warning', 'Rep 4: POSSIBLE DEVIATION', '2025-12-16 16:05:50', NULL),
(25, 9, 'posture', 'info', 'Rep 5: GOOD', '2025-12-16 16:05:50', NULL),
(26, 9, 'posture', 'info', 'Rep 6: GOOD', '2025-12-16 16:05:50', NULL),
(27, 9, 'posture', 'info', 'Rep 7: GOOD', '2025-12-16 16:05:50', NULL),
(28, 9, 'posture', 'warning', 'Rep 8: POSSIBLE DEVIATION', '2025-12-16 16:05:50', NULL),
(29, 9, 'posture', 'warning', 'Rep 9: POSSIBLE DEVIATION', '2025-12-16 16:05:50', NULL),
(30, 9, 'fatigue', 'warning', 'Fatigue indicators detected. Consider rest/reduced load.', '2025-12-16 16:05:50', NULL),
(31, 11, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(32, 11, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(33, 11, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(34, 11, 'posture', 'warning', 'Rep 4: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(35, 11, 'posture', 'warning', 'Rep 5: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(36, 11, 'posture', 'warning', 'Rep 6: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(37, 11, 'posture', 'warning', 'Rep 7: POSSIBLE DEVIATION', '2025-12-16 16:26:05', NULL),
(38, 12, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-16 16:27:11', NULL),
(39, 12, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-16 16:27:11', NULL),
(40, 12, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2025-12-16 16:27:11', NULL),
(41, 12, 'posture', 'info', 'Rep 4: GOOD', '2025-12-16 16:27:11', NULL),
(42, 12, 'posture', 'warning', 'Rep 5: POSSIBLE DEVIATION', '2025-12-16 16:27:11', NULL),
(43, 12, 'posture', 'warning', 'Rep 6: POSSIBLE DEVIATION', '2025-12-16 16:27:11', NULL),
(44, 13, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(45, 13, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(46, 13, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(47, 13, 'posture', 'warning', 'Rep 4: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(48, 13, 'posture', 'warning', 'Rep 5: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(49, 13, 'posture', 'info', 'Rep 6: GOOD', '2025-12-18 03:11:08', NULL),
(50, 13, 'posture', 'info', 'Rep 7: GOOD', '2025-12-18 03:11:08', NULL),
(51, 13, 'posture', 'warning', 'Rep 8: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(52, 13, 'posture', 'info', 'Rep 9: GOOD', '2025-12-18 03:11:08', NULL),
(53, 13, 'posture', 'warning', 'Rep 10: POSSIBLE DEVIATION', '2025-12-18 03:11:08', NULL),
(54, 15, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-18 03:34:58', NULL),
(55, 15, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-18 03:34:58', NULL),
(56, 15, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2025-12-18 03:34:58', NULL),
(57, 15, 'posture', 'info', 'Rep 4: GOOD', '2025-12-18 03:34:58', NULL),
(58, 15, 'posture', 'info', 'Rep 5: GOOD', '2025-12-18 03:34:58', NULL),
(59, 15, 'posture', 'warning', 'Rep 6: POSSIBLE DEVIATION', '2025-12-18 03:34:58', NULL),
(60, 16, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-18 03:35:50', NULL),
(61, 16, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-18 03:35:50', NULL),
(62, 17, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-18 03:36:27', NULL),
(63, 17, 'fatigue', 'warning', 'Fatigue indicators detected. Consider rest/reduced load.', '2025-12-18 03:36:27', NULL),
(64, 18, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2025-12-18 03:55:07', NULL),
(65, 18, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2025-12-18 03:55:07', NULL),
(66, 18, 'posture', 'info', 'Rep 3: GOOD', '2025-12-18 03:55:07', NULL),
(67, 20, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(68, 20, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(69, 20, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(70, 20, 'posture', 'warning', 'Rep 4: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(71, 20, 'posture', 'warning', 'Rep 5: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(72, 20, 'posture', 'warning', 'Rep 6: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(73, 20, 'posture', 'warning', 'Rep 7: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(74, 20, 'posture', 'info', 'Rep 8: GOOD', '2026-01-21 05:13:41', NULL),
(75, 20, 'posture', 'warning', 'Rep 9: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(76, 20, 'posture', 'warning', 'Rep 10: POSSIBLE DEVIATION', '2026-01-21 05:13:41', NULL),
(77, 21, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2026-01-21 05:19:28', NULL),
(78, 21, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2026-01-21 05:19:28', NULL),
(79, 22, 'posture', 'danger', 'Rep 1: UNSAFE - Avoid swinging / leaning', '2026-01-21 05:22:59', NULL),
(80, 23, 'posture', 'warning', 'Rep 1: POSSIBLE DEVIATION', '2026-01-21 05:26:18', NULL),
(81, 23, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2026-01-21 05:26:18', NULL),
(82, 23, 'fatigue', 'warning', 'Fatigue indicators detected. Consider rest/reduced load.', '2026-01-21 05:26:18', NULL),
(83, 24, 'posture', 'danger', 'Rep 1: UNSAFE - Avoid swinging / leaning', '2026-01-21 05:29:19', NULL),
(84, 24, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2026-01-21 05:29:19', NULL),
(85, 24, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2026-01-21 05:29:19', NULL),
(86, 24, 'posture', 'warning', 'Rep 4: POSSIBLE DEVIATION', '2026-01-21 05:29:19', NULL),
(87, 25, 'posture', 'danger', 'Rep 1: UNSAFE - Avoid swinging / leaning', '2026-01-21 05:33:02', NULL),
(88, 25, 'posture', 'warning', 'Rep 2: POSSIBLE DEVIATION', '2026-01-21 05:33:02', NULL),
(89, 25, 'posture', 'warning', 'Rep 3: POSSIBLE DEVIATION', '2026-01-21 05:33:02', NULL),
(90, 43, 'posture', 'warning', 'Rep 3: COACHING - Consistency drifting (ML)', '2026-01-21 07:47:03', NULL),
(91, 43, 'posture', 'warning', 'Rep 4: COACHING - Consistency drifting (ML)', '2026-01-21 07:47:03', NULL),
(92, 43, 'posture', 'warning', 'Rep 13: COACHING - Keep elbows steadier (both)', '2026-01-21 07:47:03', NULL),
(93, 43, 'posture', 'danger', 'Rep 15: UNSAFE - Elbow drifting a lot (both)', '2026-01-21 07:47:03', NULL),
(94, 43, 'posture', 'danger', 'Rep 16: UNSAFE - Elbow drifting a lot (both)', '2026-01-21 07:47:03', NULL),
(95, 43, 'posture', 'warning', 'Rep 18: COACHING - Keep elbow steadier (right)', '2026-01-21 07:47:03', NULL),
(96, 43, 'posture', 'danger', 'Rep 20: UNSAFE - Elbow drifting a lot (right)', '2026-01-21 07:47:03', NULL),
(97, 44, 'posture', 'warning', 'Rep 3: COACHING - Consistency drifting (ML)', '2026-01-21 07:47:35', NULL),
(98, 45, 'posture', 'warning', 'Rep 4: COACHING - Keep elbows steadier (both)', '2026-01-21 08:01:40', NULL),
(99, 45, 'posture', 'warning', 'Rep 6: COACHING - Keep elbow steadier (right)', '2026-01-21 08:01:40', NULL),
(100, 45, 'posture', 'warning', 'Rep 7: COACHING - Keep elbows steadier (both)', '2026-01-21 08:01:40', NULL),
(101, 45, 'posture', 'warning', 'Rep 8: COACHING - Keep elbows steadier (both)', '2026-01-21 08:01:40', NULL),
(102, 52, 'posture', 'warning', 'Rep 3: COACHING - Consistency drifting (ML)', '2026-01-21 08:39:44', '{\"reasons\": [\"Consistency drifting (ML)\"]}'),
(103, 52, 'posture', 'warning', 'Rep 9: COACHING - Keep elbow steadier (right)', '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Fatigue trend - consider rest or lighter weight\"]}'),
(104, 52, 'posture', 'warning', 'Rep 10: COACHING - Keep elbow steadier (right)', '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue trend - consider rest or lighter weight\"]}'),
(105, 52, 'posture', 'warning', 'Rep 12: COACHING - Keep elbow steadier (left)', '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (left)\"]}'),
(106, 52, 'posture', 'warning', 'Rep 13: COACHING - Keep elbow steadier (right)', '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"]}'),
(107, 52, 'posture', 'warning', 'Rep 14: COACHING - Keep elbows steadier (both)', '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbows steadier (both)\"]}'),
(108, 52, 'fatigue', 'warning', 'Fatigue indicators detected. Consider rest/reduced load.', '2026-01-21 08:39:44', '{\"fatigue_index\": 30}'),
(109, 59, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-21 09:10:04', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(110, 59, 'posture', 'info', 'Tempo slowing - stay controlled', '2026-01-21 09:10:04', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 5}'),
(111, 59, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-01-21 09:10:04', '{\"all\": [\"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep\": 7}'),
(112, 59, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:10:04', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 8}'),
(113, 59, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-01-21 09:10:04', '{\"rep\": 9}'),
(114, 59, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:10:04', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 11}'),
(115, 62, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-21 09:21:47', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(116, 62, 'posture', 'info', 'Tempo slowing - stay controlled', '2026-01-21 09:21:47', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 8}'),
(117, 62, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-01-21 09:21:47', '{\"rep\": 9}'),
(118, 62, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:21:47', '{\"rep\": 10}'),
(119, 62, 'posture', 'info', 'Tempo slowing - stay controlled', '2026-01-21 09:21:47', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 11}'),
(120, 62, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:21:47', '{\"all\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep\": 14}'),
(121, 62, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:21:47', '{\"all\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep\": 15}'),
(122, 65, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:31:14', '{\"rep\": 1}'),
(123, 65, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:31:14', '{\"rep\": 1}'),
(124, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(125, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(126, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(127, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(128, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(129, 65, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:31:14', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(130, 65, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:31:14', '{\"rep\": 11}'),
(131, 65, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:31:14', '{\"rep\": 11}'),
(132, 66, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-21 09:37:11', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(133, 66, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:37:11', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(134, 66, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-21 09:37:11', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 9}'),
(135, 66, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-21 09:37:11', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 10}'),
(136, 69, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-01-21 09:48:16', '{\"rep\": 3}'),
(137, 69, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:48:16', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(138, 69, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-01-21 09:48:16', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 5}'),
(139, 69, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:48:16', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 8}'),
(140, 69, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-01-21 09:48:16', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 9}'),
(141, 72, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-01-22 06:44:36', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 1}'),
(142, 72, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-01-22 06:44:36', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 2}'),
(143, 72, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-22 06:44:36', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(144, 73, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-22 06:45:29', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(145, 73, 'posture', 'warning', 'Consistency drifting (ML)', '2026-01-22 06:45:29', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(146, 73, 'posture', 'warning', 'Range dropping - lighten weight or rest', '2026-01-22 06:45:29', '{\"all\": [\"Range dropping - lighten weight or rest\"], \"rep\": 5}'),
(147, 73, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-01-22 06:45:29', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 9}'),
(148, 74, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-01-22 06:46:31', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 1}'),
(149, 74, 'posture', 'warning', 'Brace core; reduce lean', '2026-01-22 06:46:31', '{\"all\": [\"Brace core; reduce lean\"], \"rep\": 2}'),
(150, 74, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-01-22 06:46:31', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 3}'),
(151, 74, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-01-22 06:46:31', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 4}'),
(152, 74, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-01-22 06:46:31', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 5}'),
(153, 74, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-01-22 06:46:31', '{\"all\": [\"Stack wrist over elbow (left)\", \"Tempo slowing - stay controlled\"], \"rep\": 6}'),
(154, 74, 'posture', 'danger', 'Wrist not stacked (right)', '2026-01-22 06:46:31', '{\"all\": [\"Wrist not stacked (right)\", \"Stack wrist over elbow (right)\"], \"rep\": 11}'),
(155, 83, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-23 01:25:26', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 2}'),
(156, 83, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 01:25:26', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(157, 88, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 01:50:44', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(158, 89, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 02:08:06', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(159, 93, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 02:19:12', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(160, 94, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 02:54:42', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(161, 94, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-23 02:54:42', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"rep\": 5}'),
(162, 94, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-23 02:54:42', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 8}'),
(163, 94, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-23 02:54:42', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 11}'),
(164, 96, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-23 02:56:41', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(165, 96, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 02:56:41', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(166, 97, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-23 03:23:16', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(167, 100, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-24 04:11:02', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 5}'),
(168, 101, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-25 06:30:51', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(169, 102, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-25 06:31:39', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 1}'),
(170, 105, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-25 06:59:09', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(171, 105, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-25 06:59:09', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 2}'),
(172, 105, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-25 06:59:09', '{\"all\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(173, 105, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-25 06:59:09', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(174, 105, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-25 06:59:09', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 5}'),
(175, 107, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 07:00:13', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(176, 107, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 07:00:13', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(177, 108, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-25 07:00:50', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 2}'),
(178, 109, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 07:01:30', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(179, 109, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 07:01:30', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(180, 110, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-25 07:04:22', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(181, 110, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-25 07:04:22', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 3}'),
(182, 122, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-25 08:17:07', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"rep\": 1}'),
(183, 122, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 08:17:07', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(184, 122, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:17:07', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 5}'),
(185, 122, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:17:07', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(186, 122, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-25 08:17:07', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"rep\": 10}'),
(187, 122, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-25 08:17:07', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 11}'),
(188, 123, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-25 08:17:56', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(189, 123, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-25 08:17:56', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"rep\": 2}'),
(190, 123, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-25 08:17:56', '{\"all\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(191, 123, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-25 08:17:56', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 5}'),
(192, 123, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-25 08:17:56', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 6}'),
(193, 123, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-25 08:17:56', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 7}'),
(194, 123, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-25 08:17:56', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 8}'),
(195, 124, 'posture', 'danger', 'Raise both arms evenly', '2026-02-25 08:19:10', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 1}'),
(196, 124, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 08:19:10', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(197, 124, 'posture', 'danger', 'Raise both arms evenly', '2026-02-25 08:19:10', '{\"all\": [\"Raise both arms evenly\", \"Tempo slowing - stay controlled\"], \"rep\": 8}'),
(198, 124, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-02-25 08:19:10', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 10}'),
(199, 124, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-02-25 08:19:10', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 12}'),
(200, 124, 'posture', 'danger', 'Raise both arms evenly', '2026-02-25 08:19:10', '{\"all\": [\"Raise both arms evenly\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 14}'),
(201, 125, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-25 08:21:25', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\"], \"rep\": 1}'),
(202, 125, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-25 08:21:25', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(203, 125, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:21:25', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(204, 125, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:21:25', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 5}'),
(205, 125, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:21:25', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 6}'),
(206, 125, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-25 08:21:25', '{\"all\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep\": 7}'),
(207, 137, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 08:09:52', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(208, 137, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 08:09:52', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 4}'),
(209, 137, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 08:09:52', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 5}'),
(210, 137, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 08:09:52', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"rep\": 9}'),
(211, 137, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 08:09:52', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 10}'),
(212, 138, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 08:13:56', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(213, 138, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 08:13:56', '{\"all\": [\"Keep elbows steadier (both)\", \"Tempo slowing - stay controlled\"], \"rep\": 6}'),
(214, 140, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-27 08:34:18', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(215, 143, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 08:57:33', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(216, 143, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-27 08:57:33', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 5}'),
(217, 143, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-27 08:57:33', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"rep\": 6}'),
(218, 143, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 08:57:33', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(219, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 1}'),
(220, 144, 'posture', 'danger', 'Wrist not stacked (left)', '2026-02-27 08:58:37', '{\"all\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"rep\": 2}'),
(221, 144, 'posture', 'danger', 'Wrist not stacked (left)', '2026-02-27 08:58:37', '{\"all\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"rep\": 3}'),
(222, 144, 'posture', 'danger', 'Wrist not stacked (left)', '2026-02-27 08:58:37', '{\"all\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"rep\": 4}'),
(223, 144, 'posture', 'warning', 'Press more evenly', '2026-02-27 08:58:37', '{\"all\": [\"Press more evenly\"], \"rep\": 5}'),
(224, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 6}'),
(225, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 7}'),
(226, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 8}'),
(227, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 9}'),
(228, 144, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 08:58:37', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 11}'),
(229, 147, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 09:35:30', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 1}'),
(230, 147, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 09:35:30', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(231, 149, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-27 10:02:21', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(232, 150, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-27 10:09:21', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(233, 150, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 10:09:21', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(234, 150, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 10:09:21', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 6}'),
(235, 150, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:09:21', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(236, 150, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:09:21', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 8}'),
(237, 151, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-02-27 10:10:56', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 3}'),
(238, 151, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-02-27 10:10:56', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 4}'),
(239, 151, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-02-27 10:10:56', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 5}'),
(240, 152, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 10:11:22', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 1}'),
(241, 153, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 10:33:15', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(242, 155, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 10:39:45', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(243, 155, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-27 10:39:45', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 5}'),
(244, 157, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-02-27 10:46:47', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 2}'),
(245, 157, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:46:47', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(246, 157, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:46:47', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(247, 158, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-02-27 10:47:08', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"rep\": 1}'),
(248, 159, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-27 10:47:35', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(249, 160, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-27 10:49:45', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(250, 160, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:49:45', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(251, 160, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 10:49:45', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(252, 160, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-02-27 10:49:45', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 4}'),
(253, 161, 'posture', 'warning', 'Consistency drifting (ML)', '2026-02-27 11:44:57', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(254, 161, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 11:44:57', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 4}'),
(255, 161, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-02-27 11:44:57', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 5}'),
(256, 161, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-02-27 11:44:57', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 6}'),
(257, 161, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-02-27 11:44:57', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"rep\": 7}'),
(258, 162, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-03-18 09:43:49', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(259, 162, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-03-18 09:43:49', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(260, 163, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-03-18 09:52:02', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(261, 163, 'posture', 'warning', 'Consistency drifting (ML)', '2026-03-18 09:52:02', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(262, 163, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-03-18 09:52:02', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 6}'),
(263, 163, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-03-18 09:52:02', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 8}'),
(264, 170, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-01 06:05:06', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(265, 172, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-01 06:11:23', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(266, 173, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-01 06:12:28', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(267, 174, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-01 06:28:12', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(268, 174, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-01 06:28:12', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(269, 174, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-04-01 06:28:12', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 8}'),
(270, 174, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-01 06:28:12', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 9}'),
(271, 174, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-01 06:28:12', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 10}'),
(272, 176, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-06 08:02:55', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(273, 176, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-06 08:02:55', '{\"all\": [\"Elbow drifting a lot (right)\"], \"rep\": 2}'),
(274, 176, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:02:55', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(275, 177, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:07:16', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(276, 177, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:07:16', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(277, 178, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-06 08:09:17', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(278, 178, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:09:17', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(279, 179, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:12:05', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(280, 180, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:27:59', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(281, 180, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:27:59', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 7}'),
(282, 180, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-06 08:27:59', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 8}'),
(283, 181, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-08 03:32:01', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(284, 182, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-08 09:36:33', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(285, 182, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-04-08 09:36:33', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 7}'),
(294, 190, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-09 12:52:49', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(295, 191, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-09 13:10:00', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(296, 191, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-09 13:10:00', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 2}'),
(297, 192, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-09 14:11:25', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(298, 192, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-09 14:11:25', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(299, 192, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-04-09 14:11:25', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 6}'),
(300, 192, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-04-09 14:11:25', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 7}'),
(301, 192, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-09 14:11:25', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 8}'),
(302, 193, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-09 16:30:58', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(303, 194, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-09 16:34:20', '{\"all\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(304, 194, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-09 16:34:20', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(305, 194, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-09 16:34:20', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 5}'),
(306, 194, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-09 16:34:20', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 6}'),
(307, 195, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-11 01:50:32', '{\"all\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(308, 195, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-11 01:50:32', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(309, 196, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-13 02:18:20', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(310, 196, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-13 02:18:20', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(311, 196, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-13 02:18:20', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"rep\": 5}'),
(312, 197, 'posture', 'warning', 'Stack wrist over elbow (left)', '2026-04-13 02:23:06', '{\"all\": [\"Stack wrist over elbow (left)\"], \"rep\": 1}'),
(313, 197, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-04-13 02:23:06', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 2}'),
(314, 197, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-13 02:23:06', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(315, 197, 'posture', 'danger', 'Wrist not stacked (right)', '2026-04-13 02:23:06', '{\"all\": [\"Wrist not stacked (right)\", \"Stack wrists over elbows (both)\"], \"rep\": 5}'),
(316, 198, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-13 02:24:35', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(317, 198, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-13 02:24:35', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 6}'),
(318, 198, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-13 02:24:35', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 7}'),
(319, 198, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-13 02:24:35', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Early fatigue signs - keep the raise controlled\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 8}'),
(320, 198, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-13 02:24:35', '{\"all\": [\"Don\'t curl (elbow too bent)\", \"Early fatigue signs - keep the raise controlled\", \"Arms bending more - avoid upright-row motion\"], \"rep\": 9}'),
(321, 200, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-15 13:40:47', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(322, 201, 'posture', 'danger', 'Wrist not stacked (left)', '2026-04-15 13:43:59', '{\"all\": [\"Wrist not stacked (left)\", \"Brace core; reduce lean\"], \"rep\": 1}'),
(323, 201, 'posture', 'danger', 'Avoid leaning / back arch', '2026-04-15 13:43:59', '{\"all\": [\"Avoid leaning / back arch\", \"Stack wrist over elbow (right)\"], \"rep\": 2}'),
(324, 201, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-04-15 13:43:59', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 4}'),
(325, 202, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-16 09:09:09', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 1}'),
(326, 202, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-04-16 09:09:09', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 2}'),
(327, 202, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-04-16 09:09:09', '{\"all\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(328, 202, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-16 09:09:09', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"rep\": 4}'),
(329, 202, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-16 09:09:09', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 5}'),
(330, 203, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 10:31:23', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(331, 203, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 10:31:23', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(332, 203, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 10:31:23', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(333, 205, 'posture', 'danger', 'Raise both arms evenly', '2026-04-17 10:36:21', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 5}'),
(334, 205, 'posture', 'warning', 'Arms bending more - avoid upright-row motion', '2026-04-17 10:36:21', '{\"all\": [\"Arms bending more - avoid upright-row motion\"], \"rep\": 7}'),
(335, 206, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 10:54:07', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(336, 206, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 10:54:07', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 6}'),
(337, 206, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 10:54:07', '{\"all\": [\"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 7}'),
(338, 207, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 10:57:48', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(339, 207, 'posture', 'warning', 'Keep torso stable', '2026-04-17 10:57:48', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(340, 207, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 10:57:48', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 5}'),
(341, 208, 'posture', 'warning', 'Keep elbows steadier (both)', '2026-04-17 11:01:31', '{\"all\": [\"Keep elbows steadier (both)\"], \"rep\": 2}'),
(342, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(343, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(344, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(345, 209, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-17 11:07:31', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep torso stable\"], \"rep\": 4}'),
(346, 209, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:07:31', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"rep\": 5}'),
(347, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 6}'),
(348, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 7}'),
(349, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 8}'),
(350, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 9}'),
(351, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 10}'),
(352, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 11}'),
(353, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 12}'),
(354, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 13}'),
(355, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 14}'),
(356, 209, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:07:31', '{\"all\": [\"Keep torso stable\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 15}'),
(357, 209, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 11:07:31', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 16}'),
(358, 209, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 11:07:31', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"rep\": 17}'),
(359, 210, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:11:14', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"rep\": 2}'),
(360, 210, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:11:14', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(361, 210, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:11:14', '{\"all\": [\"Keep torso stable\"], \"rep\": 5}'),
(362, 210, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:11:14', '{\"all\": [\"Keep torso stable\"], \"rep\": 6}'),
(363, 210, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:11:14', '{\"all\": [\"Keep torso stable\"], \"rep\": 7}'),
(364, 211, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:13:04', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(365, 211, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:13:04', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(366, 211, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:13:04', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(367, 211, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:13:04', '{\"all\": [\"Keep torso stable\"], \"rep\": 4}');
INSERT INTO `feedback` (`feedback_id`, `log_id`, `feedback_type`, `severity`, `feedback_text`, `created_at`, `feedback_meta`) VALUES
(368, 211, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:13:04', '{\"all\": [\"Keep torso stable\"], \"rep\": 5}'),
(369, 211, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 11:13:04', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 6}'),
(370, 215, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:20:39', '{\"all\": [\"Avoid torso swinging\", \"Keep elbows steadier (both)\"], \"rep\": 4}'),
(371, 217, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 11:24:03', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(372, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 2}'),
(373, 218, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 11:31:59', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(374, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 8}'),
(375, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 17}'),
(376, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 19}'),
(377, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 21}'),
(378, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 22}'),
(379, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 23}'),
(380, 218, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 11:31:59', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 24}'),
(381, 218, 'posture', 'danger', 'Don\'t curl (elbow too bent)', '2026-04-17 11:31:59', '{\"all\": [\"Don\'t curl (elbow too bent)\"], \"rep\": 25}'),
(382, 219, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:36:37', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"rep\": 1}'),
(383, 219, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:36:37', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(384, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(385, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(386, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(387, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 4}'),
(388, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 5}'),
(389, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 6}'),
(390, 220, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 11:38:09', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(391, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 8}'),
(392, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 9}'),
(393, 220, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:38:09', '{\"all\": [\"Keep torso stable\"], \"rep\": 10}'),
(394, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(395, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(396, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(397, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(398, 222, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 11:50:40', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 5}'),
(399, 222, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 11:50:40', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 6}'),
(400, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\"], \"rep\": 7}'),
(401, 222, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:50:40', '{\"all\": [\"Keep torso stable\"], \"rep\": 8}'),
(402, 223, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 11:55:22', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(403, 223, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 11:55:22', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(404, 223, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:55:22', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(405, 223, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 11:55:22', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(406, 223, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:55:22', '{\"all\": [\"Keep torso stable\"], \"rep\": 6}'),
(407, 223, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 11:55:22', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 7}'),
(408, 223, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 11:55:22', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 12}'),
(409, 223, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 11:55:22', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 13}'),
(410, 223, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 11:55:22', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 14}'),
(411, 223, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 11:55:22', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 15}'),
(412, 223, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 11:55:22', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 23}'),
(413, 224, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:57:44', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(414, 224, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:57:44', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(415, 224, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:57:44', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(416, 224, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:57:44', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"rep\": 5}'),
(417, 224, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:57:44', '{\"all\": [\"Keep torso stable\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 6}'),
(418, 224, 'posture', 'danger', 'Avoid torso swinging', '2026-04-17 11:57:44', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 8}'),
(419, 224, 'posture', 'warning', 'Keep torso stable', '2026-04-17 11:57:44', '{\"all\": [\"Keep torso stable\"], \"rep\": 9}'),
(420, 225, 'posture', 'warning', 'Keep torso stable', '2026-04-17 12:12:13', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(421, 225, 'posture', 'warning', 'Keep torso stable', '2026-04-17 12:12:13', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(422, 226, 'posture', 'warning', 'Keep torso stable', '2026-04-17 12:34:29', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(423, 226, 'posture', 'warning', 'Keep torso stable', '2026-04-17 12:34:29', '{\"all\": [\"Keep torso stable\"], \"rep\": 2}'),
(424, 226, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 12:34:29', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(425, 226, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 12:34:29', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(426, 226, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 12:34:29', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 5}'),
(427, 226, 'posture', 'warning', 'Keep torso stable', '2026-04-17 12:34:29', '{\"all\": [\"Keep torso stable\"], \"rep\": 11}'),
(428, 227, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 12:48:31', '{\"all\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(429, 227, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 12:48:31', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(430, 227, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 12:48:31', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 5}'),
(431, 227, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 12:48:31', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 6}'),
(432, 228, 'posture', 'warning', 'Keep torso stable', '2026-04-17 13:00:54', '{\"all\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(433, 228, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:00:54', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 10}'),
(434, 230, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:04:44', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 1}'),
(435, 230, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:04:44', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 2}'),
(436, 230, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 13:04:44', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(437, 230, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 13:04:44', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 11}'),
(438, 230, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 13:04:44', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 12}'),
(439, 230, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 13:04:44', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 13}'),
(440, 230, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 13:04:44', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 14}'),
(441, 230, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 13:04:44', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 15}'),
(442, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\"], \"rep\": 1}'),
(443, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\", \"Press more evenly\"], \"rep\": 2}'),
(444, 231, 'posture', 'warning', 'Press more evenly', '2026-04-17 13:06:51', '{\"all\": [\"Press more evenly\"], \"rep\": 3}'),
(445, 231, 'posture', 'warning', 'Stack wrist over elbow (right)', '2026-04-17 13:06:51', '{\"all\": [\"Stack wrist over elbow (right)\"], \"rep\": 4}'),
(446, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\", \"Press more evenly\"], \"rep\": 5}'),
(447, 231, 'posture', 'warning', 'Press more evenly', '2026-04-17 13:06:51', '{\"all\": [\"Press more evenly\"], \"rep\": 6}'),
(448, 231, 'posture', 'warning', 'Press more evenly', '2026-04-17 13:06:51', '{\"all\": [\"Press more evenly\"], \"rep\": 7}'),
(449, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\", \"Press more evenly\"], \"rep\": 8}'),
(450, 231, 'posture', 'warning', 'Brace core; reduce lean', '2026-04-17 13:06:51', '{\"all\": [\"Brace core; reduce lean\", \"Consistency drifting (ML)\"], \"rep\": 10}'),
(451, 231, 'posture', 'warning', 'Press more evenly', '2026-04-17 13:06:51', '{\"all\": [\"Press more evenly\"], \"rep\": 11}'),
(452, 231, 'posture', 'danger', 'Wrist not stacked (left)', '2026-04-17 13:06:51', '{\"all\": [\"Wrist not stacked (left)\", \"Press more evenly\"], \"rep\": 12}'),
(453, 231, 'posture', 'warning', 'Press more evenly', '2026-04-17 13:06:51', '{\"all\": [\"Press more evenly\", \"Tempo slowing - stay controlled\"], \"rep\": 13}'),
(454, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\", \"Brace core; reduce lean\"], \"rep\": 14}'),
(455, 231, 'posture', 'danger', 'Keep arms even', '2026-04-17 13:06:51', '{\"all\": [\"Keep arms even\", \"Press more evenly\", \"Range dropping - lighten weight or rest\"], \"rep\": 15}'),
(456, 232, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 13:08:45', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(457, 232, 'posture', 'danger', 'Avoid leaning / swinging (side-to-side)', '2026-04-17 13:08:45', '{\"all\": [\"Avoid leaning / swinging (side-to-side)\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(458, 234, 'posture', 'warning', 'Keep torso stable', '2026-04-17 13:49:49', '{\"all\": [\"Keep torso stable\"], \"rep\": 1}'),
(459, 234, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:49:49', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 2}'),
(460, 234, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:49:49', '{\"all\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(461, 234, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 13:49:49', '{\"all\": [\"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 9}'),
(462, 235, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 14:00:40', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(463, 235, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 14:00:40', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 9}'),
(464, 235, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-17 14:00:40', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 10}'),
(465, 235, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 14:00:40', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 11}'),
(466, 235, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 14:00:40', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 14}'),
(467, 235, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 14:00:40', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 15}'),
(468, 238, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 14:18:53', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(469, 239, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 14:22:41', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(470, 241, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 15:19:18', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(471, 241, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-17 15:19:18', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(472, 241, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-04-17 15:19:18', '{\"all\": [\"Tempo slowing - stay controlled\"], \"rep\": 10}'),
(473, 241, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 15:19:18', '{\"all\": [\"Keep elbow steadier (left)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 12}'),
(474, 242, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 23:59:50', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 1}'),
(475, 242, 'posture', 'warning', 'Tempo slowing - stay controlled', '2026-04-17 23:59:50', '{\"all\": [\"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 6}'),
(476, 242, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 9}'),
(477, 242, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-17 23:59:50', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 10}'),
(478, 242, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 23:59:50', '{\"all\": [\"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 11}'),
(479, 242, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 12}'),
(480, 242, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 13}'),
(481, 242, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 14}'),
(482, 242, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 16}'),
(483, 242, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-17 23:59:50', '{\"all\": [\"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 17}'),
(484, 242, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-17 23:59:50', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 18}'),
(485, 242, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 23}'),
(486, 242, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-17 23:59:50', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 24}'),
(487, 244, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 00:53:09', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 11}'),
(488, 244, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-18 00:53:09', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 12}'),
(489, 244, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 00:53:09', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 13}'),
(490, 244, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-18 00:53:09', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 14}'),
(491, 244, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-18 00:53:09', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"rep\": 15}'),
(492, 245, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 01:03:27', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"rep\": 2}'),
(493, 246, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 02:03:15', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 1}'),
(494, 246, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 02:03:15', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(495, 246, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 02:03:15', '{\"all\": [\"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 8}'),
(496, 246, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 02:03:15', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 9}'),
(497, 246, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 02:03:15', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 10}'),
(498, 247, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 02:11:45', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(499, 247, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 02:11:45', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\"], \"rep\": 2}'),
(500, 247, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 02:11:45', '{\"all\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(501, 247, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 02:11:45', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 4}'),
(502, 248, 'posture', 'warning', 'Stack wrists over elbows (both)', '2026-04-18 02:13:23', '{\"all\": [\"Stack wrists over elbows (both)\"], \"rep\": 1}'),
(503, 248, 'posture', 'danger', 'Wrists not stacked (both)', '2026-04-18 02:13:23', '{\"all\": [\"Wrists not stacked (both)\"], \"rep\": 2}'),
(504, 248, 'posture', 'danger', 'Keep arms even', '2026-04-18 02:13:23', '{\"all\": [\"Keep arms even\", \"Brace core; reduce lean\"], \"rep\": 3}'),
(505, 248, 'posture', 'danger', 'Keep arms even', '2026-04-18 02:13:23', '{\"all\": [\"Keep arms even\", \"Press more evenly\"], \"rep\": 4}'),
(506, 248, 'posture', 'danger', 'Avoid leaning / back arch', '2026-04-18 02:13:23', '{\"all\": [\"Avoid leaning / back arch\", \"Brace core; reduce lean\"], \"rep\": 5}'),
(507, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 2}'),
(508, 249, 'posture', 'danger', 'Avoid leaning / swinging (side-to-side)', '2026-04-18 02:14:40', '{\"all\": [\"Avoid leaning / swinging (side-to-side)\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(509, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\", \"Consistency drifting (ML)\"], \"rep\": 4}'),
(510, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 5}'),
(511, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 6}'),
(512, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 8}'),
(513, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 9}'),
(514, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 11}'),
(515, 249, 'posture', 'danger', 'Raise both arms evenly', '2026-04-18 02:14:40', '{\"all\": [\"Raise both arms evenly\"], \"rep\": 12}'),
(516, 249, 'posture', 'danger', 'Avoid leaning / swinging (side-to-side)', '2026-04-18 02:14:40', '{\"all\": [\"Avoid leaning / swinging (side-to-side)\"], \"rep\": 13}'),
(517, 250, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 02:15:47', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep\": 1}'),
(518, 250, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 02:15:47', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 2}'),
(519, 250, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 02:15:47', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Consistency drifting (ML)\"], \"rep\": 3}'),
(520, 250, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 02:15:47', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\"], \"rep\": 4}'),
(521, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\"], \"rep\": 1}'),
(522, 251, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 03:46:55', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(523, 251, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 03:46:55', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(524, 251, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 03:46:55', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 5}'),
(525, 251, 'posture', 'warning', 'Keep torso stable', '2026-04-18 03:46:55', '{\"all\": [\"Keep torso stable\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 10}'),
(526, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 11}'),
(527, 251, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-18 03:46:55', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 12}'),
(528, 251, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 03:46:55', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 13}'),
(529, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 14}'),
(530, 251, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 03:46:55', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 15}'),
(531, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"rep\": 16}'),
(532, 251, 'posture', 'danger', 'Elbow drifting a lot (left)', '2026-04-18 03:46:55', '{\"all\": [\"Elbow drifting a lot (left)\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 17}'),
(533, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 18}'),
(534, 251, 'posture', 'danger', 'Avoid torso swinging', '2026-04-18 03:46:55', '{\"all\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 19}'),
(535, 252, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 17:56:55', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(536, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 6}'),
(537, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 7}'),
(538, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 9}'),
(539, 252, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 17:56:55', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"rep\": 12}'),
(540, 252, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 17:56:55', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 13}'),
(541, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"rep\": 14}'),
(542, 252, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 17:56:55', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 15}'),
(543, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 16}'),
(544, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 17}'),
(545, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 18}'),
(546, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep\": 19}'),
(547, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 20}'),
(548, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep\": 21}'),
(549, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 22}'),
(550, 252, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 17:56:55', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 23}'),
(551, 252, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 17:56:55', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 24}'),
(552, 252, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 17:56:55', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 25}'),
(553, 252, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 17:56:55', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 26}'),
(554, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 27}'),
(555, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 28}'),
(556, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 29}'),
(557, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 30}'),
(558, 252, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 17:56:55', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 31}'),
(559, 253, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 18:02:38', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(560, 253, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 18:02:38', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(561, 253, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:02:38', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 13}'),
(562, 253, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:02:38', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 14}'),
(563, 253, 'fatigue', 'warning', 'Stop recommended. Strong fatigue detected since Rep 13. Top issues: right elbow drift x25. Please rest or reduce weight.', '2026-04-18 18:02:38', '{\"details\": {\"c_dur\": 1, \"c_rom\": 0, \"c_drift\": 0.9979111949602764, \"c_trunk\": 0, \"dur_ratio\": 1.3809273440670604, \"rom_ratio\": 1.0052320655337652, \"drift_delta\": 0.14968667924404144, \"trunk_delta\": -0.005806908011436462}, \"since_rep\": 13, \"top_issues\": [[\"right elbow drift\", 25]], \"fatigue_index\": 45.9728455344836, \"fatigue_level\": \"high\", \"fatigue_trend\": \"sharply_rising\"}'),
(564, 253, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:02:38', '{\"all\": [\"Keep elbow steadier (right)\", \"High fatigue - stop the set or reduce load\", \"Consistency drifting (ML)\"], \"rep\": 15}'),
(565, 254, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 18:06:31', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 3}'),
(566, 254, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 18:06:31', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 4}'),
(567, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 9}'),
(568, 254, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 18:06:31', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 13}'),
(569, 254, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 14}'),
(570, 254, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 16}'),
(571, 254, 'posture', 'warning', 'Early fatigue signs - keep elbows steady and control the rep', '2026-04-18 18:06:31', '{\"all\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"rep\": 17}'),
(572, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 18}'),
(573, 254, 'posture', 'warning', 'Consistency drifting (ML)', '2026-04-18 18:06:31', '{\"all\": [\"Consistency drifting (ML)\"], \"rep\": 19}'),
(574, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"rep\": 20}'),
(575, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"rep\": 21}'),
(576, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"rep\": 22}'),
(577, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 23}'),
(578, 254, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 24}'),
(579, 254, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 18:06:31', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep\": 25}'),
(580, 254, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 26}'),
(581, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 27}'),
(582, 254, 'posture', 'warning', 'Fatigue rising - prioritize control and consider rest', '2026-04-18 18:06:31', '{\"all\": [\"Fatigue rising - prioritize control and consider rest\"], \"rep\": 28}'),
(583, 254, 'posture', 'warning', 'Keep torso stable', '2026-04-18 18:06:31', '{\"all\": [\"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"rep\": 29}'),
(584, 254, 'posture', 'warning', 'Keep torso stable', '2026-04-18 18:06:31', '{\"all\": [\"Keep torso stable\"], \"rep\": 30}'),
(585, 254, 'posture', 'warning', 'Keep elbow steadier (left)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (left)\"], \"rep\": 31}'),
(586, 254, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"rep\": 32}'),
(587, 254, 'posture', 'warning', 'Keep elbow steadier (right)', '2026-04-18 18:06:31', '{\"all\": [\"Keep elbow steadier (right)\"], \"rep\": 34}'),
(588, 254, 'fatigue', 'warning', 'Stop recommended. Strong fatigue detected since Rep 9. Top issues: right elbow drift x260, left elbow drift x96. Please rest or reduce weight.', '2026-04-18 18:06:31', '{\"details\": {\"c_dur\": 0.8403309908180556, \"c_rom\": 0.14015104119823232, \"c_drift\": 1, \"c_trunk\": 0.7083872126208411, \"dur_ratio\": 1.3161323963272222, \"rom_ratio\": 0.8835607292884596, \"drift_delta\": 0.4694075286388397, \"trunk_delta\": 0.0637548491358757}, \"since_rep\": 9, \"top_issues\": [[\"right elbow drift\", 260], [\"left elbow drift\", 96]], \"fatigue_index\": 55.117912978771685, \"fatigue_level\": \"high\", \"fatigue_trend\": \"rising\"}'),
(589, 254, 'posture', 'danger', 'Elbow drifting a lot (right)', '2026-04-18 18:06:31', '{\"all\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"High fatigue - stop the set or reduce load\"], \"rep\": 35}');

-- --------------------------------------------------------

--
-- Table structure for table `login_otps`
--

CREATE TABLE `login_otps` (
  `otp_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `otp_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `attempts` int NOT NULL DEFAULT '0',
  `consumed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `login_otps`
--

INSERT INTO `login_otps` (`otp_id`, `user_id`, `otp_hash`, `expires_at`, `attempts`, `consumed_at`, `created_at`) VALUES
(1, 1, '$2y$10$3MomIdEOahQUBSawUITPTu/3Ck8zsmzY7aI0c4CPcXCfr4CHqcYyW', '2026-02-24 16:45:05', 0, NULL, '2026-02-24 08:40:05'),
(2, 1, '$2y$10$y9p6RCk6unuz2FZLjJh3NeTJtxP9v0HwEWvbAYWgUQiMc/hPvNKkm', '2026-02-24 16:46:18', 0, NULL, '2026-02-24 08:41:18'),
(3, 1, '$2y$10$bHIhzBAgzLO0iYo9AjgcSO4n//KhMh0PzrJsfYhr1XjBE2GOBOkS6', '2026-02-24 16:46:25', 0, NULL, '2026-02-24 08:41:25'),
(4, 1, '$2y$10$RnkR9UB3lWqdBWV1E2kVJuSPbR8PQDZJCIoWIv9kHr1IZq5y6JCoi', '2026-02-24 16:47:25', 0, NULL, '2026-02-24 08:42:25');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `message_id` bigint NOT NULL,
  `sender_id` int NOT NULL,
  `recipient_id` int NOT NULL,
  `subject` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `log_id` bigint DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`message_id`, `sender_id`, `recipient_id`, `subject`, `body`, `log_id`, `is_read`, `created_at`) VALUES
(1, 1, 12, 'test message', 'hi! testing msg function', NULL, 1, '2026-04-09 16:22:24');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notif_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `notif_type` enum('assignment','review_posted','session_uploaded','system') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'system',
  `message` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `log_id` bigint DEFAULT NULL,
  `from_user_id` int DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notif_id`, `user_id`, `notif_type`, `message`, `log_id`, `from_user_id`, `is_read`, `created_at`) VALUES
(1, 2, 'assignment', 'New trainer request from: Test Trainee User (Trainee ID: 3)', NULL, 3, 1, '2026-02-23 05:19:06'),
(2, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-23 05:19:13'),
(3, 3, 'review_posted', 'Your session #95 has been reviewed by your trainer.', 95, 2, 1, '2026-02-23 06:50:35'),
(4, 2, 'system', 'Your LiftRight account status changed to: pending.', NULL, 1, 1, '2026-02-23 07:04:46'),
(5, 2, 'system', 'Your LiftRight account status changed to: pending.', NULL, 1, 1, '2026-02-23 07:04:47'),
(6, 2, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:04:49'),
(7, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:04:54'),
(8, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:39'),
(9, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:45'),
(10, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:45'),
(11, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:51'),
(12, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:51'),
(13, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:05:52'),
(14, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:06:15'),
(15, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:06:27'),
(16, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:06:27'),
(17, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:06:31'),
(18, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:06:52'),
(19, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:07:00'),
(20, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:07:00'),
(21, 3, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-02-23 07:08:33'),
(22, 1, 'system', 'Profile change request submitted by Test Trainee User1 (user@liftright.local).', NULL, 3, 1, '2026-02-23 09:04:47'),
(23, 3, 'system', 'Your profile update was approved by an admin.', NULL, 1, 1, '2026-02-23 09:06:13'),
(25, 1, 'system', 'Profile change request submitted by LiftRight Trainer (trainer@liftright.local).', NULL, 2, 1, '2026-02-28 10:30:43'),
(26, 1, 'system', 'Profile change request submitted by LiftRight Trainer (trainer@liftright.local).', NULL, 2, 1, '2026-02-28 10:46:54'),
(27, 2, 'system', 'Your profile update was approved by an admin.', NULL, 1, 1, '2026-02-28 10:47:11'),
(28, 1, 'system', 'Profile change request submitted by Zy Cris (crispino.zyrus@gmail.com).', NULL, NULL, 1, '2026-02-28 10:54:35'),
(30, 1, 'system', 'Profile change request submitted by Test Trainee User1 (user@liftright.local).', NULL, 3, 1, '2026-02-28 11:13:40'),
(31, 3, 'system', 'Your profile update was approved by an admin.', NULL, 1, 1, '2026-02-28 11:13:49'),
(32, 1, 'system', 'Profile change request submitted by LiftRight Trainer (trainer@liftright.local).', NULL, 2, 1, '2026-02-28 11:40:26'),
(33, 2, 'system', 'Your profile update was approved by an admin.', NULL, 1, 1, '2026-02-28 11:40:34'),
(34, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:03:57'),
(35, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:03:57'),
(36, 1, 'system', 'Unlink requested by trainee ID 3.', NULL, 3, 1, '2026-02-28 12:04:14'),
(37, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:16:23'),
(38, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:16:23'),
(39, 1, 'system', 'Unlink requested by trainee ID 3.', NULL, 3, 1, '2026-02-28 12:16:36'),
(40, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:25:35'),
(41, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:25:35'),
(42, 1, 'system', 'Unlink requested: Test Trainee User1 (#3) from LiftRight Trainer (#2).', NULL, 3, 1, '2026-02-28 12:25:50'),
(43, 3, 'system', 'Your trainer unlink request has been approved.', NULL, 1, 1, '2026-02-28 12:35:00'),
(44, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:57:21'),
(45, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-02-28 12:57:21'),
(46, 1, 'system', 'Unlink requested: Test Trainee User1 (#3) from LiftRight Trainer (#2).', NULL, 3, 1, '2026-03-04 11:50:18'),
(47, 3, 'system', 'Your trainer unlink request has been approved.', NULL, 1, 1, '2026-03-04 11:54:41'),
(48, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-03-04 11:55:12'),
(49, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-03-04 11:55:12'),
(50, 1, 'system', 'Unlink requested: Test Trainee User1 (#3) from LiftRight Trainer (#2).', NULL, 3, 1, '2026-03-04 11:56:23'),
(51, 3, 'system', 'Your trainer unlink request has been approved.', NULL, 1, 1, '2026-03-04 11:56:35'),
(52, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-03-18 09:45:37'),
(53, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-03-18 09:45:37'),
(54, 3, 'review_posted', 'Your session #162 has been reviewed by your trainer.', 162, 2, 1, '2026-03-18 09:46:04'),
(55, 1, 'system', 'Unlink requested: Test Trainee User1 (#3) from LiftRight Trainer (#2).', NULL, 3, 1, '2026-03-18 09:47:15'),
(56, 3, 'system', 'Your trainer unlink request has been approved.', NULL, 1, 1, '2026-03-18 09:47:51'),
(57, 10, 'system', 'Your LiftRight account has been approved.', NULL, 1, 0, '2026-03-31 09:36:27'),
(58, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-04-01 06:30:19'),
(59, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-04-01 06:30:19'),
(60, 1, 'system', 'Profile change request submitted by LiftRight Trainer (trainer@liftright.local).', NULL, 2, 0, '2026-04-06 08:18:46'),
(61, 2, 'system', 'Your profile update was approved by an admin.', NULL, 1, 0, '2026-04-06 08:20:09'),
(62, 11, 'system', 'Your LiftRight account has been approved.', NULL, 1, 0, '2026-04-06 08:31:40'),
(63, 12, 'system', 'Your LiftRight account has been approved.', NULL, 1, 1, '2026-04-09 16:22:06'),
(64, 12, 'system', 'New message: test message', NULL, 1, 1, '2026-04-09 16:22:24'),
(65, 1, 'system', 'Profile change request submitted by Febrilo Par (diamondthekidrs44@gmail.com).', NULL, 12, 0, '2026-04-09 16:23:57'),
(66, 12, 'system', 'Your profile update was approved by an admin.', NULL, 1, 1, '2026-04-09 16:24:32'),
(67, 1, 'system', 'Profile change request submitted by Febrilo Par (diamondthekidrs44@gmail.com).', NULL, 12, 0, '2026-04-09 16:36:25'),
(68, 12, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 0, '2026-04-09 16:36:50'),
(69, 12, 'review_posted', 'Your session #194 has been reviewed by your trainer.', 194, 2, 1, '2026-04-09 16:39:12'),
(70, 12, 'system', 'Your profile update was approved by an admin.', NULL, 1, 0, '2026-04-09 16:39:34'),
(71, 1, 'system', 'Unlink requested: Febrilo Par (#12) from LiftRight Trainer (#2).', NULL, 12, 0, '2026-04-10 00:13:17'),
(72, 12, 'system', 'Your trainer unlink request has been approved.', NULL, 1, 0, '2026-04-10 00:13:47'),
(73, 12, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 0, '2026-04-10 00:15:02'),
(74, 13, 'system', 'Your LiftRight account has been approved.', NULL, 1, 0, '2026-04-16 09:03:59'),
(75, 13, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 0, '2026-04-16 09:11:54'),
(76, 12, 'review_posted', 'Your session #247 has been reviewed by your trainer.', 247, 2, 1, '2026-04-18 02:21:43'),
(77, 3, 'review_posted', 'Your session #251 has been reviewed by your trainer.', 251, 2, 1, '2026-04-18 03:49:38');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `reset_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `consumed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pending_registrations`
--

CREATE TABLE `pending_registrations` (
  `pending_id` bigint NOT NULL,
  `full_name` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('user','trainer') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user',
  `age` int DEFAULT NULL,
  `affiliation` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `credential_type` enum('cpt','scs','pt','student','other') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `credential_ref` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statement` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `proof_file` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `proof_mime` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `profile_change_requests`
--

CREATE TABLE `profile_change_requests` (
  `request_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `requested_full_name` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_email` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_age` int DEFAULT NULL,
  `requested_birthdate` date DEFAULT NULL,
  `requested_gender` enum('male','female','other','prefer_not_to_say') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_bio` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `requested_profile_photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_qualification` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_years_experience` tinyint UNSIGNED DEFAULT NULL,
  `requested_specializations` json DEFAULT NULL,
  `status` enum('pending','approved','rejected','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewed_by` int DEFAULT NULL,
  `admin_notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `profile_change_requests`
--

INSERT INTO `profile_change_requests` (`request_id`, `user_id`, `requested_full_name`, `requested_email`, `requested_age`, `requested_birthdate`, `requested_gender`, `requested_bio`, `requested_profile_photo`, `requested_qualification`, `requested_years_experience`, `requested_specializations`, `status`, `created_at`, `reviewed_at`, `reviewed_by`, `admin_notes`) VALUES
(3, 2, 'LiftRight Trainer', 'trainer@liftright.local', NULL, NULL, NULL, 'wasdasdadsas', 'uploads/pending_profiles/p_2_fb6980f47f10.png', '312das', 3, '[\"sdasdasdsada\"]', 'approved', '2026-02-28 10:46:54', '2026-02-28 10:47:11', 1, ''),
(5, 3, 'Test Trainee User1', 'user@liftright.local', NULL, '2003-11-14', 'male', 'Test Traineeeeeeee', 'uploads/pending_profiles/p_3_5d1914e0e924.png', NULL, NULL, NULL, 'approved', '2026-02-28 11:13:40', '2026-02-28 11:13:49', 1, ''),
(6, 2, 'LiftRight Trainer', 'trainer@liftright.local', NULL, NULL, NULL, 'wasdasdadsas', 'uploads/pending_profiles/p_2_8f5090a4d771.jpg', '312das', 3, '[\"sdasdasdsada\"]', 'approved', '2026-02-28 11:40:26', '2026-02-28 11:40:34', 1, ''),
(7, 2, 'LiftRight Trainer', 'trainer@liftright.local', NULL, NULL, NULL, 'wasdasdadsas', 'uploads/pending_profiles/p_2_d86e9c974764.png', '312das', 3, '[\"sdasdasdsada\"]', 'approved', '2026-04-06 08:18:46', '2026-04-06 08:20:09', 1, ''),
(8, 12, 'Febrilo Par', 'diamondthekidrs44@gmail.com', NULL, NULL, NULL, 'Hi! I\'m one of the contributors to this thesis, and I\'m also the CEO of Hotdog.', 'uploads/pending_profiles/p_12_1c281420a877.jpg', NULL, NULL, NULL, 'approved', '2026-04-09 16:23:57', '2026-04-09 16:24:32', 1, 'yes, sure thing lmao'),
(9, 12, 'Febrilo Par', 'diamondthekidrs44@gmail.com', NULL, '2004-02-17', 'male', 'Hi! I\'m one of the contributors to this thesis, and I\'m also the CEO of Hotdog.', NULL, NULL, NULL, NULL, 'approved', '2026-04-09 16:36:25', '2026-04-09 16:39:34', 1, '');

-- --------------------------------------------------------

--
-- Table structure for table `rep_metrics`
--

CREATE TABLE `rep_metrics` (
  `rep_id` bigint NOT NULL,
  `log_id` bigint NOT NULL,
  `rep_index` int NOT NULL,
  `duration_ms` int DEFAULT NULL,
  `rom_score` float DEFAULT NULL,
  `trunk_sway` float DEFAULT NULL,
  `confidence_avg` float DEFAULT NULL,
  `form_label` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'good',
  `anomaly_score` float DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rep_meta` json DEFAULT NULL,
  `fatigue_score` float DEFAULT NULL,
  `fatigue_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fatigue_trend` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rep_metrics`
--

INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(1, 1, 1, 820, 0.82, 0.18, 0.93, 'good', -0.21, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(2, 1, 2, 870, 0.79, 0.2, 0.92, 'good', -0.18, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(3, 1, 3, 960, 0.61, 0.27, 0.9, 'bad', 0.14, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(4, 2, 1, 980, 0.71, 0.24, 0.91, 'good', -0.1, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(5, 2, 2, 1120, 0.57, 0.33, 0.88, 'bad', 0.28, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(6, 2, 3, 1180, 0.52, 0.36, 0.86, 'bad', 0.35, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(7, 3, 1, 900, 0.76, 0.22, 0.92, 'good', -0.12, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(8, 3, 2, 1040, 0.58, 0.31, 0.89, 'bad', 0.22, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(9, 3, 3, 1100, 0.54, 0.34, 0.87, 'bad', 0.3, '2025-12-16 15:18:44', NULL, NULL, NULL, NULL),
(10, 6, 1, 7858, 173.096, 0.080673, 0.63766, 'bad', -0.735833, '2025-12-16 15:42:00', NULL, NULL, NULL, NULL),
(11, 6, 2, 2201, 165.037, 0.0225981, 0.78353, 'good', 0.0259225, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(12, 6, 3, 2183, 162.348, 0.0595842, 0.871811, 'good', 0.0294182, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(13, 6, 4, 2196, 163.977, 0.0490298, 0.89875, 'good', 0.0284478, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(14, 6, 5, 2002, 161.99, 0.0560793, 0.905292, 'bad', -0.0053243, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(15, 6, 6, 2200, 149.176, 0.0634695, 0.903285, 'bad', -0.0773745, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(16, 6, 7, 2194, 167.388, 0.0510686, 0.902458, 'good', 0.0837952, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(17, 6, 8, 2366, 129.572, 0.0312399, 0.900192, 'bad', -0.725101, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(18, 6, 9, 2001, 173.77, 0.0457862, 0.905305, 'bad', -0.0540958, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(19, 6, 10, 2147, 167.833, 0.0457972, 0.896895, 'good', 0.0761759, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(20, 6, 11, 2783, 171.255, 0.0472899, 0.896884, 'good', 0.117082, '2025-12-16 15:42:01', NULL, NULL, NULL, NULL),
(21, 7, 1, 3388, 165.505, 0.166974, 0.666523, 'bad', -0.0402354, '2025-12-16 15:44:27', NULL, NULL, NULL, NULL),
(22, 7, 2, 1605, 170.088, 0.0544593, 0.788342, 'bad', -0.102785, '2025-12-16 15:44:27', NULL, NULL, NULL, NULL),
(23, 7, 3, 3167, 146.917, 0.0814012, 0.840871, 'bad', -0.376511, '2025-12-16 15:44:27', NULL, NULL, NULL, NULL),
(24, 9, 1, 9019, 164.647, 0.379041, 0.649708, 'bad', -0.735837, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(25, 9, 2, 7649, 172.065, 0.0443829, 0.884427, 'bad', -0.735817, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(26, 9, 3, 2437, 173.978, 0.0509671, 0.903304, 'good', 0.0767213, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(27, 9, 4, 1805, 169.727, 0.0713813, 0.88077, 'bad', -0.00839751, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(28, 9, 5, 2043, 168.734, 0.0562414, 0.881708, 'good', 0.0679527, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(29, 9, 6, 2993, 174.499, 0.0587825, 0.886609, 'good', 0.116987, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(30, 9, 7, 2768, 168.762, 0.060294, 0.877282, 'good', 0.0621909, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(31, 9, 8, 3734, 97.023, 0.0600447, 0.924754, 'bad', -0.735837, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(32, 9, 9, 13420, 140.225, 0.0639284, 0.975708, 'bad', -0.735837, '2025-12-16 16:05:50', NULL, NULL, NULL, NULL),
(33, 11, 1, 3403, 1.46185, 0.134891, 0.766881, 'bad', -0.235058, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(34, 11, 2, 3060, 1.39852, 0.124065, 0.770497, 'bad', -0.17256, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(35, 11, 3, 2595, 1.40223, 0.126726, 0.771451, 'bad', -0.167435, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(36, 11, 4, 2834, 1.33283, 0.130465, 0.769565, 'bad', -0.203341, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(37, 11, 5, 2861, 1.29935, 0.120452, 0.76543, 'bad', -0.164476, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(38, 11, 6, 3026, 1.39877, 0.12297, 0.772472, 'bad', -0.165668, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(39, 11, 7, 2820, 1.26023, 0.10841, 0.724801, 'bad', -0.111303, '2025-12-16 16:26:05', NULL, NULL, NULL, NULL),
(40, 12, 1, 2412, 0.998028, 0.0451839, 0.944008, 'bad', -0.329878, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(41, 12, 2, 3398, 1.86042, 0.0713655, 0.952826, 'bad', -0.100267, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(42, 12, 3, 1395, 0.52981, 0.0348635, 0.917523, 'bad', -0.264802, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(43, 12, 4, 3431, 1.80887, 0.0546985, 0.936435, 'good', 0.0123083, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(44, 12, 5, 3645, 1.77558, 0.0514144, 0.945668, 'bad', -0.0384855, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(45, 12, 6, 3981, 1.77016, 0.0391085, 0.950093, 'bad', -0.192144, '2025-12-16 16:27:11', NULL, NULL, NULL, NULL),
(46, 13, 1, 5234, 159.768, 0.099645, 0.984575, 'bad', -0.670517, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(47, 13, 2, 2975, 156.562, 0.114205, 0.975709, 'bad', -0.160471, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(48, 13, 3, 2658, 158.569, 0.110856, 0.975714, 'bad', -0.0955522, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(49, 13, 4, 3215, 165.599, 0.131132, 0.969543, 'bad', -0.00521502, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(50, 13, 5, 3823, 171.126, 0.0674258, 0.958964, 'bad', -0.0286935, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(51, 13, 6, 2815, 167.076, 0.0741964, 0.963494, 'good', 0.109648, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(52, 13, 7, 2217, 161.766, 0.0676832, 0.967913, 'good', 0.0377659, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(53, 13, 8, 2206, 157.314, 0.0653031, 0.967073, 'bad', -0.0729687, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(54, 13, 9, 2283, 167.913, 0.0686071, 0.971694, 'good', 0.093386, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(55, 13, 10, 1974, 158.646, 0.0507018, 0.975945, 'bad', -0.0977481, '2025-12-18 03:11:08', NULL, NULL, NULL, NULL),
(56, 15, 1, 3804, 161.809, 0.0510914, 0.986487, 'bad', -0.375102, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(57, 15, 2, 3564, 159.409, 0.0830197, 0.975112, 'bad', -0.103472, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(58, 15, 3, 2926, 159.641, 0.118871, 0.970548, 'bad', -0.225054, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(59, 15, 4, 2666, 166.873, 0.114009, 0.97137, 'good', 0.0763706, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(60, 15, 5, 2608, 167.788, 0.0739779, 0.969813, 'good', 0.12292, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(61, 15, 6, 5323, 177.13, 0.100217, 0.978771, 'bad', -0.674112, '2025-12-18 03:34:58', NULL, NULL, NULL, NULL),
(62, 16, 1, 5449, 0.81788, 0.0625306, 0.702331, 'bad', -0.326209, '2025-12-18 03:35:50', NULL, NULL, NULL, NULL),
(63, 16, 2, 2369, 1.9807, 0.162693, 0.600566, 'bad', -0.333992, '2025-12-18 03:35:50', NULL, NULL, NULL, NULL),
(64, 17, 1, 5295, 4.11571, 2.23144, 0.787671, 'bad', -0.593459, '2025-12-18 03:36:27', NULL, NULL, NULL, NULL),
(65, 18, 1, 1831, 174.062, 0.0164443, 0.958606, 'bad', -0.185295, '2025-12-18 03:55:07', NULL, NULL, NULL, NULL),
(66, 18, 2, 4135, 171.733, 0.0333796, 0.966726, 'bad', -0.106151, '2025-12-18 03:55:07', NULL, NULL, NULL, NULL),
(67, 18, 3, 3585, 170.579, 0.0566112, 0.976331, 'good', 0.0840965, '2025-12-18 03:55:07', NULL, NULL, NULL, NULL),
(68, 20, 1, 6304, 159.791, 0.09846, 0.617875, 'bad', -0.630997, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(69, 20, 2, 2442, 156.826, 0.131624, 0.842804, 'bad', -0.057186, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(70, 20, 3, 2419, 162.682, 0.122457, 0.860763, 'bad', -0.0656358, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(71, 20, 4, 2429, 149.992, 0.0982155, 0.954084, 'bad', -0.0300327, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(72, 20, 5, 3633, 173.578, 0.0901147, 0.982326, 'bad', -0.306283, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(73, 20, 6, 2790, 167.975, 0.0860855, 0.98846, 'bad', -0.110965, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(74, 20, 7, 3202, 106.344, 0.0961589, 0.991349, 'bad', -0.49507, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(75, 20, 8, 1597, 156.292, 0.0931575, 0.992714, 'good', 0.0654208, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(76, 20, 9, 2194, 164.842, 0.0900667, 0.991728, 'bad', -0.00843886, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(77, 20, 10, 2410, 160.773, 0.0847282, 0.99101, 'bad', -0.00782555, '2026-01-21 05:13:41', NULL, NULL, NULL, NULL),
(78, 21, 1, 2841, 121.094, 0.0870322, 0.952085, 'bad', -0.309314, '2026-01-21 05:19:28', NULL, NULL, NULL, NULL),
(79, 21, 2, 2943, 154.924, 0.0727494, 0.970546, 'bad', -0.0785307, '2026-01-21 05:19:28', NULL, NULL, NULL, NULL),
(80, 22, 1, 2392, 149.466, 0.122431, 0.941616, 'bad', -0.0479871, '2026-01-21 05:22:59', NULL, NULL, NULL, NULL),
(81, 23, 1, 3669, 164.601, 0.406494, 0.766064, 'bad', -0.367241, '2026-01-21 05:26:18', NULL, NULL, NULL, NULL),
(82, 23, 2, 1987, 104.844, 0.0902702, 0.918063, 'bad', -0.442346, '2026-01-21 05:26:18', NULL, NULL, NULL, NULL),
(83, 24, 1, 4758, 131.622, 0.156482, 0.651115, 'bad', -0.548639, '2026-01-21 05:29:19', NULL, NULL, NULL, NULL),
(84, 24, 2, 6784, 154.478, 0.244475, 0.831264, 'bad', -0.667993, '2026-01-21 05:29:19', NULL, NULL, NULL, NULL),
(85, 24, 3, 2193, 111.954, 0.0822804, 0.940718, 'bad', -0.360985, '2026-01-21 05:29:19', NULL, NULL, NULL, NULL),
(86, 24, 4, 2011, 133.173, 0.0675652, 0.95148, 'bad', -0.0677044, '2026-01-21 05:29:19', NULL, NULL, NULL, NULL),
(87, 25, 1, 5878, 154.921, 0.187347, 0.639149, 'bad', -0.62714, '2026-01-21 05:33:02', NULL, NULL, NULL, NULL),
(88, 25, 2, 5909, 167.981, 0.154504, 0.83076, 'bad', -0.627308, '2026-01-21 05:33:02', NULL, NULL, NULL, NULL),
(89, 25, 3, 4430, 166.742, 0.0881009, 0.970252, 'bad', -0.419843, '2026-01-21 05:33:02', NULL, NULL, NULL, NULL),
(90, 38, 1, 9922, 166.078, 0, 0.962314, 'good', -0.683359, '2026-01-21 06:56:09', NULL, NULL, NULL, NULL),
(91, 38, 2, 3041, 169.095, 0, 0.9777, 'good', -0.201621, '2026-01-21 06:56:09', NULL, NULL, NULL, NULL),
(92, 39, 1, 14033, 173.652, 0, 0.977514, 'good', -0.683567, '2026-01-21 07:01:21', NULL, NULL, NULL, NULL),
(93, 39, 2, 2338, 163.357, 0, 0.98705, 'good', -0.0714775, '2026-01-21 07:01:21', NULL, NULL, NULL, NULL),
(94, 40, 1, 4167, 170.012, 0, 0.974324, 'good', -0.397436, '2026-01-21 07:01:44', NULL, NULL, NULL, NULL),
(95, 40, 2, 2630, 159.745, 0, 0.979772, 'good', -0.0897234, '2026-01-21 07:01:44', NULL, NULL, NULL, NULL),
(96, 41, 1, 3394, 169.076, 0, 0.984216, 'good', -0.259547, '2026-01-21 07:02:09', NULL, NULL, NULL, NULL),
(97, 41, 2, 2840, 157.857, 0, 0.988724, 'good', -0.114262, '2026-01-21 07:02:09', NULL, NULL, NULL, NULL),
(98, 43, 1, 8697, 166.742, NULL, 0.909111, 'bad', -0.68183, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(99, 43, 2, 2809, 161.759, NULL, 0.956604, 'bad', -0.122961, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(100, 43, 3, 2986, 168.37, NULL, 0.972244, 'bad', -0.188171, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(101, 43, 4, 5343, 154.476, NULL, 0.984287, 'bad', -0.54606, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(102, 43, 5, 3957, 163.637, NULL, 0.977664, 'bad', -0.335378, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(103, 43, 6, 2352, 165.339, NULL, 0.975896, 'bad', -0.0849855, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(104, 43, 7, 4593, 153.482, NULL, 0.971128, 'bad', -0.43305, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(105, 43, 8, 2377, 142.338, NULL, 0.977181, 'bad', -0.0703426, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(106, 43, 9, 4134, 154.45, NULL, 0.979838, 'bad', -0.350471, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(107, 43, 10, 1974, 158.032, NULL, 0.981299, 'bad', -0.0188986, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(108, 43, 11, 1994, 147.786, NULL, 0.983396, 'bad', -0.0172296, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(109, 43, 12, 1973, 157.996, NULL, 0.981491, 'bad', -0.0185767, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(110, 43, 13, 4889, 118.138, NULL, 0.98603, 'bad', -0.568255, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(111, 43, 14, 4169, 133.317, NULL, 0.983305, 'bad', -0.414869, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(112, 43, 15, 2802, 160.919, NULL, 0.989636, 'bad', -0.17019, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(113, 43, 16, 1762, 143.923, NULL, 0.990115, 'bad', -0.0974028, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(114, 43, 17, 1950, 112.813, NULL, 0.983953, 'bad', -0.351139, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(115, 43, 18, 4710, 98.7302, NULL, 0.985617, 'bad', -0.625529, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(116, 43, 19, 1771, 135.174, NULL, 0.986647, 'bad', -0.139676, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(117, 43, 20, 9209, 149.011, NULL, 0.987217, 'bad', -0.682755, '2026-01-21 07:47:03', NULL, NULL, NULL, NULL),
(118, 44, 1, 3457, 163.712, NULL, 0.972972, 'bad', -0.242591, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(119, 44, 2, 1984, 166.054, NULL, 0.976692, 'bad', -0.0623639, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(120, 44, 3, 2220, 141.121, NULL, 0.95132, 'bad', -0.0756699, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(121, 44, 4, 2196, 155.54, NULL, 0.968871, 'bad', -0.0280505, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(122, 44, 5, 2172, 156.427, NULL, 0.976709, 'bad', -0.0276759, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(123, 44, 6, 2171, 155.869, NULL, 0.979511, 'bad', -0.0264026, '2026-01-21 07:47:35', NULL, NULL, NULL, NULL),
(124, 45, 1, 11258, 148.409, NULL, 0.880664, 'bad', -0.683552, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(125, 45, 2, 2182, 170.707, NULL, 0.93265, 'bad', -0.113044, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(126, 45, 3, 2199, 153.091, NULL, 0.96365, 'bad', -0.0260954, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(127, 45, 4, 14263, 139.831, NULL, 0.992391, 'bad', -0.683567, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(128, 45, 5, 1987, 164.893, NULL, 0.98869, 'bad', -0.0537193, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(129, 45, 6, 2233, 116.537, NULL, 0.990526, 'bad', -0.318226, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(130, 45, 7, 2411, 110.373, NULL, 0.992208, 'bad', -0.400179, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(131, 45, 8, 2397, 122.423, NULL, 0.993393, 'bad', -0.270641, '2026-01-21 08:01:40', NULL, NULL, NULL, NULL),
(132, 47, 1, 6784, 161.899, 0.227323, 0.876238, 'bad', -0.667147, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(133, 47, 2, 2354, 163.105, 0.0464487, 0.95541, 'bad', -0.00132196, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(134, 47, 3, 2224, 148.11, 0.0663432, 0.972186, 'good', 0.0287156, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(135, 47, 4, 2387, 162.412, 0.0670506, 0.982414, 'bad', -0.00121378, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(136, 47, 5, 2406, 146.817, 0.0506017, 0.974497, 'good', 0.00743634, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(137, 47, 6, 2391, 154.063, 0.0417256, 0.976774, 'good', 0.0216089, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(138, 47, 7, 2418, 151.761, 0.0312564, 0.973609, 'good', 0.00728359, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(139, 47, 8, 4790, 102.271, 0.0534963, 0.987464, 'bad', -0.615356, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(140, 47, 9, 4000, 167.174, 0.0489667, 0.9882, 'bad', -0.344841, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(141, 47, 10, 3614, 155.714, 0.0849443, 0.987675, 'bad', -0.268948, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(142, 47, 11, 2796, 134.615, 0.0868121, 0.988147, 'bad', -0.186133, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(143, 47, 12, 1652, 137.941, 0.046969, 0.990059, 'good', 0.00145176, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(144, 47, 13, 6033, 121.761, 0.0572939, 0.990797, 'bad', -0.641439, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(145, 47, 14, 3428, 169.568, 0.0694103, 0.989136, 'bad', -0.226502, '2026-01-21 08:17:58', NULL, NULL, NULL, NULL),
(146, 52, 1, 6734, 170.419, 0, 0.867907, 'bad', -0.658722, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 179.28982543945312, \"min_angle\": 8.870448112487793, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(147, 52, 2, 2706, 163.576, 0, 0.901046, 'bad', -0.117395, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 173.64199829101562, \"min_angle\": 10.066011428833008, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.23255273699760437}', NULL, NULL, NULL),
(148, 52, 3, 2394, 157.766, 0, 0.945328, 'bad', -0.0528621, '2026-01-21 08:39:43', '{\"reasons\": [\"Consistency drifting (ML)\"], \"max_angle\": 175.8173370361328, \"min_angle\": 18.051538467407227, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2221380919218063}', NULL, NULL, NULL),
(149, 52, 4, 2810, 161.978, 0, 0.940984, 'bad', -0.12506, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 175.84732055664062, \"min_angle\": 13.869434356689451, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2492063194513321}', NULL, NULL, NULL),
(150, 52, 5, 2402, 152.876, 0, 0.952015, 'bad', -0.0466503, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 175.84732055664062, \"min_angle\": 22.970823287963867, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.8877519318307844, \"rom_ratio\": 0.97399584510217, \"drift_delta\": 0}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.24586953222751615}', NULL, NULL, NULL),
(151, 52, 6, 2439, 148.521, 0, 0.951591, 'bad', -0.0542014, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 171.4605255126953, \"min_angle\": 22.93995475769043, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9012692376905476, \"rom_ratio\": 0.9438108769270416, \"drift_delta\": 0}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2207394391298294}', NULL, NULL, NULL),
(152, 52, 7, 2582, 150.703, 0, 0.967358, 'bad', -0.0688575, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 171.4605255126953, \"min_angle\": 20.7578067779541, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9012692376905476, \"rom_ratio\": 0.9303906358372486, \"drift_delta\": -0.025130093097686768}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.21016760170459747}', NULL, NULL, NULL),
(153, 52, 8, 16564, 141.342, 0, 0.969546, 'bad', -0.683567, '2026-01-21 08:39:43', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"max_angle\": 177.13262939453125, \"min_angle\": 35.79106140136719, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9541169345161712, \"rom_ratio\": 0.9169187715515128, \"drift_delta\": -0.025130093097686768}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(154, 52, 9, 17234, 131.818, 0, 0.987323, 'bad', -0.683567, '2026-01-21 08:39:43', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Fatigue trend - consider rest or lighter weight\"], \"max_angle\": 179.09915161132812, \"min_angle\": 47.28144073486328, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 55.00000000000001, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 1, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 6.120051465924412, \"rom_ratio\": 0.872597902761815, \"drift_delta\": 0.4541304677724838}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(155, 52, 10, 2381, 147.717, 0, 0.989718, 'bad', -0.0692615, '2026-01-21 08:39:43', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue trend - consider rest or lighter weight\"], \"max_angle\": 179.09915161132812, \"min_angle\": 31.3817138671875, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 55.00000000000001, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 1, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 6.120051465924412, \"rom_ratio\": 0.872597902761815, \"drift_delta\": 0.4541304677724838}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.4060981571674347}', NULL, NULL, NULL),
(156, 52, 11, 2390, 148.4, 0, 0.989412, 'bad', -0.0487976, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 177.63243103027344, \"min_angle\": 29.23249626159668, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 19.227434992790226, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0.6409144997596741, \"dur_ratio\": 0.8832566751343173, \"rom_ratio\": 0.9119604954652843, \"drift_delta\": 0.16022862493991852}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2074006050825119}', NULL, NULL, NULL),
(157, 52, 12, 2583, 146.861, 0, 0.989616, 'bad', -0.0763524, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"max_angle\": 177.51304626464844, \"min_angle\": 30.65174865722656, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (left)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.8832566751343173, \"rom_ratio\": 0.9119604954652843, \"drift_delta\": -0.03846892714500427}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.20084881782531736}', NULL, NULL, NULL),
(158, 52, 13, 6750, 124.983, 0, 0.990348, 'bad', -0.661235, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"max_angle\": 177.5733184814453, \"min_angle\": 52.59041213989258, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9546594730906364, \"rom_ratio\": 0.9066749584617108, \"drift_delta\": -0.03846892714500427}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.5365550518035889}', NULL, NULL, NULL),
(159, 52, 14, 2622, 118.966, 0, 0.991268, 'bad', -0.334012, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"max_angle\": 175.34707641601562, \"min_angle\": 56.38128662109375, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 30, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbows steadier (both)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 0.9688617570239574, \"rom_ratio\": 0.7716047503356319, \"drift_delta\": 0.26334773004055023}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.5092172622680664}', NULL, NULL, NULL),
(160, 59, 1, 5918, 169.605, 0, 0.852071, 'good', -0.610375, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.32528603076934814}', NULL, NULL, NULL),
(161, 59, 2, 2253, 171.418, 0, 0.975255, 'good', -0.128691, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3044107258319855}', NULL, NULL, NULL),
(162, 59, 3, 2630, 167.937, 0, 0.981844, 'good', -0.136326, '2026-01-21 09:10:04', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2622838020324707}', NULL, NULL, NULL),
(163, 59, 4, 2268, 172.683, 0, 0.983508, 'good', -0.137406, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1859431564807892}', NULL, NULL, NULL),
(164, 59, 5, 5096, 176.287, 0, 0.988985, 'good', -0.557563, '2026-01-21 09:10:04', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4959814846515655}', NULL, NULL, NULL),
(165, 59, 6, 3754, 173.332, 0, 0.992142, 'good', -0.408132, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 26.53618745971174, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(166, 59, 7, 5375, 174.784, 0, 0.989793, 'good', -0.592709, '2026-01-21 09:10:04', '{\"reasons\": [\"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 43.757704989137046, \"elbow_drift_absmax\": 0.6936243772506714}', NULL, NULL, NULL),
(167, 59, 8, 2631, 161.551, 0, 0.990731, 'good', -0.109397, '2026-01-21 09:10:04', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 33.54769640136213, \"elbow_drift_absmax\": 0.3713323473930359}', NULL, NULL, NULL),
(168, 59, 9, 4867, 175.323, 0, 0.99289, 'bad', -0.54963, '2026-01-21 09:10:04', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 42.01306212597752, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(169, 59, 10, 1749, 172.864, 0, 0.99004, 'good', -0.113716, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 8.03059458732605, \"elbow_drift_absmax\": 0.25232434272766113}', NULL, NULL, NULL),
(170, 59, 11, 2130, 173.217, 0, 0.990724, 'good', -0.133999, '2026-01-21 09:10:04', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2666179835796356}', NULL, NULL, NULL),
(171, 62, 1, 12149, 174.745, 0, 0.887926, 'good', -0.683565, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.46460798382759094}', NULL, NULL, NULL),
(172, 62, 2, 2623, 166.52, 0, 0.988528, 'good', -0.124095, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22641436755657196}', NULL, NULL, NULL),
(173, 62, 3, 2247, 166.03, 0, 0.992123, 'good', -0.0797447, '2026-01-21 09:21:47', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20102261006832123}', NULL, NULL, NULL),
(174, 62, 4, 2373, 171.462, 0, 0.989915, 'good', -0.135225, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20140595734119415}', NULL, NULL, NULL),
(175, 62, 5, 2376, 163.288, 0, 0.989284, 'good', -0.07459, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20319874584674835}', NULL, NULL, NULL),
(176, 62, 6, 3266, 163.924, 0, 0.99164, 'good', -0.208927, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19082623720169067}', NULL, NULL, NULL),
(177, 62, 7, 2230, 165.209, 0, 0.989737, 'good', -0.0727207, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19399471580982208}', NULL, NULL, NULL),
(178, 62, 8, 4379, 176.145, 0, 0.992272, 'good', -0.457839, '2026-01-21 09:21:47', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.493680751881344, \"elbow_drift_absmax\": 0.23149646818637848}', NULL, NULL, NULL),
(179, 62, 9, 2245, 125.076, 0, 0.992483, 'bad', -0.284637, '2026-01-21 09:21:47', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 3.3957266807556152, \"elbow_drift_absmax\": 0.6722539067268372}', NULL, NULL, NULL),
(180, 62, 10, 2747, 161.119, 0, 0.989746, 'bad', -0.134736, '2026-01-21 09:21:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 27.706090807914737, \"elbow_drift_absmax\": 0.43408283591270447}', NULL, NULL, NULL),
(181, 62, 11, 7140, 135.161, 0, 0.991856, 'good', -0.665085, '2026-01-21 09:21:47', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 27.706090807914737, \"elbow_drift_absmax\": 0.3292917013168335}', NULL, NULL, NULL),
(182, 62, 12, 2623, 155.881, 0, 0.992572, 'good', -0.0779313, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 15.131154656410216, \"elbow_drift_absmax\": 0.25298792123794556}', NULL, NULL, NULL),
(183, 62, 13, 2997, 104.562, 0, 0.993562, 'good', -0.484705, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 15.366686762676496, \"elbow_drift_absmax\": 0.3703940510749817}', NULL, NULL, NULL),
(184, 62, 14, 4869, 141.436, 0, 0.993305, 'good', -0.49655, '2026-01-21 09:21:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 20.29896873365428, \"elbow_drift_absmax\": 0.43488672375679016}', NULL, NULL, NULL),
(185, 62, 15, 8007, 168.558, 0, 0.995205, 'good', -0.677918, '2026-01-21 09:21:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 43.792721599129656, \"elbow_drift_absmax\": 0.4769136607646942}', NULL, NULL, NULL),
(186, 63, 1, 9793, 169.995, 0, 0.827457, 'good', -0.683261, '2026-01-21 09:23:23', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.375911682844162}', NULL, NULL, NULL),
(187, 63, 2, 2248, 163.163, 0, 0.965979, 'good', -0.06228, '2026-01-21 09:23:23', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2464689463376999}', NULL, NULL, NULL),
(188, 63, 3, 2386, 133.009, 0, 0.984285, 'bad', -0.21754, '2026-01-21 09:23:23', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6477876305580139}', NULL, NULL, NULL),
(189, 64, 1, 4030, 172.682, 0, 0.967955, 'good', -0.389258, '2026-01-21 09:24:35', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28266090154647827}', NULL, NULL, NULL),
(190, 64, 2, 2117, 170.906, 0, 0.986923, 'good', -0.112787, '2026-01-21 09:24:35', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2895864248275757}', NULL, NULL, NULL),
(191, 65, 1, 9185, 102.103, 0, 0.857504, 'bad', -0.6833, '2026-01-21 09:31:14', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6563076376914978}', NULL, NULL, NULL),
(192, 65, 2, 4002, 134.783, 0, 0.990721, 'warning', -0.386703, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4653170108795166}', NULL, NULL, NULL),
(193, 65, 3, 2002, 141.154, 0, 0.992149, 'warning', -0.0699449, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4243333339691162}', NULL, NULL, NULL),
(194, 65, 4, 3988, 164.477, 0, 0.995505, 'warning', -0.362963, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.46540993452072144}', NULL, NULL, NULL),
(195, 65, 5, 1995, 151.638, 0, 0.993096, 'good', -0.0145493, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2920394241809845}', NULL, NULL, NULL),
(196, 65, 6, 2128, 148.837, 0, 0.989682, 'good', -0.0334229, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.34767061471939087}', NULL, NULL, NULL),
(197, 65, 7, 2127, 171.262, 0, 0.991222, 'good', -0.11347, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20696058869361875}', NULL, NULL, NULL),
(198, 65, 8, 2264, 151.587, 0, 0.992003, 'good', -0.0332493, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26511189341545105}', NULL, NULL, NULL),
(199, 65, 9, 2117, 169.001, 0, 0.990955, 'good', -0.0947048, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26917046308517456}', NULL, NULL, NULL),
(200, 65, 10, 2127, 161.991, 0, 0.992559, 'good', -0.04726, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2713639438152313}', NULL, NULL, NULL),
(201, 65, 11, 2111, 112.111, 0, 0.993702, 'bad', -0.407349, '2026-01-21 09:31:14', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.675918459892273}', NULL, NULL, NULL),
(202, 66, 1, 4336, 166.642, 0, 0.971944, 'good', -0.412583, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2318998426198959}', NULL, NULL, NULL),
(203, 66, 2, 1998, 163.121, 0, 0.982444, 'good', -0.0430639, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19817207753658295}', NULL, NULL, NULL),
(204, 66, 3, 2245, 164.138, 0, 0.988058, 'warning', -0.0670865, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2131891697645187}', NULL, NULL, NULL),
(205, 66, 4, 2006, 164.568, 0, 0.989633, 'good', -0.0526123, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22231295704841617}', NULL, NULL, NULL),
(206, 66, 5, 2117, 154.989, 0, 0.989566, 'good', -0.0209307, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2335340529680252}', NULL, NULL, NULL),
(207, 66, 6, 2250, 156.017, 0, 0.98772, 'good', -0.033825, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.6654757261276245, \"elbow_drift_absmax\": 0.22785858809947968}', NULL, NULL, NULL),
(208, 66, 7, 3509, 165.568, 0, 0.991148, 'warning', -0.269709, '2026-01-21 09:37:11', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 1.3465315103530884, \"elbow_drift_absmax\": 0.3645757734775543}', NULL, NULL, NULL),
(209, 66, 8, 2750, 169.132, 0, 0.988952, 'good', -0.159893, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.7189168648312334, \"elbow_drift_absmax\": 0.2367648184299469}', NULL, NULL, NULL),
(210, 66, 9, 2997, 163.957, 0, 0.990817, 'warning', -0.163695, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 5.122157091436281, \"elbow_drift_absmax\": 0.2373572736978531}', NULL, NULL, NULL),
(211, 66, 10, 2744, 170.083, 0, 0.989625, 'warning', -0.16627, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.7189168648312334, \"elbow_drift_absmax\": 0.22888554632663727}', NULL, NULL, NULL),
(212, 66, 11, 2262, 167.028, 0, 0.989011, 'good', -0.0887133, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.0446657345690156, \"elbow_drift_absmax\": 0.23160088062286377}', NULL, NULL, NULL),
(213, 66, 12, 2366, 165.39, 0, 0.989687, 'good', -0.0868989, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.0613250732421875, \"elbow_drift_absmax\": 0.2311573326587677}', NULL, NULL, NULL),
(214, 66, 13, 2391, 160.252, 0, 0.990668, 'good', -0.061625, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.1145508289337158, \"elbow_drift_absmax\": 0.2347409576177597}', NULL, NULL, NULL),
(215, 69, 1, 9774, 153.473, 0, 0.818485, 'good', -0.683237, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5271849632263184}', NULL, NULL, NULL),
(216, 69, 2, 2102, 174.15, 0, 0.945224, 'good', -0.139894, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20203272998332977}', NULL, NULL, NULL),
(217, 69, 3, 1704, 125.056, 0, 0.978747, 'bad', -0.257012, '2026-01-21 09:48:16', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6398125886917114}', NULL, NULL, NULL),
(218, 69, 4, 2245, 129.544, 0, 0.988464, 'warning', -0.193445, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4893537163734436}', NULL, NULL, NULL),
(219, 69, 5, 1720, 117.13, 0, 0.992937, 'warning', -0.326845, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5807831287384033}', NULL, NULL, NULL),
(220, 69, 6, 2050, 159.041, 0, 0.991658, 'good', -0.0287383, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27310922741889954}', NULL, NULL, NULL),
(221, 69, 7, 1976, 153.131, 0, 0.993116, 'good', -0.0124984, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2805273234844208}', NULL, NULL, NULL),
(222, 69, 8, 1645, 120.088, 0, 0.992969, 'warning', -0.287272, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5508155822753906}', NULL, NULL, NULL),
(223, 69, 9, 3641, 143.722, 0, 0.991829, 'warning', -0.299714, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 3.714201450347901, \"elbow_drift_absmax\": 0.5203053951263428}', NULL, NULL, NULL),
(224, 69, 10, 2037, 170.21, 0, 0.991844, 'good', -0.0985763, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 3.714201450347901, \"elbow_drift_absmax\": 0.22950762510299683}', NULL, NULL, NULL),
(225, 72, 1, 4377, 0.804141, 0.0726823, 0.986813, 'bad', -0.507287, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(226, 72, 2, 2599, 1.4352, 0.0864629, 0.991234, 'bad', -0.459475, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(227, 72, 3, 616, 0.84936, 0.0982458, 0.989533, 'good', -0.498027, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 167.2865447998047, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(228, 72, 4, 751, 0.911635, 0.087797, 0.988378, 'good', -0.463161, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 166.0986785888672, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(229, 73, 1, 865, 1.34837, 0.0946827, 0.98621, 'good', -0.486382, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 167.3314208984375, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(230, 73, 2, 626, 0.597754, 0.07609, 0.988099, 'good', -0.411617, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 171.2187042236328, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(231, 73, 3, 733, 0.661733, 0.0760713, 0.989625, 'good', -0.385406, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 165.86241149902344, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(232, 73, 4, 733, 0.75664, 0.094338, 0.99076, 'good', -0.489544, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 168.25662231445312, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(233, 73, 5, 615, 0.362155, 0.108971, 0.988792, 'good', -0.506079, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [\"Range dropping - lighten weight or rest\"], \"label_ui\": \"warning\", \"elbow_min\": 167.52662658691406, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(234, 73, 6, 620, 0.539877, 0.0932376, 0.990903, 'good', -0.490615, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 166.6708526611328, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(235, 73, 7, 627, 0.401175, 0.0848932, 0.990646, 'good', -0.466573, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 168.265869140625, \"is_warning\": false, \"fatigue_index\": 6.026932117857816}', NULL, NULL, NULL),
(236, 73, 8, 748, 0.825451, 0.0940555, 0.99168, 'good', -0.489047, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 171.5061798095703, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(237, 73, 9, 2602, 0.880765, 0.0680944, 0.985994, 'good', -0.280133, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"elbow_min\": 164.79238891601562, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(238, 73, 10, 872, 0.552158, 0.0307542, 0.988402, 'good', -0.211309, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 170.39279174804688, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(239, 74, 1, 5634, 1.65146, 0.149515, 0.79211, 'good', -0.447623, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.25637415051460266}', NULL, NULL, NULL),
(240, 74, 2, 1999, 1.63775, 0.144145, 0.831809, 'good', -0.324346, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Brace core; reduce lean\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2938270568847656}', NULL, NULL, NULL),
(241, 74, 3, 3371, 1.52815, 0.108535, 0.819807, 'good', -0.142362, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22597643733024597}', NULL, NULL, NULL),
(242, 74, 4, 2231, 1.46313, 0.102493, 0.817317, 'good', -0.0342568, '2026-01-22 06:46:31', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2955237925052643}', NULL, NULL, NULL),
(243, 74, 5, 3617, 1.48158, 0.105824, 0.817427, 'good', -0.0925957, '2026-01-22 06:46:31', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22300106287002563}', NULL, NULL, NULL),
(244, 74, 6, 6251, 1.53447, 0.102671, 0.807987, 'good', -0.398739, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 5.872446298599243, \"wrist_stack_absmax\": 0.31776919960975647}', NULL, NULL, NULL),
(245, 74, 7, 2627, 1.57177, 0.0981488, 0.808911, 'good', -0.183053, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.19817015528678897}', NULL, NULL, NULL),
(246, 74, 8, 3154, 1.50054, 0.0964747, 0.827423, 'good', -0.0766547, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2189619243144989}', NULL, NULL, NULL),
(247, 74, 9, 2221, 1.51565, 0.115839, 0.827404, 'good', -0.131045, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.17899364233016968}', NULL, NULL, NULL),
(248, 74, 10, 2374, 1.54701, 0.104067, 0.826675, 'good', -0.150324, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2143746912479401}', NULL, NULL, NULL),
(249, 74, 11, 4494, 1.44058, 0.0858399, 0.881044, 'bad', -0.255284, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (right)\", \"Stack wrist over elbow (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.4356368482112885}', NULL, NULL, NULL),
(250, 82, 1, 7330, 176.826, 0, 0.849309, 'good', -0.670284, '2026-02-23 01:25:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.219472274184227}', NULL, NULL, NULL),
(251, 82, 2, 4739, 173.581, 0, 0.978586, 'good', -0.496949, '2026-02-23 01:25:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24083785712718964}', NULL, NULL, NULL);
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(252, 83, 1, 5673, 167.815, 0, 0.901062, 'good', -0.588556, '2026-02-23 01:25:26', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30558180809020996}', NULL, NULL, NULL),
(253, 83, 2, 7648, 171.063, 0, 0.9874, 'bad', -0.674983, '2026-02-23 01:25:26', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5635055303573608}', NULL, NULL, NULL),
(254, 83, 3, 1616, 169.686, 0, 0.981151, 'good', -0.081795, '2026-02-23 01:25:26', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2378017157316208}', NULL, NULL, NULL),
(255, 88, 1, 12696, 173.592, 0, 0.801111, 'good', -0.683567, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4151446521282196}', NULL, NULL, NULL),
(256, 88, 2, 3267, 170.789, 0, 0.975226, 'good', -0.249408, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19525563716888428}', NULL, NULL, NULL),
(257, 88, 3, 9726, 165.376, 0, 0.983436, 'good', -0.683189, '2026-02-23 01:50:44', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18687815964221952}', NULL, NULL, NULL),
(258, 88, 4, 2250, 161.533, 0, 0.98633, 'good', -0.0532135, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1819896250963211}', NULL, NULL, NULL),
(259, 89, 1, 7447, 177.223, 0, 0.958498, 'good', -0.672268, '2026-02-23 02:08:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22735695540905}', NULL, NULL, NULL),
(260, 89, 2, 3507, 173.811, 0, 0.983907, 'good', -0.309186, '2026-02-23 02:08:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19196100533008575}', NULL, NULL, NULL),
(261, 89, 3, 6747, 170.955, 0, 0.991585, 'good', -0.653478, '2026-02-23 02:08:06', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23993971943855288}', NULL, NULL, NULL),
(262, 91, 1, 15243, 178.818, 0, 0.85374, 'good', -0.683567, '2026-02-23 02:12:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.36857014894485474}', NULL, NULL, NULL),
(263, 93, 1, 4757, 176.39, 0, 0.81706, 'good', -0.50931, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2568829655647278}', NULL, NULL, NULL),
(264, 93, 2, 4376, 173.253, 0, 0.973301, 'good', -0.44459, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24614661931991577}', NULL, NULL, NULL),
(265, 93, 3, 4499, 169.67, 0, 0.981354, 'good', -0.448686, '2026-02-23 02:19:12', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19567608833312988}', NULL, NULL, NULL),
(266, 93, 4, 4004, 169.077, 0, 0.98191, 'good', -0.36541, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17789286375045776}', NULL, NULL, NULL),
(267, 93, 5, 3866, 172.205, 0, 0.983754, 'good', -0.358217, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22129936516284943}', NULL, NULL, NULL),
(268, 94, 1, 9282, 176.546, 0, 0.957582, 'good', -0.682866, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2642352283000946}', NULL, NULL, NULL),
(269, 94, 2, 6002, 178.983, 0, 0.990167, 'good', -0.626156, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1966916173696518}', NULL, NULL, NULL),
(270, 94, 3, 3271, 174.52, 0, 0.988285, 'good', -0.27761, '2026-02-23 02:54:41', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21627609431743625}', NULL, NULL, NULL),
(271, 94, 4, 3605, 170.497, 0, 0.983015, 'good', -0.304036, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2060348093509674}', NULL, NULL, NULL),
(272, 94, 5, 7263, 146.002, 0, 0.990683, 'bad', -0.668946, '2026-02-23 02:54:41', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(273, 94, 6, 1995, 166.001, 0, 0.983758, 'good', -0.0627858, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16211724281311035}', NULL, NULL, NULL),
(274, 94, 7, 2111, 161.739, 0, 0.982591, 'good', -0.0457419, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 9.402015209197998, \"elbow_drift_absmax\": 0.28438493609428406}', NULL, NULL, NULL),
(275, 94, 8, 4381, 114.806, 0, 0.988956, 'good', -0.538773, '2026-02-23 02:54:41', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 9.402015209197998, \"elbow_drift_absmax\": 0.49692168831825256}', NULL, NULL, NULL),
(276, 94, 9, 1255, 158.844, 0, 0.991311, 'good', -0.0306981, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.34431517124176025}', NULL, NULL, NULL),
(277, 94, 10, 1746, 160.506, 0, 0.989776, 'good', -0.0244893, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.3035406172275543}', NULL, NULL, NULL),
(278, 94, 11, 5636, 151.531, 0, 0.99375, 'bad', -0.592245, '2026-02-23 02:54:41', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.6685231328010559}', NULL, NULL, NULL),
(279, 94, 12, 2610, 162.917, 0, 0.990315, 'good', -0.138788, '2026-02-23 02:54:42', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.4959278106689453}', NULL, NULL, NULL),
(280, 95, 1, 6613, 173.878, 0, 0.957253, 'good', -0.650247, '2026-02-23 02:55:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2525123357772827}', NULL, NULL, NULL),
(281, 95, 2, 4879, 169.732, 0, 0.973491, 'good', -0.50373, '2026-02-23 02:55:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24321186542510984}', NULL, NULL, NULL),
(282, 96, 1, 3013, 115.224, 0, 0.890726, 'bad', -0.420286, '2026-02-23 02:56:41', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6166037917137146}', NULL, NULL, NULL),
(283, 96, 2, 4752, 174.054, 0, 0.898426, 'good', -0.499979, '2026-02-23 02:56:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22062930464744568}', NULL, NULL, NULL),
(284, 96, 3, 2772, 161.021, 0, 0.978324, 'good', -0.115193, '2026-02-23 02:56:41', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2515883147716522}', NULL, NULL, NULL),
(285, 97, 1, 9083, 178.215, 0, 0.992128, 'good', -0.682624, '2026-02-23 03:23:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30567362904548645}', NULL, NULL, NULL),
(286, 97, 2, 4242, 165.837, 0, 0.990883, 'good', -0.39367, '2026-02-23 03:23:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16841627657413483}', NULL, NULL, NULL),
(287, 97, 3, 3746, 165.619, 0, 0.991535, 'good', -0.304307, '2026-02-23 03:23:16', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23105518519878387}', NULL, NULL, NULL),
(288, 100, 1, 36097, 162.454, 0, 0.915521, 'good', -0.683567, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.37239834666252136}', NULL, NULL, NULL),
(289, 100, 2, 1618, 157.76, 0, 0.970247, 'good', -0.00926311, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.259771466255188}', NULL, NULL, NULL),
(290, 100, 3, 2000, 163.62, 0, 0.977642, 'good', -0.0486103, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2766464948654175}', NULL, NULL, NULL),
(291, 100, 4, 2643, 167.447, 0, 0.975089, 'good', -0.133979, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2535858750343323}', NULL, NULL, NULL),
(292, 100, 5, 5108, 130.288, 0, 0.975198, 'bad', -0.570328, '2026-02-24 04:11:02', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(293, 101, 1, 12369, 132.62, 0, 0.951293, 'bad', -0.683566, '2026-02-25 06:30:51', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5963998436927795}', NULL, NULL, NULL),
(294, 102, 1, 5191, 105.395, 0, 0.881037, 'bad', -0.631098, '2026-02-25 06:31:39', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6277127861976624}', NULL, NULL, NULL),
(295, 105, 1, 9942, 163.821, 0, 0.956337, 'bad', -0.683357, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6650781035423279}', NULL, NULL, NULL),
(296, 105, 2, 2128, 139.776, 0, 0.985956, 'bad', -0.12229, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5611814260482788}', NULL, NULL, NULL),
(297, 105, 3, 1612, 145.764, 0, 0.983111, 'good', -0.03875, '2026-02-25 06:59:08', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4325236678123474}', NULL, NULL, NULL),
(298, 105, 4, 2508, 140.494, 0, 0.983282, 'bad', -0.171293, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.622738778591156}', NULL, NULL, NULL),
(299, 105, 5, 2120, 114.235, 0, 0.985428, 'bad', -0.360895, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.545386552810669}', NULL, NULL, NULL),
(300, 105, 6, 3249, 161.957, 0, 0.970568, 'good', -0.199925, '2026-02-25 06:59:08', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2835617661476135}', NULL, NULL, NULL),
(301, 105, 7, 2129, 162.004, 0, 0.977302, 'good', -0.0512551, '2026-02-25 06:59:08', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.31445568799972534}', NULL, NULL, NULL),
(302, 106, 1, 8623, 172.905, 0, 0.887392, 'good', -0.681373, '2026-02-25 06:59:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3407405614852905}', NULL, NULL, NULL),
(303, 106, 2, 8256, 162.033, 0, 0.820584, 'good', -0.679256, '2026-02-25 06:59:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.411639541387558}', NULL, NULL, NULL),
(304, 107, 1, 4186, 169.308, 0, 0.914353, 'good', -0.398454, '2026-02-25 07:00:13', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26871246099472046}', NULL, NULL, NULL),
(305, 107, 2, 2509, 149.423, 0, 0.963573, 'good', -0.0664153, '2026-02-25 07:00:13', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3118056058883667}', NULL, NULL, NULL),
(306, 107, 3, 2149, 120.979, 0, 0.972141, 'good', -0.256174, '2026-02-25 07:00:13', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3222694993019104}', NULL, NULL, NULL),
(307, 107, 4, 3468, 111.601, 0, 0.978036, 'good', -0.463597, '2026-02-25 07:00:13', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3696337640285492}', NULL, NULL, NULL),
(308, 108, 1, 3900, 145.863, 0, 0.942544, 'good', -0.311991, '2026-02-25 07:00:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2385709136724472}', NULL, NULL, NULL),
(309, 108, 2, 3854, 170.926, 0, 0.973042, 'good', -0.368816, '2026-02-25 07:00:50', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4717813730239868}', NULL, NULL, NULL),
(310, 109, 1, 6243, 171.292, 0, 0.897105, 'good', -0.631867, '2026-02-25 07:01:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29736045002937317}', NULL, NULL, NULL),
(311, 109, 2, 1991, 163.686, 0, 0.967163, 'good', -0.047124, '2026-02-25 07:01:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25296565890312195}', NULL, NULL, NULL),
(312, 109, 3, 2003, 161.234, 0, 0.971421, 'good', -0.036519, '2026-02-25 07:01:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28804489970207214}', NULL, NULL, NULL),
(313, 109, 4, 2001, 161.26, 0, 0.974504, 'good', -0.0461581, '2026-02-25 07:01:30', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3661065101623535}', NULL, NULL, NULL),
(314, 110, 1, 8599, 131.298, 0, 0.659786, 'good', -0.681467, '2026-02-25 07:04:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4232212007045746}', NULL, NULL, NULL),
(315, 110, 2, 1620, 157.269, 0, 0.855635, 'good', -0.00848277, '2026-02-25 07:04:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2706197500228882}', NULL, NULL, NULL),
(316, 110, 3, 4376, 120.442, 0, 0.966276, 'good', -0.504341, '2026-02-25 07:04:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3990409672260285}', NULL, NULL, NULL),
(317, 111, 1, 3102, 95.7068, 0, 0.937906, 'good', -0.553933, '2026-02-25 07:04:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28688332438468933}', NULL, NULL, NULL),
(318, 122, 1, 7559, 163.503, 0, 0.628403, 'bad', -0.673938, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(319, 122, 2, 4027, 175.96, 0, 0.940132, 'good', -0.406413, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27928590774536133}', NULL, NULL, NULL),
(320, 122, 3, 1838, 171.528, 0, 0.974495, 'good', -0.103128, '2026-02-25 08:17:07', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2581453323364258}', NULL, NULL, NULL),
(321, 122, 4, 1784, 169.031, 0, 0.97488, 'good', -0.0780274, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2332076132297516}', NULL, NULL, NULL),
(322, 122, 5, 3824, 105.777, 0, 0.973407, 'good', -0.55831, '2026-02-25 08:17:07', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(323, 122, 6, 1567, 170.872, 0, 0.97218, 'good', -0.0959246, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.994919776916504, \"elbow_drift_absmax\": 0.2959102392196655}', NULL, NULL, NULL),
(324, 122, 7, 1729, 161.229, 0, 0.98711, 'good', -0.0315923, '2026-02-25 08:17:07', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 6.999331712722778, \"elbow_drift_absmax\": 0.33761367201805115}', NULL, NULL, NULL),
(325, 122, 8, 1662, 166.296, 0, 0.979493, 'good', -0.0561972, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.994919776916504, \"elbow_drift_absmax\": 0.2781488299369812}', NULL, NULL, NULL),
(326, 122, 9, 1719, 167.423, 0, 0.982289, 'good', -0.0692867, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.865630865097046, \"elbow_drift_absmax\": 0.31983283162117004}', NULL, NULL, NULL),
(327, 122, 10, 2316, 133.074, 0, 0.97059, 'bad', -0.229525, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 4.865630865097046, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(328, 122, 11, 1126, 160.246, 0, 0.973909, 'bad', -0.147506, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(329, 122, 12, 1356, 149.496, 0, 0.978374, 'good', -0.014682, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.32520750164985657}', NULL, NULL, NULL),
(330, 123, 1, 3852, 171.752, 0, 0.84085, 'good', -0.36855, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4398638010025024}', NULL, NULL, NULL),
(331, 123, 2, 5516, 165.247, 0, 0.903716, 'bad', -0.59112, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(332, 123, 3, 773, 110.867, 0, 0.869299, 'good', -0.400867, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.45704907178878784}', NULL, NULL, NULL),
(333, 123, 4, 2344, 146.647, 0, 0.84564, 'good', -0.0540795, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.312942773103714}', NULL, NULL, NULL),
(334, 123, 5, 1539, 117.257, 0, 0.949915, 'bad', -0.353445, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(335, 123, 6, 1134, 169.784, 0, 0.966385, 'good', -0.153897, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5672565698623657}', NULL, NULL, NULL),
(336, 123, 7, 6261, 159.085, 0, 0.959131, 'bad', -0.636269, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(337, 123, 8, 1417, 162.136, 0, 0.948582, 'bad', -0.14357, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(338, 123, 9, 977, 116.82, 0, 0.934542, 'good', -0.316203, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.37925946712493896}', NULL, NULL, NULL),
(339, 123, 10, 1426, 158.596, 0, 0.893019, 'good', -0.0156989, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27605122327804565}', NULL, NULL, NULL),
(340, 123, 11, 1563, 164.027, 0, 0.912379, 'good', -0.0400967, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.1508020056691084, \"elbow_drift_absmax\": 0.2731146514415741}', NULL, NULL, NULL),
(341, 124, 1, 531, 0.605555, 0.0801145, 0.97064, 'bad', -0.437635, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"bad\", \"elbow_min\": 157.0267333984375, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(342, 124, 2, 470, 0.535107, 0.0964553, 0.977018, 'good', -0.498248, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.1000518798828, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(343, 124, 3, 598, 0.687046, 0.0575895, 0.978269, 'good', -0.223343, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 153.0726776123047, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(344, 124, 4, 667, 0.914453, 0.0724339, 0.980223, 'good', -0.338594, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.4596405029297, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(345, 124, 5, 532, 0.393098, 0.0563612, 0.981178, 'good', -0.280875, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 148.66311645507812, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(346, 124, 6, 503, 0.653854, 0.0699501, 0.981275, 'good', -0.364894, '2026-02-25 08:19:10', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 149.05780029296875, \"is_warning\": false, \"fatigue_index\": 4.817852783203125}', NULL, NULL, NULL),
(347, 124, 7, 601, 0.46058, 0.0706138, 0.985129, 'good', -0.362787, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.48733520507812, \"is_warning\": false, \"fatigue_index\": 4.817852783203125}', NULL, NULL, NULL),
(348, 124, 8, 1290, 0.378682, 0.0250283, 0.985218, 'bad', -0.106103, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"bad\", \"elbow_min\": 157.12188720703125, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(349, 124, 9, 802, 0.565185, 0.0509835, 0.976889, 'good', -0.125016, '2026-02-25 08:19:10', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 148.2534637451172, \"is_warning\": false, \"fatigue_index\": 5.1414591780350305}', NULL, NULL, NULL),
(350, 124, 10, 684, 0.584688, 0.0395696, 0.992154, 'bad', -0.504985, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 10.92451581866003}', NULL, NULL, NULL),
(351, 124, 11, 664, 0.403937, 0.0426516, 0.992403, 'good', -0.181346, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 147.90794372558594, \"is_warning\": false, \"fatigue_index\": 6.893558849568526}', NULL, NULL, NULL),
(352, 124, 12, 531, 0.36717, 0.0566007, 0.979205, 'bad', -0.497319, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 35.28574311880371}', NULL, NULL, NULL),
(353, 124, 13, 582, 0.706987, 0.047908, 0.979868, 'good', -0.213336, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 135.661865234375, \"is_warning\": false, \"fatigue_index\": 26.178717972319333}', NULL, NULL, NULL),
(354, 124, 14, 734, 0.542538, 0.0968015, 0.959278, 'bad', -0.175433, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 30}', NULL, NULL, NULL),
(355, 124, 15, 546, 0.775278, 0.0775918, 0.986678, 'good', -0.429401, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 138.6455841064453, \"is_warning\": false, \"fatigue_index\": 20.892974853515625}', NULL, NULL, NULL),
(356, 125, 1, 26496, 177.758, 0, 0.856292, 'bad', -0.683567, '2026-02-25 08:21:25', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(357, 125, 2, 5816, 175.051, 0, 0.88128, 'good', -0.61013, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.33025094866752625}', NULL, NULL, NULL),
(358, 125, 3, 1595, 175.793, 0, 0.954043, 'good', -0.147226, '2026-02-25 08:21:25', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3165428042411804}', NULL, NULL, NULL),
(359, 125, 4, 1757, 175.477, 0, 0.974328, 'good', -0.151381, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.36876311898231506}', NULL, NULL, NULL),
(360, 125, 5, 1769, 172.663, 0, 0.967399, 'good', -0.126363, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.39054152369499207}', NULL, NULL, NULL),
(361, 125, 6, 1755, 175.451, 0, 0.976323, 'good', -0.141948, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.621460437774658, \"elbow_drift_absmax\": 0.27738726139068604}', NULL, NULL, NULL),
(362, 125, 7, 3221, 178.682, 0, 0.979298, 'good', -0.305804, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2650342881679535}', NULL, NULL, NULL),
(363, 125, 8, 2027, 172.88, 0, 0.961186, 'good', -0.122944, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20584411919116977}', NULL, NULL, NULL),
(364, 125, 9, 1956, 173.009, 0, 0.960689, 'good', -0.120763, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21045389771461487}', NULL, NULL, NULL),
(365, 125, 10, 1904, 170.751, 0, 0.961794, 'good', -0.102621, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3173067271709442}', NULL, NULL, NULL),
(366, 125, 11, 1809, 167.032, 0, 0.979277, 'good', -0.0650939, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2870665192604065}', NULL, NULL, NULL),
(367, 125, 12, 2249, 161.005, 0, 0.966052, 'good', -0.0533568, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2838613986968994}', NULL, NULL, NULL),
(368, 137, 1, 3469, 165.473, 0, 0.955987, 'good', -0.331172, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(369, 137, 2, 2721, 172.835, 0, 0.987192, 'good', -0.18604, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21801359951496124}', NULL, NULL, NULL),
(370, 137, 3, 6410, 175.146, 0, 0.993078, 'bad', -0.650663, '2026-02-27 08:09:52', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(371, 137, 4, 2316, 176.991, 0, 0.977335, 'good', -0.200194, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.40271785855293274}', NULL, NULL, NULL),
(372, 137, 5, 4186, 163.052, 0, 0.978069, 'good', -0.431952, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(373, 137, 6, 2116, 178.925, 0, 0.984417, 'good', -0.19335, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2621115744113922}', NULL, NULL, NULL),
(374, 137, 7, 2254, 174.288, 0, 0.979434, 'good', -0.153357, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26306602358818054}', NULL, NULL, NULL),
(375, 137, 8, 2382, 174.925, 0, 0.981504, 'good', -0.170054, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25356608629226685}', NULL, NULL, NULL),
(376, 137, 9, 1245, 162.749, 0, 0.978191, 'bad', -0.102078, '2026-02-27 08:09:52', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5672575235366821}', NULL, NULL, NULL),
(377, 137, 10, 1817, 166.902, 0, 0.989401, 'good', -0.0821925, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 1.4437758922576904, \"elbow_drift_absmax\": 0.4147493243217468}', NULL, NULL, NULL),
(378, 137, 11, 1848, 176.151, 0, 0.97541, 'good', -0.149573, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.4437758922576904, \"elbow_drift_absmax\": 0.20772908627986908}', NULL, NULL, NULL),
(379, 138, 1, 2733, 172.856, 0, 0.92761, 'good', -0.188271, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2397655099630356}', NULL, NULL, NULL),
(380, 138, 2, 1543, 175.43, 0, 0.9464, 'good', -0.142581, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30588048696517944}', NULL, NULL, NULL),
(381, 138, 3, 1558, 175.722, 0, 0.958642, 'good', -0.143051, '2026-02-27 08:13:56', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26834017038345337}', NULL, NULL, NULL),
(382, 138, 4, 1669, 174.568, 0, 0.971134, 'good', -0.131786, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2828606963157654}', NULL, NULL, NULL),
(383, 138, 5, 1551, 151.973, 0, 0.970555, 'good', -0.00485176, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30289432406425476}', NULL, NULL, NULL),
(384, 138, 6, 4499, 150.101, 0, 0.975853, 'good', -0.441386, '2026-02-27 08:13:56', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 2.4040353298187256, \"elbow_drift_absmax\": 0.541191816329956}', NULL, NULL, NULL),
(385, 138, 7, 1432, 161.781, 0, 0.95357, 'good', -0.029171, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.4040353298187256, \"elbow_drift_absmax\": 0.27182894945144653}', NULL, NULL, NULL),
(386, 138, 8, 1468, 157.205, 0, 0.955458, 'good', -0.0152804, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 5.2790772914886475, \"elbow_drift_absmax\": 0.3268530070781708}', NULL, NULL, NULL),
(387, 140, 1, 3556, 108.113, 0, 0.624337, 'good', -0.500554, '2026-02-27 08:34:18', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4212509095668793}', NULL, NULL, NULL),
(388, 143, 1, 3887, 157.787, 0, 0.883782, 'good', -0.308524, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2754361033439636}', NULL, NULL, NULL),
(389, 143, 2, 2035, 172.969, 0, 0.939194, 'good', -0.125798, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2651256024837494}', NULL, NULL, NULL),
(390, 143, 3, 3813, 175.606, 0, 0.963294, 'good', -0.370327, '2026-02-27 08:57:33', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2430647611618042}', NULL, NULL, NULL),
(391, 143, 4, 2719, 175.368, 0, 0.920403, 'good', -0.208738, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1987724006175995}', NULL, NULL, NULL),
(392, 143, 5, 3716, 148.575, 0, 0.980085, 'bad', -0.312946, '2026-02-27 08:57:33', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5664390921592712}', NULL, NULL, NULL),
(393, 143, 6, 5452, 171.442, 0, 0.98338, 'bad', -0.590542, '2026-02-27 08:57:33', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6545327305793762}', NULL, NULL, NULL),
(394, 143, 7, 1406, 168.036, 0, 0.977766, 'good', -0.075618, '2026-02-27 08:57:33', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 32.33842659932539, \"elbow_drift_absmax\": 0.315511018037796}', NULL, NULL, NULL),
(395, 143, 8, 2543, 123.263, 0, 0.965636, 'good', -0.329295, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(396, 143, 9, 1549, 174.466, 0, 0.948437, 'good', -0.128394, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 6.046249866485595, \"elbow_drift_absmax\": 0.23244167864322665}', NULL, NULL, NULL),
(397, 143, 10, 1749, 170.401, 0, 0.919912, 'good', -0.0895557, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23675964772701263}', NULL, NULL, NULL),
(398, 144, 1, 3067, 1.51034, 0.0754794, 0.795856, 'good', -0.0787911, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2531309127807617}', NULL, NULL, NULL),
(399, 144, 2, 1295, 1.34698, 0.0449209, 0.938679, 'bad', -0.068641, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.4130139648914337}', NULL, NULL, NULL),
(400, 144, 3, 1419, 1.47817, 0.0642373, 0.942321, 'bad', -0.0725218, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2646343410015106}', NULL, NULL, NULL),
(401, 144, 4, 1309, 1.27232, 0.0797182, 0.937216, 'bad', 0.0703985, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.3219814896583557}', NULL, NULL, NULL),
(402, 144, 5, 6194, 1.56832, 0.0883398, 0.844236, 'good', -0.386302, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.23147200047969815}', NULL, NULL, NULL),
(403, 144, 6, 1578, 1.31483, 0.0776672, 0.861547, 'good', 0.0831608, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2960854172706604}', NULL, NULL, NULL),
(404, 144, 7, 2294, 1.25563, 0.0793165, 0.861125, 'good', -0.0136809, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.12794499099254608}', NULL, NULL, NULL),
(405, 144, 8, 4868, 1.27273, 0.0806028, 0.884689, 'good', -0.199552, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 6.443175673484802, \"wrist_stack_absmax\": 0.2996082305908203}', NULL, NULL, NULL),
(406, 144, 9, 2075, 1.2174, 0.0701597, 0.868927, 'good', 0.0108835, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.1683754920959473}', NULL, NULL, NULL),
(407, 144, 10, 1771, 1.20948, 0.0626253, 0.859332, 'good', 0.000704383, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.16230255365371704}', NULL, NULL, NULL),
(408, 144, 11, 1963, 1.23435, 0.0682903, 0.862675, 'good', 0.0395291, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.18241989612579343}', NULL, NULL, NULL),
(409, 147, 1, 4001, 168.366, 0, 0.974706, 'bad', -0.399349, '2026-02-27 09:35:30', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5903091430664062}', NULL, NULL, NULL),
(410, 147, 2, 2371, 169.436, 0, 0.989525, 'good', -0.123, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.31472674012184143}', NULL, NULL, NULL),
(411, 147, 3, 2113, 175.016, 0, 0.995636, 'good', -0.149739, '2026-02-27 09:35:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22872349619865415}', NULL, NULL, NULL),
(412, 147, 4, 1952, 174.616, 0, 0.961211, 'good', -0.137664, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2462081164121628}', NULL, NULL, NULL),
(413, 147, 5, 3860, 172.237, 0, 0.882452, 'good', -0.357543, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2313503921031952}', NULL, NULL, NULL),
(414, 148, 1, 4588, 172.695, 0, 0.997224, 'good', -0.473265, '2026-02-27 10:00:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24979478120803833}', NULL, NULL, NULL),
(415, 149, 1, 5594, 170.025, 0, 0.996676, 'good', -0.583572, '2026-02-27 10:02:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21367192268371585}', NULL, NULL, NULL);
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(416, 149, 2, 3668, 172.502, 0, 0.998562, 'good', -0.327783, '2026-02-27 10:02:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25157630443573}', NULL, NULL, NULL),
(417, 149, 3, 4194, 173.696, 0, 0.99753, 'bad', -0.46767, '2026-02-27 10:02:21', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(418, 150, 1, 4132, 173.496, 0, 0.983432, 'good', -0.408151, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23481398820877075}', NULL, NULL, NULL),
(419, 150, 2, 3135, 172.301, 0, 0.997584, 'good', -0.24283, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29549112915992737}', NULL, NULL, NULL),
(420, 150, 3, 3417, 169.345, 0, 0.998387, 'bad', -0.311342, '2026-02-27 10:09:21', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5814729332923889}', NULL, NULL, NULL),
(421, 150, 4, 6137, 132.12, 0, 0.997637, 'good', -0.629451, '2026-02-27 10:09:21', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.40507909655570984}', NULL, NULL, NULL),
(422, 150, 5, 2364, 135.459, 0, 0.996612, 'good', -0.116431, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2281184196472168}', NULL, NULL, NULL),
(423, 150, 6, 2900, 142.959, 0, 0.997857, 'good', -0.161475, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 13.150556087493896, \"elbow_drift_absmax\": 0.4430599510669708}', NULL, NULL, NULL),
(424, 150, 7, 2316, 157.27, 0, 0.997781, 'good', -0.051322, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.654340744018555, \"elbow_drift_absmax\": 0.33427730202674866}', NULL, NULL, NULL),
(425, 150, 8, 3333, 164.97, 0, 0.997909, 'good', -0.229465, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.654340744018555, \"elbow_drift_absmax\": 0.29899200797080994}', NULL, NULL, NULL),
(426, 150, 9, 2500, 155.874, 0, 0.997261, 'good', -0.0612829, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.4201054573059082, \"elbow_drift_absmax\": 0.1701507568359375}', NULL, NULL, NULL),
(427, 150, 10, 2845, 165.926, 0, 0.997238, 'good', -0.150883, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18283167481422424}', NULL, NULL, NULL),
(428, 150, 11, 2888, 159.993, 0, 0.996431, 'good', -0.128805, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.15904006361961365}', NULL, NULL, NULL),
(429, 151, 1, 2067, 0.619269, 0.0964207, 0.94856, 'good', -0.527571, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2178017944097519}', NULL, NULL, NULL),
(430, 151, 2, 2180, 1.16148, 0.0814624, 0.95085, 'good', -0.0292886, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2041058987379074}', NULL, NULL, NULL),
(431, 151, 3, 1885, 1.3959, 0.0957202, 0.983171, 'good', 0.0264603, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.32852986454963684}', NULL, NULL, NULL),
(432, 151, 4, 7018, 1.38858, 0.0987147, 0.881958, 'good', -0.418627, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2862248122692108}', NULL, NULL, NULL),
(433, 151, 5, 2633, 1.29155, 0.0799699, 0.891148, 'good', 0.0787985, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 5.027639865875244, \"wrist_stack_absmax\": 0.25270721316337585}', NULL, NULL, NULL),
(434, 151, 6, 2485, 1.35579, 0.10208, 0.884622, 'good', 0.0372782, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.1893621981143951}', NULL, NULL, NULL),
(435, 151, 7, 2479, 1.36504, 0.0920455, 0.878867, 'good', 0.067686, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22989383339881897}', NULL, NULL, NULL),
(436, 151, 8, 2445, 1.35235, 0.0829638, 0.87142, 'good', 0.056809, '2026-02-27 10:10:56', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.16922394931316376}', NULL, NULL, NULL),
(437, 152, 1, 6784, 109.495, 0, 0.852966, 'bad', -0.671742, '2026-02-27 10:11:22', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(438, 153, 1, 4453, 163.77, 0, 0.978346, 'good', -0.424968, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28117799758911133}', NULL, NULL, NULL),
(439, 153, 2, 4168, 166.385, 0, 0.995961, 'good', -0.38277, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21965207159519196}', NULL, NULL, NULL),
(440, 153, 3, 3882, 164.445, 0, 0.9957, 'good', -0.324715, '2026-02-27 10:33:15', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23548826575279236}', NULL, NULL, NULL),
(441, 153, 4, 3216, 155.235, 0, 0.994549, 'good', -0.173818, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2360885590314865}', NULL, NULL, NULL),
(442, 153, 5, 3002, 161.573, 0, 0.994802, 'good', -0.152895, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2166147381067276}', NULL, NULL, NULL),
(443, 153, 6, 2825, 166.423, 0, 0.994188, 'good', -0.151558, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16433416306972504}', NULL, NULL, NULL),
(444, 153, 7, 2390, 174.084, 0, 0.99311, 'good', -0.161453, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1988685429096222}', NULL, NULL, NULL),
(445, 154, 1, 3427, 175.43, 0, 0.942915, 'good', -0.309307, '2026-02-27 10:35:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25658974051475525}', NULL, NULL, NULL),
(446, 154, 2, 2206, 177.399, 0, 0.945861, 'good', -0.185479, '2026-02-27 10:35:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3118451237678528}', NULL, NULL, NULL),
(447, 155, 1, 3176, 169.66, 0, 0.965604, 'good', -0.233828, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.33852216601371765}', NULL, NULL, NULL),
(448, 155, 2, 2882, 169.958, 0, 0.97772, 'good', -0.185315, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2571307420730591}', NULL, NULL, NULL),
(449, 155, 3, 2598, 174.588, 0, 0.971883, 'good', -0.18779, '2026-02-27 10:39:45', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22988787293434143}', NULL, NULL, NULL),
(450, 155, 4, 2736, 171.82, 0, 0.974383, 'good', -0.179114, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20887725055217743}', NULL, NULL, NULL),
(451, 155, 5, 3957, 173.532, 0, 0.977416, 'bad', -0.42291, '2026-02-27 10:39:45', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6303626894950867}', NULL, NULL, NULL),
(452, 157, 1, 4250, 154.563, 0, 0.985876, 'good', -0.417941, '2026-02-27 10:46:47', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.642208993434906}', NULL, NULL, NULL),
(453, 157, 2, 3773, 154.847, 0, 0.995681, 'bad', -0.319834, '2026-02-27 10:46:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5570183396339417}', NULL, NULL, NULL),
(454, 157, 3, 3317, 152.393, 0, 0.991382, 'good', -0.225675, '2026-02-27 10:46:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5057030320167542}', NULL, NULL, NULL),
(455, 157, 4, 4231, 151.039, 0, 0.992747, 'good', -0.372439, '2026-02-27 10:46:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3248208463191986}', NULL, NULL, NULL),
(456, 158, 1, 1658, 107.241, 0, 0.981385, 'bad', -0.432024, '2026-02-27 10:47:08', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5837083458900452}', NULL, NULL, NULL),
(457, 159, 1, 3858, 140.899, 0, 0.977119, 'good', -0.332907, '2026-02-27 10:47:35', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4302944242954254}', NULL, NULL, NULL),
(458, 160, 1, 1702, 109.258, 0, 0.938803, 'good', -0.384629, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3510110378265381}', NULL, NULL, NULL),
(459, 160, 2, 4432, 158.899, 0, 0.956258, 'good', -0.414751, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.34606680274009705}', NULL, NULL, NULL),
(460, 160, 3, 2918, 152.011, 0, 0.95906, 'good', -0.161511, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5168856382369995}', NULL, NULL, NULL),
(461, 160, 4, 2283, 144.101, 0, 0.957758, 'good', -0.0919314, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4931391775608063}', NULL, NULL, NULL),
(462, 161, 1, 2461, 173.922, 0, 0.99754, 'good', -0.166707, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19187913835048676}', NULL, NULL, NULL),
(463, 161, 2, 2284, 173.885, 0, 0.99759, 'good', -0.150313, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2155902236700058}', NULL, NULL, NULL),
(464, 161, 3, 2332, 172.401, 0, 0.998114, 'good', -0.14015, '2026-02-27 11:44:57', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2184824645519257}', NULL, NULL, NULL),
(465, 161, 4, 2215, 147.314, 0, 0.998022, 'bad', -0.148489, '2026-02-27 11:44:57', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(466, 161, 5, 2350, 169.107, 0, 0.998044, 'good', -0.134386, '2026-02-27 11:44:57', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4241201877593994}', NULL, NULL, NULL),
(467, 161, 6, 2201, 170.787, 0, 0.997117, 'good', -0.120642, '2026-02-27 11:44:57', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 24.67652678489685, \"elbow_drift_absmax\": 0.3224336504936218}', NULL, NULL, NULL),
(468, 161, 7, 2317, 139.536, 0, 0.998064, 'bad', -0.141395, '2026-02-27 11:44:57', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 24.67652678489685, \"elbow_drift_absmax\": 0.5712682604789734}', NULL, NULL, NULL),
(469, 161, 8, 2303, 175.078, 0, 0.997947, 'good', -0.164844, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 12.474142313003538, \"elbow_drift_absmax\": 0.25567862391471863}', NULL, NULL, NULL),
(470, 161, 9, 1946, 174.642, 0, 0.997809, 'good', -0.137219, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.463539123535156, \"elbow_drift_absmax\": 0.229164257645607}', NULL, NULL, NULL),
(471, 161, 10, 2083, 174.822, 0, 0.997479, 'good', -0.148068, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.463539123535156, \"elbow_drift_absmax\": 0.27898499369621277}', NULL, NULL, NULL),
(472, 162, 1, 4398, 168.789, 0, 0.909749, 'good', -0.431437, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2817760705947876}', NULL, NULL, NULL),
(473, 162, 2, 3003, 164.296, 0, 0.911796, 'good', -0.169269, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29155203700065613}', NULL, NULL, NULL),
(474, 162, 3, 2434, 155.424, 0, 0.924883, 'good', -0.0677116, '2026-03-18 09:43:49', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3836756050586701}', NULL, NULL, NULL),
(475, 162, 4, 7148, 168.009, 0, 0.959807, 'good', -0.665317, '2026-03-18 09:43:49', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.45750582218170166}', NULL, NULL, NULL),
(476, 162, 5, 2450, 165.765, 0, 0.91636, 'good', -0.0989048, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 11.05482816696167, \"elbow_drift_absmax\": 0.2463913261890411}', NULL, NULL, NULL),
(477, 163, 1, 5934, 174.016, 0, 0.895424, 'good', -0.616653, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.32780972123146057}', NULL, NULL, NULL),
(478, 163, 2, 2955, 161.959, 0, 0.966549, 'good', -0.159188, '2026-03-18 09:52:02', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.37287232279777527}', NULL, NULL, NULL),
(479, 163, 3, 2895, 164.294, 0, 0.956196, 'good', -0.152178, '2026-03-18 09:52:02', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29056286811828613}', NULL, NULL, NULL),
(480, 163, 4, 2602, 169.531, 0, 0.959093, 'good', -0.147929, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3039013743400574}', NULL, NULL, NULL),
(481, 163, 5, 2543, 162.966, 0, 0.959537, 'good', -0.092381, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22876808047294617}', NULL, NULL, NULL),
(482, 163, 6, 3302, 171.314, 0, 0.950283, 'bad', -0.332982, '2026-03-18 09:52:02', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6893754601478577}', NULL, NULL, NULL),
(483, 163, 7, 2265, 162.481, 0, 0.946408, 'good', -0.0687581, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.855434894561768, \"elbow_drift_absmax\": 0.34436333179473877}', NULL, NULL, NULL),
(484, 163, 8, 1684, 165.21, 0, 0.94937, 'good', -0.059223, '2026-03-18 09:52:02', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 7.895636558532715, \"elbow_drift_absmax\": 0.3696983456611634}', NULL, NULL, NULL),
(485, 163, 9, 2432, 172.955, 0, 0.955967, 'good', -0.154855, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.855434894561768, \"elbow_drift_absmax\": 0.2263495028018951}', NULL, NULL, NULL),
(486, 170, 1, 3434, 170.192, 0, 0.99443, 'good', -0.273153, '2026-04-01 06:05:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19102582335472107}', NULL, NULL, NULL),
(487, 170, 2, 2638, 163.009, 0, 0.991371, 'good', -0.105087, '2026-04-01 06:05:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16805943846702576}', NULL, NULL, NULL),
(488, 170, 3, 2669, 168.451, 0, 0.986141, 'good', -0.143927, '2026-04-01 06:05:06', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17469161748886108}', NULL, NULL, NULL),
(489, 172, 1, 1030, 0.524995, 0.130173, 0.923894, 'good', -0.507262, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 158.16671752929688, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(490, 172, 2, 798, 0.544412, 0.115883, 0.931526, 'good', -0.506815, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 160.5016632080078, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(491, 172, 3, 1118, 0.755417, 0.136882, 0.93025, 'good', -0.507284, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 155.9709930419922, \"is_warning\": true, \"fatigue_index\": 0}', NULL, NULL, NULL),
(492, 172, 4, 981, 0.751395, 0.133373, 0.943585, 'good', -0.507289, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 162.0985107421875, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(493, 172, 5, 986, 0.639396, 0.119892, 0.947815, 'good', -0.507007, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 157.4168701171875, \"is_warning\": false, \"fatigue_index\": 0.8998168945312499}', NULL, NULL, NULL),
(494, 172, 6, 961, 0.862584, 0.121655, 0.938403, 'good', -0.507088, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 158.78216552734375, \"is_warning\": false, \"fatigue_index\": 0}', NULL, NULL, NULL),
(495, 173, 1, 3747, 175.193, 0, 0.970189, 'good', -0.378966, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.49242761731147766}', NULL, NULL, NULL),
(496, 173, 2, 3478, 165.466, 0, 0.966335, 'good', -0.254505, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2174871414899826}', NULL, NULL, NULL),
(497, 173, 3, 3251, 163.353, 0, 0.974803, 'good', -0.203621, '2026-04-01 06:12:28', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19083000719547272}', NULL, NULL, NULL),
(498, 173, 4, 2936, 165.032, 0, 0.973761, 'good', -0.159964, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16156578063964844}', NULL, NULL, NULL),
(499, 173, 5, 3077, 162.012, 0, 0.971843, 'good', -0.168022, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1587398499250412}', NULL, NULL, NULL),
(500, 173, 6, 3655, 164.5, 0, 0.979367, 'good', -0.282569, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17707963287830353}', NULL, NULL, NULL),
(501, 173, 7, 3902, 165.839, 0, 0.978732, 'good', -0.333331, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18880023062229156}', NULL, NULL, NULL),
(502, 173, 8, 3481, 162.108, 0, 0.973304, 'good', -0.241044, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1616682410240173}', NULL, NULL, NULL),
(503, 173, 9, 2828, 165.78, 0, 0.969085, 'good', -0.148695, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.14528551697731018}', NULL, NULL, NULL),
(504, 173, 10, 3371, 170.779, 0, 0.979955, 'good', -0.266403, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1875794231891632}', NULL, NULL, NULL),
(505, 174, 1, 3190, 171.251, 0, 0.994299, 'good', -0.240323, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20234476029872897}', NULL, NULL, NULL),
(506, 174, 2, 2785, 172.172, 0, 0.995181, 'good', -0.188763, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1719403862953186}', NULL, NULL, NULL),
(507, 174, 3, 2866, 170.813, 0, 0.994559, 'good', -0.188896, '2026-04-01 06:28:12', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16317218542099}', NULL, NULL, NULL),
(508, 174, 4, 2745, 171.873, 0, 0.99409, 'good', -0.182619, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1321955919265747}', NULL, NULL, NULL),
(509, 174, 5, 2935, 167.251, 0, 0.991924, 'good', -0.174549, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.13630768656730652}', NULL, NULL, NULL),
(510, 174, 6, 2785, 170.051, 0, 0.98998, 'good', -0.173245, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.13161221146583557}', NULL, NULL, NULL),
(511, 174, 7, 3066, 162.759, 0, 0.993996, 'good', -0.181167, '2026-04-01 06:28:12', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3761248290538788}', NULL, NULL, NULL),
(512, 174, 8, 2258, 150.247, 0, 0.991273, 'good', -0.0617287, '2026-04-01 06:28:12', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 25.554317235946655, \"elbow_drift_absmax\": 0.4489337205886841}', NULL, NULL, NULL),
(513, 174, 9, 2701, 154.688, 0, 0.991958, 'bad', -0.192621, '2026-04-01 06:28:12', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}', NULL, NULL, NULL),
(514, 174, 10, 2385, 145.393, 0, 0.990409, 'bad', -0.162061, '2026-04-01 06:28:12', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.6858193278312683}', NULL, NULL, NULL),
(515, 175, 1, 14139, 154.521, 0, 0.922626, 'good', -0.683567, '2026-04-06 07:59:39', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4008048474788666}', NULL, NULL, NULL),
(516, 175, 2, 5278, 157.946, 0, 0.90967, 'good', -0.539957, '2026-04-06 07:59:39', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3860962986946106}', NULL, NULL, NULL),
(517, 176, 1, 10428, 166.095, 0, 0.983582, 'good', -0.683473, '2026-04-06 08:02:55', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3811350166797638}', NULL, NULL, NULL),
(518, 176, 2, 5674, 170.363, 0, 0.970606, 'bad', -0.593133, '2026-04-06 08:02:55', '{\"reasons\": [\"Elbow drifting a lot (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.356058806180954}', NULL, NULL, NULL),
(519, 176, 3, 9428, 170.26, 0, 0.955175, 'good', -0.682968, '2026-04-06 08:02:55', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.31749796867370605}', NULL, NULL, NULL),
(520, 177, 1, 6149, 167.883, 0, 0.896741, 'good', -0.623349, '2026-04-06 08:07:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25917306542396545}', NULL, NULL, NULL),
(521, 177, 2, 4752, 169.503, 0, 0.92209, 'good', -0.486055, '2026-04-06 08:07:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2593960464000702}', NULL, NULL, NULL),
(522, 177, 3, 4957, 170.778, 0, 0.906133, 'good', -0.516396, '2026-04-06 08:07:16', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2321683019399643}', NULL, NULL, NULL),
(523, 177, 4, 5444, 176.217, 0, 0.901255, 'good', -0.581357, '2026-04-06 08:07:16', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20079654455184937}', NULL, NULL, NULL),
(524, 178, 1, 5488, 174.909, 0, 0.923323, 'good', -0.586673, '2026-04-06 08:09:17', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4125021696090698}', NULL, NULL, NULL),
(525, 178, 2, 31966, 174.5, 0, 0.623431, 'good', -0.683567, '2026-04-06 08:09:17', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4272039234638214}', NULL, NULL, NULL),
(526, 178, 3, 5476, 169.707, 0, 0.935274, 'good', -0.573729, '2026-04-06 08:09:17', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.32548144459724426}', NULL, NULL, NULL),
(527, 179, 1, 5047, 167.919, 0, 0.882149, 'good', -0.520769, '2026-04-06 08:12:05', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2106032371520996}', NULL, NULL, NULL),
(528, 179, 2, 4570, 166.067, 0, 0.913073, 'good', -0.448793, '2026-04-06 08:12:05', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2386593222618103}', NULL, NULL, NULL),
(529, 179, 3, 4365, 171.176, 0, 0.902646, 'good', -0.434805, '2026-04-06 08:12:05', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26592138409614563}', NULL, NULL, NULL),
(530, 180, 1, 5321, 171.216, 0, 0.92394, 'good', -0.55943, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24179665744304657}', NULL, NULL, NULL),
(531, 180, 2, 4052, 169.449, 0, 0.956595, 'good', -0.376045, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2500564754009247}', NULL, NULL, NULL),
(532, 180, 3, 3214, 166.368, 0, 0.952426, 'good', -0.214125, '2026-04-06 08:27:59', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26326099038124084}', NULL, NULL, NULL),
(533, 180, 4, 3787, 167.223, 0, 0.954322, 'good', -0.320405, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27276483178138733}', NULL, NULL, NULL),
(534, 180, 5, 4435, 170.356, 0, 0.9496, 'good', -0.442359, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.13904929161071777, \"elbow_drift_absmax\": 0.2644197344779968}', NULL, NULL, NULL),
(535, 180, 6, 4253, 173.575, 0, 0.960318, 'good', -0.427305, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.13904929161071777, \"elbow_drift_absmax\": 0.23830363154411316}', NULL, NULL, NULL),
(536, 180, 7, 6779, 174.148, 0, 0.974555, 'good', -0.656119, '2026-04-06 08:27:59', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23260560631752017}', NULL, NULL, NULL),
(537, 180, 8, 5299, 175.114, 0, 0.972678, 'good', -0.565514, '2026-04-06 08:27:59', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.1536620057130786, \"elbow_drift_absmax\": 0.2279813438653946}', NULL, NULL, NULL),
(538, 180, 9, 4485, 165.299, 0, 0.966666, 'good', -0.433388, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.1536620057130786, \"elbow_drift_absmax\": 0.24932678043842316}', NULL, NULL, NULL),
(539, 180, 10, 3709, 166.996, 0, 0.940984, 'good', -0.30365, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21793800592422485}', NULL, NULL, NULL),
(540, 180, 11, 3703, 169.024, 0, 0.964751, 'good', -0.31297, '2026-04-06 08:27:59', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22097575664520264}', NULL, NULL, NULL),
(541, 181, 1, 13824, 171.795, 0, 0.921634, 'good', -0.683567, '2026-04-08 03:32:01', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24258626997470856}', NULL, NULL, NULL),
(542, 181, 2, 5753, 172.02, 0, 0.906981, 'good', -0.599839, '2026-04-08 03:32:01', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1634855568408966}', NULL, NULL, NULL),
(543, 181, 3, 5805, 147.98, 0, 0.902986, 'good', -0.605575, '2026-04-08 03:32:01', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6573622226715088}', NULL, NULL, NULL),
(544, 182, 1, 5348, 175.576, 0, 0.966399, 'good', -0.571207, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21346531808376312}', NULL, NULL, NULL),
(545, 182, 2, 3817, 166.313, 0, 0.932634, 'good', -0.320332, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.15650632977485657}', NULL, NULL, NULL),
(546, 182, 3, 4061, 168.532, 0, 0.923108, 'good', -0.372713, '2026-04-08 09:36:33', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1812828928232193}', NULL, NULL, NULL),
(547, 182, 4, 3849, 166.41, 0, 0.925417, 'good', -0.326111, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19908466935157776}', NULL, NULL, NULL),
(548, 182, 5, 3566, 171.312, 0, 0.91689, 'good', -0.302541, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2212261408567429}', NULL, NULL, NULL),
(549, 182, 6, 3829, 170.828, 0, 0.907271, 'good', -0.344416, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.656976580619812, \"elbow_drift_absmax\": 0.22666218876838684}', NULL, NULL, NULL),
(550, 182, 7, 7332, 169.289, 0, 0.934105, 'good', -0.669689, '2026-04-08 09:36:33', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 3.3093023300170894, \"elbow_drift_absmax\": 0.5029732584953308}', NULL, NULL, NULL),
(551, 182, 8, 4276, 140.072, 0, 0.929561, 'good', -0.41606, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.4988220036029816}', NULL, NULL, NULL),
(552, 182, 9, 3792, 173.441, 0, 0.931993, 'good', -0.353712, '2026-04-08 09:36:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.2453694045543671}', NULL, NULL, NULL),
(576, 190, 1, 3291, 174.983, 0, 0.984668, 'good', -0.286895, '2026-04-09 12:52:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29162701964378357}', 0, 'none', 'stable'),
(577, 190, 2, 2755, 175.464, 0, 0.985131, 'good', -0.214887, '2026-04-09 12:52:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24855762720108032}', 0, 'none', 'stable'),
(578, 190, 3, 2859, 173.667, 0, 0.984465, 'good', -0.211879, '2026-04-09 12:52:49', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24692440032958984}', 0, 'none', 'stable'),
(579, 190, 4, 2900, 175.958, 0, 0.985795, 'good', -0.242433, '2026-04-09 12:52:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3252395987510681}', 0, 'none', 'stable'),
(580, 190, 5, 2892, 173.787, 0, 0.983017, 'good', -0.223766, '2026-04-09 12:52:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.668413764900632, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.34005969762802124}', 4.66841, 'none', 'stable'),
(581, 191, 1, 17524, 115.357, 0, 0.551818, 'good', -0.683567, '2026-04-09 13:10:00', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4509267807006836}', 0, 'none', 'stable'),
(582, 191, 2, 24922, 106.249, 0, 0.544854, 'good', -0.683567, '2026-04-09 13:10:00', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4282559156417846}', 0, 'none', 'stable'),
(583, 192, 1, 2984, 177.454, 0, 0.985388, 'good', -0.262709, '2026-04-09 14:11:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2610276937484741}', 0, 'none', 'stable'),
(584, 192, 2, 2433, 173.537, 0, 0.993139, 'good', -0.1612, '2026-04-09 14:11:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2509121000766754}', 0, 'none', 'stable'),
(585, 192, 3, 2611, 177.133, 0, 0.992729, 'good', -0.221345, '2026-04-09 14:11:25', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3445570766925812}', 0, 'none', 'stable'),
(586, 192, 4, 2458, 174.548, 0, 0.992347, 'good', -0.18293, '2026-04-09 14:11:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.36452150344848633}', 0, 'none', 'stable'),
(587, 192, 5, 2335, 175.504, 0, 0.991522, 'good', -0.173574, '2026-04-09 14:11:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 7.914817995495267, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.28757038712501526}', 7.91482, 'none', 'stable'),
(588, 192, 6, 4912, 168.467, 0, 0.989672, 'good', -0.50585, '2026-04-09 14:11:25', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.1911653412712945, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2889467775821686}', 0.191165, 'none', 'stable'),
(589, 192, 7, 4959, 171.194, 0, 0.990077, 'good', -0.518392, '2026-04-09 14:11:25', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 35, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.26708513498306274}', 35, 'low', 'stable'),
(590, 192, 8, 25611, 113.924, 0, 0.594865, 'good', -0.683567, '2026-04-09 14:11:25', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 35.191165341271294, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.42303693294525146}', 35.1912, 'low', 'sharply_rising'),
(591, 193, 1, 6740, 170.241, 0, 0.94792, 'good', -0.6529, '2026-04-09 16:30:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24052250385284424}', 0, 'none', 'stable'),
(592, 193, 2, 6162, 172.076, 0, 0.911911, 'good', -0.627587, '2026-04-09 16:30:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2345561981201172}', 0, 'none', 'stable'),
(593, 193, 3, 5805, 174.724, 0, 0.903765, 'good', -0.608504, '2026-04-09 16:30:58', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.30799490213394165}', 0, 'none', 'stable'),
(594, 193, 4, 5871, 176.11, 0, 0.889419, 'good', -0.61456, '2026-04-09 16:30:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.27493301033973694}', 0, 'none', 'stable');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(595, 193, 5, 6584, 169.739, 0, 0.859165, 'good', -0.646733, '2026-04-09 16:30:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.384757002194722, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.25776275992393494}', 2.38476, 'none', 'stable'),
(596, 194, 1, 5023, 153.684, 0, 0.949658, 'good', -0.534018, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(597, 194, 2, 5881, 158.053, 0, 0.971697, 'good', -0.598796, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3317064940929413}', 0, 'none', 'stable'),
(598, 194, 3, 4032, 159.041, 0, 0.973956, 'good', -0.34449, '2026-04-09 16:34:20', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3642129302024842}', 0, 'none', 'stable'),
(599, 194, 4, 5905, 164.215, 0, 0.979154, 'good', -0.603861, '2026-04-09 16:34:20', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29606837034225464}', 0, 'none', 'stable'),
(600, 194, 5, 7616, 156.848, 0, 0.976, 'good', -0.672121, '2026-04-09 16:34:20', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.28700530529022217}', 0, 'none', 'stable'),
(601, 194, 6, 6357, 158.911, 0, 0.972812, 'good', -0.631029, '2026-04-09 16:34:20', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.973783039863185, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2694622874259949}', 1.97378, 'none', 'stable'),
(602, 194, 7, 5566, 162.824, 0, 0.97881, 'good', -0.572691, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.973783039863185, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.288038969039917}', 1.97378, 'none', 'stable'),
(603, 194, 8, 4701, 161.33, 0, 0.982426, 'good', -0.459543, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2714749574661255}', 0, 'none', 'stable'),
(604, 194, 9, 5136, 159.513, 0, 0.973899, 'good', -0.520936, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.31650760769844055}', 0, 'none', 'stable'),
(605, 194, 10, 4324, 158.724, 0, 0.983178, 'good', -0.390485, '2026-04-09 16:34:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2168295532464981}', 0, 'none', 'stable'),
(606, 195, 1, 3184, 174.459, 0, 0.991219, 'good', -0.263952, '2026-04-11 01:50:32', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.17800118029117584}', 0, 'none', 'stable'),
(607, 195, 2, 2677, 171.295, 0, 0.987341, 'good', -0.168374, '2026-04-11 01:50:32', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.1496017873287201}', 0, 'none', 'stable'),
(608, 195, 3, 2967, 171.065, 0, 0.99331, 'good', -0.214357, '2026-04-11 01:50:32', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3590087592601776}', 0, 'none', 'stable'),
(609, 195, 4, 2337, 114.123, 0, 0.994611, 'bad', -0.401958, '2026-04-11 01:50:32', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(610, 195, 5, 2666, 170.604, 0, 0.990574, 'good', -0.160592, '2026-04-11 01:50:32', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.23681865632534027}', 0, 'none', 'stable'),
(611, 196, 1, 54121, 167.28, 0, 0.769652, 'good', -0.683567, '2026-04-13 02:18:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3154284656047821}', 0, 'none', 'stable'),
(612, 196, 2, 2700, 168.834, 0, 0.967722, 'good', -0.152414, '2026-04-13 02:18:20', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2703278064727783}', 0, 'none', 'stable'),
(613, 196, 3, 2738, 153.031, 0, 0.970341, 'bad', -0.180384, '2026-04-13 02:18:20', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.6581981182098389}', 0, 'none', 'stable'),
(614, 196, 4, 5367, 156.435, 0, 0.979103, 'bad', -0.571262, '2026-04-13 02:18:20', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(615, 196, 5, 3130, 157.961, 0, 0.975353, 'bad', -0.213775, '2026-04-13 02:18:20', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5608166456222534}', 0, 'none', 'stable'),
(616, 197, 1, 2332, 1.07521, 0.0838689, 0.910837, 'good', -0.131225, '2026-04-13 02:23:06', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.3161717653274536}', 0, 'none', 'stable'),
(617, 197, 2, 2069, 1.11999, 0.0994476, 0.906807, 'good', -0.0766606, '2026-04-13 02:23:06', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.3465506136417389}', 0, 'none', 'stable'),
(618, 197, 3, 1875, 1.09081, 0.103722, 0.900086, 'good', -0.217358, '2026-04-13 02:23:06', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.1299498975276947}', 0, 'none', 'stable'),
(619, 197, 4, 1765, 1.03663, 0.0969172, 0.905406, 'good', -0.297114, '2026-04-13 02:23:06', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.1067601814866066}', 0, 'none', 'stable'),
(620, 197, 5, 2739, 1.26665, 0.109692, 0.895671, 'bad', -0.226698, '2026-04-13 02:23:06', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (right)\", \"Stack wrists over elbows (both)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.7353443503379822}', 0, 'none', 'stable'),
(621, 198, 1, 1102, 0.771472, 0.0803864, 0.952883, 'good', -0.384971, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 161.45777893066406, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(622, 198, 2, 889, 0.504146, 0.0725642, 0.95501, 'good', -0.331073, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 159.16346740722656, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(623, 198, 3, 1075, 0.552187, 0.0721242, 0.954125, 'good', -0.296369, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 158.8789520263672, \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(624, 198, 4, 819, 0.475329, 0.0556463, 0.947419, 'good', -0.170678, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 157.7621307373047, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(625, 198, 5, 829, 0.331301, 0.0542957, 0.952643, 'good', -0.187642, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 156.33648681640625, \"is_warning\": false, \"fatigue_index\": 1.340185546875, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 1.34019, 'none', 'stable'),
(626, 198, 6, 1134, 0.741084, 0.0778673, 0.990087, 'bad', -0.313621, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 3.0509582519531246, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 3.05096, 'none', 'stable'),
(627, 198, 7, 839, 0.422638, 0.0742955, 0.99378, 'bad', -0.406149, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"unsafe\", \"elbow_min\": 69.34074401855469, \"is_warning\": false, \"fatigue_index\": 30, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\"}', 30, 'low', 'stable'),
(628, 198, 8, 1402, 0.633713, 0.0876742, 0.988875, 'bad', -0.185431, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Early fatigue signs - keep the raise controlled\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 30.502349739369645, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\"}', 30.5023, 'low', 'sharply_rising'),
(629, 198, 9, 1230, 0.888435, 0.0872467, 0.984423, 'bad', -0.146751, '2026-04-13 02:24:35', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Early fatigue signs - keep the raise controlled\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 32.66157347964614, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\"}', 32.6616, 'low', 'sharply_rising'),
(630, 200, 1, 4007, 167.086, 0, 0.996728, 'good', -0.363251, '2026-04-15 13:40:47', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.34923219680786133}', 0, 'none', 'stable'),
(631, 200, 2, 3858, 165.878, 0, 0.994884, 'good', -0.325444, '2026-04-15 13:40:47', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.1919848918914795}', 0, 'none', 'stable'),
(632, 200, 3, 4981, 172.027, 0, 0.933924, 'good', -0.533189, '2026-04-15 13:40:47', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4818412661552429}', 0, 'none', 'stable'),
(633, 201, 1, 2946, 2.12646, 0.130402, 0.995384, 'bad', -0.530347, '2026-04-15 13:43:59', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Brace core; reduce lean\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.4151842892169952}', 0, 'none', 'stable'),
(634, 201, 2, 4133, 2.39289, 0.456049, 0.994684, 'bad', -0.530693, '2026-04-15 13:43:59', '{\"arm\": \"L\", \"reasons\": [\"Avoid leaning / back arch\", \"Stack wrist over elbow (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 4.135560989379883}', 0, 'none', 'stable'),
(635, 201, 3, 3642, 1.3877, 0.0523342, 0.99827, 'good', 0.00399535, '2026-04-15 13:43:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.16427069902420044}', 0, 'none', 'stable'),
(636, 201, 4, 2988, 1.48934, 0.0688943, 0.998597, 'good', -0.0315443, '2026-04-15 13:43:59', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.18739895522594452}', 0, 'none', 'stable'),
(637, 201, 5, 2657, 1.50589, 0.0871888, 0.997975, 'good', -0.0897557, '2026-04-15 13:43:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.12121275067329408}', 0, 'none', 'stable'),
(638, 202, 1, 4519, 147.085, 0, 0.730119, 'good', -0.467036, '2026-04-16 09:09:09', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.6760808825492859}', 0, 'none', 'stable'),
(639, 202, 2, 5481, 148.514, 0, 0.703539, 'good', -0.570596, '2026-04-16 09:09:09', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5485669374465942}', 0, 'none', 'stable'),
(640, 202, 3, 6042, 146.26, 0, 0.755037, 'good', -0.617822, '2026-04-16 09:09:09', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5528244972229004}', 0, 'none', 'stable'),
(641, 202, 4, 4875, 150.98, 0, 0.619517, 'bad', -0.500395, '2026-04-16 09:09:09', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5719839930534363}', 0, 'none', 'stable'),
(642, 202, 5, 9388, 173.434, 0, 0.641034, 'good', -0.683032, '2026-04-16 09:09:09', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5990327000617981}', 0, 'none', 'stable'),
(643, 202, 6, 6093, 173.614, 0, 0.733171, 'good', -0.626279, '2026-04-16 09:09:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.661041087574429, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3496372699737549}', 2.66104, 'none', 'stable'),
(644, 202, 7, 4511, 175.754, 0, 0.693763, 'good', -0.477445, '2026-04-16 09:09:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.33108076453208923}', 0, 'none', 'stable'),
(645, 203, 1, 8502, 155.294, 0, 0.980004, 'bad', -0.68101, '2026-04-17 10:31:23', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(646, 203, 2, 2103, 171.13, 0, 0.956586, 'good', -0.119271, '2026-04-17 10:31:23', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3429011404514313}', 0, 'none', 'stable'),
(647, 203, 3, 2261, 170.994, 0, 0.937329, 'good', -0.136022, '2026-04-17 10:31:23', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.38842031359672546}', 0, 'none', 'stable'),
(648, 203, 4, 2604, 170.006, 0, 0.927101, 'good', -0.158958, '2026-04-17 10:31:23', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3660752177238464}', 0, 'none', 'stable'),
(649, 203, 5, 2646, 172.437, 0, 0.935424, 'good', -0.179622, '2026-04-17 10:31:23', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3267088830471039}', 0, 'none', 'stable'),
(650, 203, 6, 2734, 174.169, 0, 0.94714, 'good', -0.201783, '2026-04-17 10:31:23', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.2789284884929657}', 0, 'none', 'stable'),
(651, 205, 1, 1418, 1.52434, 0.0799249, 0.962638, 'good', -0.282232, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(652, 205, 2, 976, 1.14756, 0.0668841, 0.96942, 'good', -0.187343, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.5912628173828, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(653, 205, 3, 1399, 0.967985, 0.0368869, 0.975457, 'good', 0.10039, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 147.29022216796875, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(654, 205, 4, 2765, 1.00696, 0.194045, 0.984158, 'good', -0.507309, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 127.99625396728516, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(655, 205, 5, 1154, 1.293, 0.0902458, 0.963796, 'bad', -0.0862774, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(656, 205, 6, 1321, 0.701145, 0.0836408, 0.969773, 'good', -0.423247, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 146.82412719726562, \"is_warning\": false, \"fatigue_index\": 22.59344787597656, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\"}', 22.5934, 'low', 'stable'),
(657, 205, 7, 1110, 0.640212, 0.0638578, 0.982466, 'good', -0.398168, '2026-04-17 10:36:21', '{\"arm\": \"R\", \"reasons\": [\"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"warning\", \"elbow_min\": 109.0460433959961, \"is_warning\": true, \"fatigue_index\": 30.237788648935258, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\"}', 30.2378, 'low', 'stable'),
(658, 206, 1, 3309, 173.537, 0.0433077, 0.977135, 'good', -0.232234, '2026-04-17 10:54:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04330769181251526, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29827752709388733}', 0, 'none', 'stable'),
(659, 206, 2, 3615, 175.834, 0.0542776, 0.973819, 'good', -0.302214, '2026-04-17 10:54:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05427761375904083, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2803453505039215}', 0, 'none', 'stable'),
(660, 206, 3, 3559, 176.179, 0.0560182, 0.967164, 'good', -0.295102, '2026-04-17 10:54:07', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05601818487048149, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2834339737892151}', 0, 'none', 'stable'),
(661, 206, 4, 3441, 175.788, 0.0597941, 0.954971, 'good', -0.271299, '2026-04-17 10:54:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05979405716061592, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2793370187282562}', 0, 'none', 'stable'),
(662, 206, 5, 3804, 176.632, 0.0591432, 0.958675, 'good', -0.342168, '2026-04-17 10:54:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05914318189024925, \"fatigue_index\": 0.5208328366279602, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.29118239879608154}', 0.520833, 'none', 'stable'),
(663, 206, 6, 4734, 169.001, 0.55, 0.961811, 'bad', -0.601329, '2026-04-17 10:54:07', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 2.4500027178813664, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.6672157645225525}', 2.45, 'none', 'stable'),
(664, 206, 7, 2836, 169.229, 0.504535, 0.982387, 'good', -0.30259, '2026-04-17 10:54:07', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.504535436630249, \"fatigue_index\": 40.95975455765158, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.48542520403862}', 40.9598, 'low', 'stable'),
(665, 207, 1, 4423, 177.796, 0.0680234, 0.98028, 'good', -0.453248, '2026-04-17 10:57:48', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06802341341972351, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3093644380569458}', 0, 'none', 'stable'),
(666, 207, 2, 4236, 169.081, 0.0692801, 0.979294, 'good', -0.381865, '2026-04-17 10:57:48', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06928011029958725, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.284493625164032}', 0, 'none', 'stable'),
(667, 207, 3, 4913, 168.24, 0.0707481, 0.975103, 'good', -0.492669, '2026-04-17 10:57:48', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07074812799692154, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.292830228805542}', 0, 'none', 'stable'),
(668, 207, 4, 5074, 165.098, 0.108282, 0.969847, 'good', -0.526662, '2026-04-17 10:57:48', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10828208923339844, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.31559842824935913}', 0, 'none', 'stable'),
(669, 207, 5, 8439, 168.458, 0.55, 0.960114, 'bad', -0.682719, '2026-04-17 10:57:48', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(670, 208, 1, 4135, 171.555, 0.0588098, 0.85536, 'good', -0.372904, '2026-04-17 11:01:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0588098019361496, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3221791982650757}', 0, 'none', 'stable'),
(671, 208, 2, 2659, 169.867, 0.154443, 0.880175, 'good', -0.170021, '2026-04-17 11:01:31', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.15444326400756836, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4534926116466522}', 0, 'none', 'stable'),
(672, 209, 1, 5839, 175.318, 0.184472, 0.934449, 'good', -0.638246, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.18447160720825195, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(673, 209, 2, 3722, 173.926, 0.134855, 0.957411, 'good', -0.367705, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.13485479354858398, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.457880437374115}', 0, 'none', 'stable'),
(674, 209, 3, 3330, 173.736, 0.133167, 0.947218, 'good', -0.307463, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.13316668570041656, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5473411679267883}', 0, 'none', 'stable'),
(675, 209, 4, 3407, 166.912, 0.147661, 0.955482, 'bad', -0.295433, '2026-04-17 11:07:30', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.14766082167625427, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5560015439987183}', 0, 'none', 'stable'),
(676, 209, 5, 112533, 160.898, 0.55, 0.912258, 'bad', -0.683567, '2026-04-17 11:07:30', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(677, 209, 6, 2532, 166.439, 0.196142, 0.943928, 'good', -0.151903, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.19614167511463165, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3800078928470611}', 0, 'none', 'stable'),
(678, 209, 7, 1537, 153.504, 0.159073, 0.964908, 'good', 0.0167365, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.15907323360443115, \"fatigue_index\": 6.178073585033417, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3822699785232544}', 6.17807, 'none', 'stable'),
(679, 209, 8, 1444, 173.825, 0.163301, 0.968914, 'good', -0.0825774, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.16330108046531677, \"fatigue_index\": 0.7046411434809368, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.32540953159332275}', 0.704641, 'none', 'stable'),
(680, 209, 9, 1374, 174.453, 0.150032, 0.964191, 'good', -0.0832328, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.15003162622451782, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.29695236682891846}', 0, 'none', 'stable'),
(681, 209, 10, 1582, 176.893, 0.149646, 0.970237, 'good', -0.113986, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1496458351612091, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3552863895893097}', 0, 'none', 'stable'),
(682, 209, 11, 1592, 174.257, 0.144811, 0.96947, 'good', -0.0853681, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.14481079578399658, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.4199963510036469}', 0, 'none', 'stable'),
(683, 209, 12, 1616, 175.632, 0.168358, 0.96486, 'good', -0.111106, '2026-04-17 11:07:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.16835816204547882, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3249343931674957}', 0, 'none', 'stable'),
(684, 209, 13, 1624, 177.485, 0.134833, 0.964241, 'good', -0.11579, '2026-04-17 11:07:31', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.134832963347435, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.37904831767082214}', 0, 'none', 'stable'),
(685, 209, 14, 4369, 158.841, 0.166848, 0.975294, 'good', -0.454659, '2026-04-17 11:07:31', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1668478697538376, \"fatigue_index\": 1.295772691567739, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.4125220775604248}', 1.29577, 'none', 'stable'),
(686, 209, 15, 6854, 170.124, 0.55, 0.877736, 'good', -0.674922, '2026-04-17 11:07:31', '{\"reasons\": [\"Keep torso stable\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 14.62931106475959, \"fatigue_level\": \"none\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.7}', 14.6293, 'none', 'rising'),
(687, 209, 16, 30728, 118.586, 0.178507, 0.629602, 'bad', -0.683567, '2026-04-17 11:07:31', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.17850668728351593, \"fatigue_index\": 50.73242258363301, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.6333220601081848}', 50.7324, 'low', 'sharply_rising'),
(688, 209, 17, 2906, 99.9372, 0.118443, 0.567574, 'good', -0.550071, '2026-04-17 11:07:31', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11844276636838912, \"fatigue_index\": 66.04088734215844, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 17; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.5642734169960022}', 66.0409, 'moderate', 'sharply_rising'),
(689, 210, 1, 753, 115.934, 0.0873424, 0.783658, 'good', -0.319565, '2026-04-17 11:11:14', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08734244108200073, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2507535517215729}', 0, 'none', 'stable'),
(690, 210, 2, 38344, 168.169, 0.420721, 0.940101, 'bad', -0.683567, '2026-04-17 11:11:14', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.4207209348678589, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(691, 210, 3, 6230, 168.927, 0.471189, 0.667131, 'bad', -0.650669, '2026-04-17 11:11:14', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.4711892008781433, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(692, 210, 4, 2006, 171.643, 0.144392, 0.980673, 'good', -0.0859027, '2026-04-17 11:11:14', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.14439231157302856, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3244941234588623}', 0, 'none', 'stable'),
(693, 210, 5, 2956, 160.384, 0.130787, 0.962882, 'good', -0.151162, '2026-04-17 11:11:14', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.13078731298446655, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.31792914867401123}', 0, 'none', 'stable'),
(694, 210, 6, 1974, 163.077, 0.12717, 0.970272, 'good', -0.00911895, '2026-04-17 11:11:14', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12717005610466003, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.28010043501853943}', 0, 'none', 'stable'),
(695, 210, 7, 1352, 139.259, 0.112123, 0.958617, 'good', -0.0309646, '2026-04-17 11:11:14', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11212275922298431, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.21879659593105316}', 0, 'none', 'stable'),
(696, 210, 8, 1159, 140.352, 0.145943, 0.97144, 'good', -0.0511637, '2026-04-17 11:11:14', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.14594343304634094, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.2556643486022949}', 0, 'none', 'stable'),
(697, 211, 1, 3721, 173.699, 0.168972, 0.925703, 'good', -0.387652, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1689722239971161, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4353432357311249}', 0, 'none', 'stable'),
(698, 211, 2, 3008, 163.006, 0.126445, 0.940977, 'good', -0.164779, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12644460797309875, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.32978418469429016}', 0, 'none', 'stable'),
(699, 211, 3, 3051, 163.031, 0.129821, 0.953637, 'good', -0.177204, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12982134521007538, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3452652394771576}', 0, 'none', 'stable'),
(700, 211, 4, 2676, 162.732, 0.10314, 0.944629, 'good', -0.0799564, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1031397581100464, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3671651184558869}', 0, 'none', 'stable'),
(701, 211, 5, 2366, 158.264, 0.104131, 0.934565, 'good', -0.0234791, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10413115471601486, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.4140286445617676}', 0, 'none', 'stable');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(702, 211, 6, 2620, 164.506, 0.0962653, 0.928013, 'good', -0.0725677, '2026-04-17 11:13:04', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.09626525640487672, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.36412474513053894}', 0, 'none', 'stable'),
(703, 215, 1, 2589, 176.246, 0.0617996, 0.977407, 'good', -0.14165, '2026-04-17 11:20:39', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06179960444569588, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2995664179325104}', 0, 'none', 'stable'),
(704, 215, 2, 2347, 159.759, 0.0675398, 0.962092, 'good', 0.0116746, '2026-04-17 11:20:39', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06753982603549957, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3365834355354309}', 0, 'none', 'stable'),
(705, 215, 3, 2211, 164.096, 0.0706223, 0.955071, 'good', 0.00651384, '2026-04-17 11:20:39', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07062230259180069, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.33174461126327515}', 0, 'none', 'stable'),
(706, 215, 4, 31908, 172.978, 0.55, 0.796536, 'bad', -0.683567, '2026-04-17 11:20:39', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbows steadier (both)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(707, 217, 1, 3437, 176.522, 0.0955585, 0.982529, 'good', -0.294961, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0955585464835167, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.286021888256073}', 0, 'none', 'stable'),
(708, 217, 2, 3032, 170.492, 0.0826636, 0.972152, 'good', -0.165775, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0826636478304863, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2582465410232544}', 0, 'none', 'stable'),
(709, 217, 3, 2690, 171.275, 0.103527, 0.956375, 'good', -0.132776, '2026-04-17 11:24:03', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.10352708399295808, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2647993564605713}', 0, 'none', 'stable'),
(710, 217, 4, 2423, 170.018, 0.0930695, 0.953163, 'good', -0.0737978, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09306953847408296, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24966952204704285}', 0, 'none', 'stable'),
(711, 217, 5, 2534, 168.349, 0.0856953, 0.959257, 'good', -0.0697128, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08569525182247162, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.2622278034687042}', 0, 'none', 'stable'),
(712, 217, 6, 2304, 169.917, 0.0923231, 0.952196, 'good', -0.0572895, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09232307970523834, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.26795676350593567}', 0, 'none', 'stable'),
(713, 217, 7, 2389, 170.76, 0.0892854, 0.951646, 'good', -0.0726422, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08928535878658295, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.24331597983837128}', 0, 'none', 'stable'),
(714, 217, 8, 2136, 170.449, 0.0904288, 0.946261, 'good', -0.0423095, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09042882919311523, \"fatigue_index\": 0.6365511152479384, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.27180811762809753}', 0.636551, 'none', 'stable'),
(715, 217, 9, 2129, 169.98, 0.0834435, 0.943149, 'good', -0.0325002, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08344346284866333, \"fatigue_index\": 0.29405951499938965, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.26487433910369873}', 0.29406, 'none', 'stable'),
(716, 217, 10, 2157, 168.579, 0.082097, 0.954165, 'good', -0.025228, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08209695667028427, \"fatigue_index\": 1.0644793510437012, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.32833752036094666}', 1.06448, 'none', 'stable'),
(717, 217, 11, 2027, 169.265, 0.0850815, 0.952907, 'good', -0.0192293, '2026-04-17 11:24:03', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08508151024580002, \"fatigue_index\": 4.297633965810141, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3009065091609955}', 4.29763, 'none', 'stable'),
(718, 218, 1, 1564, 1.25, 0.099499, 0.903558, 'good', -0.0656652, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(719, 218, 2, 1400, 1.21737, 0.122334, 0.901531, 'bad', -0.289575, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(720, 218, 3, 1019, 1.09516, 0.132125, 0.907618, 'good', -0.417343, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 60, \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(721, 218, 4, 932, 1.17482, 0.105893, 0.89868, 'good', -0.0587089, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(722, 218, 5, 911, 0.907002, 0.0880714, 0.905981, 'good', -0.162296, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(723, 218, 6, 817, 0.618411, 0.0888449, 0.914328, 'good', -0.248133, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 73.37989807128906, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(724, 218, 7, 661, 0.853726, 0.0794156, 0.909092, 'good', -0.339243, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(725, 218, 8, 775, 0.784969, 0.106902, 0.906852, 'bad', -0.140824, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(726, 218, 9, 845, 0.754313, 0.113384, 0.912614, 'good', -0.498788, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 125.85869598388672, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(727, 218, 10, 819, 0.705216, 0.120554, 0.923268, 'good', -0.306915, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0.7219238820865829, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0.721924, 'none', 'stable'),
(728, 218, 11, 748, 0.823037, 0.0866801, 0.906182, 'good', -0.227555, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0.7219238820865829, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0.721924, 'none', 'stable'),
(729, 218, 12, 788, 0.915648, 0.124328, 0.90384, 'good', -0.349306, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(730, 218, 13, 659, 0.616497, 0.0937818, 0.908089, 'good', -0.20527, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(731, 218, 14, 665, 0.779613, 0.122334, 0.922911, 'good', -0.350109, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(732, 218, 15, 647, 0.659579, 0.0905057, 0.93164, 'good', -0.230249, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 6.282782152533136, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 6.28278, 'none', 'stable'),
(733, 218, 16, 733, 0.766896, 0.112382, 0.907236, 'good', -0.211314, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60.83501434326172, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0, 'none', 'stable'),
(734, 218, 17, 730, 0.831082, 0.123933, 0.867064, 'bad', -0.356002, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0, 'none', 'stable'),
(735, 218, 18, 758, 0.86781, 0.146896, 0.903804, 'good', -0.496938, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0, 'none', 'stable'),
(736, 218, 19, 700, 0.925291, 0.0913733, 0.910138, 'bad', -0.177428, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0, 'none', 'stable'),
(737, 218, 20, 778, 0.647413, 0.0989981, 0.909829, 'good', -0.136131, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0, 'none', 'stable'),
(738, 218, 21, 680, 0.758808, 0.0964666, 0.926254, 'bad', -0.162377, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0.4580489519893365, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0.458049, 'none', 'stable'),
(739, 218, 22, 785, 0.800401, 0.119623, 0.892167, 'bad', -0.29249, '2026-04-17 11:31:59', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0.4580489519893365, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0.458049, 'none', 'stable'),
(740, 218, 23, 698, 0.705683, 0.147742, 0.924664, 'bad', -0.499209, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0.4580489519893365, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 0.458049, 'none', 'stable'),
(741, 218, 24, 734, 0.676768, 0.125572, 0.931554, 'good', -0.38194, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 60, \"is_warning\": true, \"fatigue_index\": 3.5764887907068914, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 3.57649, 'none', 'stable'),
(742, 218, 25, 879, 1.0227, 0.108497, 0.931646, 'bad', -0.102699, '2026-04-17 11:31:59', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 3.5764887907068914, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\"}', 3.57649, 'none', 'stable'),
(743, 219, 1, 2844, 139.143, 0.387658, 0.809908, 'bad', -0.26786, '2026-04-17 11:36:37', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.387658417224884, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3659124374389648}', 0, 'none', 'stable'),
(744, 219, 2, 3887, 173.418, 0.154775, 0.972562, 'good', -0.403641, '2026-04-17 11:36:37', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.154775470495224, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3898196816444397}', 0, 'none', 'stable'),
(745, 220, 1, 5048, 174.86, 0.117435, 0.996498, 'good', -0.547564, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11743543297052383, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.22631210088729856}', 0, 'none', 'stable'),
(746, 220, 2, 5166, 172.862, 0.16105, 0.995417, 'good', -0.575779, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.16105014085769653, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2598201334476471}', 0, 'none', 'stable'),
(747, 220, 3, 5303, 167.841, 0.157843, 0.997813, 'good', -0.580147, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1578432470560074, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.25830477476119995}', 0, 'none', 'stable'),
(748, 220, 4, 4270, 163.385, 0.146791, 0.998276, 'good', -0.429328, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.146791473031044, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2889786660671234}', 0, 'none', 'stable'),
(749, 220, 5, 4440, 163.241, 0.143432, 0.997816, 'good', -0.454709, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.14343203604221344, \"fatigue_index\": 3.239836957719591, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2946842312812805}', 3.23984, 'none', 'stable'),
(750, 220, 6, 4379, 170.5, 0.153947, 0.996683, 'good', -0.469862, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.15394721925258636, \"fatigue_index\": 3.239836957719591, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.28411972522735596}', 3.23984, 'none', 'stable'),
(751, 220, 7, 4456, 170.08, 0.0887762, 0.997488, 'good', -0.434073, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08877620846033096, \"fatigue_index\": 2.6999546421898737, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.25915753841400146}', 2.69995, 'none', 'stable'),
(752, 220, 8, 4500, 171.049, 0.107838, 0.996186, 'good', -0.457224, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10783810168504716, \"fatigue_index\": 0.738097561730279, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2664630115032196}', 0.738098, 'none', 'stable'),
(753, 220, 9, 5291, 168.814, 0.101184, 0.996651, 'good', -0.554516, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1011841893196106, \"fatigue_index\": 0.1475214958190918, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2611478269100189}', 0.147521, 'none', 'stable'),
(754, 220, 10, 5046, 171.673, 0.136362, 0.997665, 'good', -0.549792, '2026-04-17 11:38:09', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1363622397184372, \"fatigue_index\": 0.1475214958190918, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2571128010749817}', 0.147521, 'none', 'stable'),
(755, 221, 1, 592, 0.290329, 0.076767, 0.998864, 'good', -0.412516, '2026-04-17 11:41:03', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(756, 221, 2, 1435, 1.27899, 0.0884902, 0.998305, 'good', -0.446055, '2026-04-17 11:41:03', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 162.22805786132812, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(757, 222, 1, 4960, 167.967, 0.177244, 0.996691, 'good', -0.553173, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.17724354565143585, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.27542033791542053}', 0, 'none', 'stable'),
(758, 222, 2, 4223, 163.026, 0.142133, 0.997102, 'good', -0.417126, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.14213301241397858, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.26501786708831787}', 0, 'none', 'stable'),
(759, 222, 3, 3598, 164.187, 0.114332, 0.996442, 'good', -0.273169, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11433202028274536, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2841501832008362}', 0, 'none', 'stable'),
(760, 222, 4, 6368, 169.392, 0.1475, 0.998018, 'good', -0.647826, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.14750047028064728, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3451811373233795}', 0, 'none', 'stable'),
(761, 222, 5, 3309, 158.189, 0.0919444, 0.996207, 'good', -0.173409, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.09194442629814148, \"fatigue_index\": 2.0488467481401234, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3025898039340973}', 2.04885, 'none', 'stable'),
(762, 222, 6, 3349, 157.067, 0.0764738, 0.994982, 'good', -0.164882, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07647376507520676, \"fatigue_index\": 2.0488467481401234, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2711012363433838}', 2.04885, 'none', 'stable'),
(763, 222, 7, 3619, 165.187, 0.10186, 0.995533, 'good', -0.268314, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10185977071523666, \"fatigue_index\": 0.7216566138797337, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2906450927257538}', 0.721657, 'none', 'stable'),
(764, 222, 8, 3845, 163.92, 0.12494, 0.995268, 'good', -0.332771, '2026-04-17 11:50:40', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12493950128555298, \"fatigue_index\": 0.12043118476867676, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2852340638637543}', 0.120431, 'none', 'stable'),
(765, 222, 9, 3607, 156.351, 0.0702338, 0.993734, 'good', -0.215388, '2026-04-17 11:50:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0702337846159935, \"fatigue_index\": 0.12043118476867676, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.24242371320724487}', 0.120431, 'none', 'stable'),
(766, 223, 1, 3346, 167.566, 0.55, 0.961201, 'good', -0.478482, '2026-04-17 11:55:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.6641324162483215}', 0, 'none', 'stable'),
(767, 223, 2, 2452, 169.888, 0.101413, 0.965887, 'good', -0.102673, '2026-04-17 11:55:22', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1014125719666481, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4703754186630249}', 0, 'none', 'stable'),
(768, 223, 3, 2520, 175.2, 0.240014, 0.963471, 'good', -0.242781, '2026-04-17 11:55:22', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.24001444876194, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5273404121398926}', 0, 'none', 'stable'),
(769, 223, 4, 5892, 169.263, 0.55, 0.942133, 'good', -0.656236, '2026-04-17 11:55:22', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(770, 223, 5, 2301, 170.13, 0.0891963, 0.983003, 'good', -0.057814, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08919627964496613, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.31479403376579285}', 0, 'none', 'stable'),
(771, 223, 6, 2496, 153.892, 0.105437, 0.985571, 'good', -0.0334965, '2026-04-17 11:55:22', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10543732345104218, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.3406193256378174}', 0, 'none', 'stable'),
(772, 223, 7, 2567, 152.847, 0.0857011, 0.98525, 'good', -0.0260367, '2026-04-17 11:55:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0857010930776596, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.35792380571365356}', 0, 'none', 'stable'),
(773, 223, 8, 2231, 159.744, 0.0895104, 0.978789, 'good', 0.0135303, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08951042592525482, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.3221838176250458}', 0, 'none', 'stable'),
(774, 223, 9, 2670, 164.712, 0.0918045, 0.969834, 'good', -0.0726186, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09180448204278946, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.28217846155166626}', 0, 'none', 'stable'),
(775, 223, 10, 2781, 157.959, 0.0776077, 0.976276, 'good', -0.0583422, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07760772109031677, \"fatigue_index\": 0.4752221050050018, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.3498569428920746}', 0.475222, 'none', 'stable'),
(776, 223, 11, 4260, 162.482, 0.0627394, 0.960735, 'good', -0.374773, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06273939460515976, \"fatigue_index\": 2.720879533256741, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.44852668046951294}', 2.72088, 'none', 'stable'),
(777, 223, 12, 4210, 133.076, 0.100115, 0.971569, 'bad', -0.445819, '2026-04-17 11:55:22', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10011540353298189, \"fatigue_index\": 28.000000000000004, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.5685885548591614}', 28, 'low', 'sharply_rising'),
(778, 223, 13, 4117, 142.755, 0.0890902, 0.977665, 'bad', -0.405579, '2026-04-17 11:55:22', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08909015357494354, \"fatigue_index\": 33.47119416009712, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.6869303584098816}', 33.4712, 'low', 'sharply_rising'),
(779, 223, 14, 2521, 156.762, 0.0635512, 0.957849, 'good', -0.00392893, '2026-04-17 11:55:22', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06355118006467819, \"fatigue_index\": 33.47119416009712, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.33788037300109863}', 33.4712, 'low', 'sharply_rising'),
(780, 223, 15, 5334, 174.889, 0.0841388, 0.955521, 'good', -0.566826, '2026-04-17 11:55:22', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08413875102996826, \"fatigue_index\": 28.000000000000004, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.3876944482326507}', 28, 'low', 'rising'),
(781, 223, 16, 2344, 167.202, 0.0569355, 0.965025, 'good', -0.0231106, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05693545565009117, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2480732500553131}', 0, 'none', 'stable'),
(782, 223, 17, 2126, 166.045, 0.0673153, 0.966063, 'good', 0.007797, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06731528043746948, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2356535792350769}', 0, 'none', 'recovering'),
(783, 223, 18, 2342, 170.23, 0.0624957, 0.965358, 'good', -0.0488854, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.062495674937963486, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2553918659687042}', 0, 'none', 'recovering'),
(784, 223, 19, 2326, 159.254, 0.0540625, 0.965723, 'good', 0.0212673, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05406254157423973, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.29925721883773804}', 0, 'none', 'recovering'),
(785, 223, 20, 2477, 160.565, 0.0804247, 0.968049, 'good', -0.012312, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08042469620704651, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.26350313425064087}', 0, 'none', 'recovering'),
(786, 223, 21, 2724, 159.927, 0.064554, 0.971864, 'good', -0.0398802, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06455396860837936, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.25188717246055603}', 0, 'none', 'stable'),
(787, 223, 22, 2803, 164.579, 0.0754858, 0.96848, 'good', -0.080547, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07548577338457108, \"fatigue_index\": 1.576336113777188, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.24868841469287872}', 1.57634, 'none', 'stable'),
(788, 223, 23, 2742, 156.969, 0.0866763, 0.966301, 'good', -0.0526439, '2026-04-17 11:55:22', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08667631447315216, \"fatigue_index\": 1.930403571837664, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.27846232056617737}', 1.9304, 'none', 'stable'),
(789, 223, 24, 2428, 156.327, 0.0840886, 0.963068, 'good', 0.00218404, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08408862352371216, \"fatigue_index\": 1.930403571837664, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2527776062488556}', 1.9304, 'none', 'stable'),
(790, 223, 25, 2568, 159.696, 0.0808407, 0.966808, 'good', -0.0241808, '2026-04-17 11:55:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08084072172641754, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.28167596459388733}', 0, 'none', 'stable'),
(791, 224, 1, 3309, 173.297, 0.109289, 0.947834, 'good', -0.260435, '2026-04-17 11:57:44', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10928931087255478, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2561430037021637}', 0, 'none', 'stable'),
(792, 224, 2, 2959, 166.736, 0.116278, 0.962351, 'good', -0.161098, '2026-04-17 11:57:44', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11627808213233948, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2938140034675598}', 0, 'none', 'stable'),
(793, 224, 3, 2732, 166.076, 0.105408, 0.961062, 'good', -0.105584, '2026-04-17 11:57:44', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10540841519832612, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3134319484233856}', 0, 'none', 'stable'),
(794, 224, 4, 2476, 162.905, 0.0911212, 0.963011, 'good', -0.0325013, '2026-04-17 11:57:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09112121164798737, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2964535057544708}', 0, 'none', 'stable'),
(795, 224, 5, 10345, 165.036, 0.300024, 0.975672, 'bad', -0.683537, '2026-04-17 11:57:44', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.30002379417419434, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.43691539764404297}', 0, 'none', 'stable'),
(796, 224, 6, 1263, 124.188, 0.205829, 0.983356, 'good', -0.27615, '2026-04-17 11:57:44', '{\"reasons\": [\"Keep torso stable\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.20582914352416992, \"fatigue_index\": 16.383250140481525, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.22858090698719025}', 16.3832, 'low', 'stable'),
(797, 224, 7, 1707, 171.938, 0.101755, 0.97017, 'good', -0.0372696, '2026-04-17 11:57:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.10175459086894988, \"fatigue_index\": 16.089972108602524, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.21652427315711975}', 16.09, 'low', 'stable'),
(798, 224, 8, 2190, 173.501, 0.458179, 0.989378, 'bad', -0.164286, '2026-04-17 11:57:44', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.4581791758537293, \"fatigue_index\": 16.089972108602524, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.47964513301849365}', 16.09, 'low', 'stable'),
(799, 224, 9, 2112, 168.759, 0.184629, 0.961518, 'good', -0.107099, '2026-04-17 11:57:44', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.184629425406456, \"fatigue_index\": 12.556685755650204, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2625885009765625}', 12.5567, 'none', 'stable'),
(800, 225, 1, 5535, 176.302, 0.0771189, 0.932971, 'good', -0.584547, '2026-04-17 12:12:13', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07711886614561081, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24317820370197296}', 0, 'none', 'stable'),
(801, 225, 2, 5704, 176.42, 0.103112, 0.931998, 'good', -0.605655, '2026-04-17 12:12:13', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10311245173215866, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.1935726553201675}', 0, 'none', 'stable'),
(802, 225, 3, 10116, 177.088, 0.128264, 0.941959, 'good', -0.683456, '2026-04-17 12:12:13', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12826400995254517, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.21313050389289856}', 0, 'none', 'stable'),
(803, 226, 1, 3905, 158.558, 0.10096, 0.815332, 'good', -0.309618, '2026-04-17 12:34:29', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10096012055873872, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29779380559921265}', 0, 'none', 'stable'),
(804, 226, 2, 3300, 174.479, 0.106891, 0.929829, 'good', -0.265146, '2026-04-17 12:34:29', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1068907231092453, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.28235873579978943}', 0, 'none', 'stable'),
(805, 226, 3, 3373, 177.47, 0.0883462, 0.937772, 'good', -0.285707, '2026-04-17 12:34:29', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08834615349769592, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2576366662979126}', 0, 'none', 'stable');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(806, 226, 4, 3774, 174.61, 0.112804, 0.937067, 'good', -0.355466, '2026-04-17 12:34:29', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.11280422657728197, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29025542736053467}', 0, 'none', 'stable'),
(807, 226, 5, 4064, 173.683, 0.108124, 0.938164, 'good', -0.396757, '2026-04-17 12:34:29', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.10812361538410188, \"fatigue_index\": 0.20548204580942792, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.289366215467453}', 0.205482, 'none', 'stable'),
(808, 226, 6, 3632, 173.591, 0.0886277, 0.95101, 'good', -0.30355, '2026-04-17 12:34:29', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0886276587843895, \"fatigue_index\": 0.20548204580942792, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.26540419459342957}', 0.205482, 'none', 'stable'),
(809, 226, 7, 3937, 172.748, 0.0596456, 0.93798, 'good', -0.342472, '2026-04-17 12:34:29', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0596456415951252, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.3098214566707611}', 0, 'none', 'stable'),
(810, 226, 8, 3917, 173.447, 0.0754466, 0.96281, 'good', -0.346626, '2026-04-17 12:34:29', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07544655352830887, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.25903424620628357}', 0, 'none', 'stable'),
(811, 226, 9, 3919, 173.262, 0.0672056, 0.960068, 'good', -0.343599, '2026-04-17 12:34:29', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06720562279224396, \"fatigue_index\": 1.0859933164384632, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.29914015531539917}', 1.08599, 'none', 'stable'),
(812, 226, 10, 3587, 174.044, 0.0843251, 0.951803, 'good', -0.295811, '2026-04-17 12:34:29', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08432509750127792, \"fatigue_index\": 0.23182895448472765, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.29145267605781555}', 0.231829, 'none', 'stable'),
(813, 226, 11, 3943, 176.982, 0.166008, 0.931797, 'good', -0.436981, '2026-04-17 12:34:29', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.16600792109966278, \"fatigue_index\": 1.0859933164384632, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3293224275112152}', 1.08599, 'none', 'stable'),
(814, 227, 1, 2396, 89.7004, 0.324791, 0.686683, 'good', -0.629675, '2026-04-17 12:48:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.3247913718223572, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3117216229438782}', 0, 'none', 'stable'),
(815, 227, 2, 3420, 171.659, 0.0426968, 0.917484, 'good', -0.240774, '2026-04-17 12:48:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04269677773118019, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3290143609046936}', 0, 'none', 'stable'),
(816, 227, 3, 4225, 162.29, 0.0557696, 0.954812, 'good', -0.356804, '2026-04-17 12:48:31', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.05576962232589722, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3500765264034271}', 0, 'none', 'stable'),
(817, 227, 4, 4869, 158.178, 0.0660009, 0.965244, 'good', -0.47313, '2026-04-17 12:48:31', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06600088626146317, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4118750393390655}', 0, 'none', 'stable'),
(818, 227, 5, 5490, 160.288, 0.0650885, 0.970154, 'good', -0.55824, '2026-04-17 12:48:31', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06508851051330566, \"fatigue_index\": 11.666305204912964, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.4081389904022217}', 11.6663, 'none', 'stable'),
(819, 227, 6, 5019, 167.2, 0.0668747, 0.963755, 'good', -0.506233, '2026-04-17 12:48:31', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06687470525503159, \"fatigue_index\": 13.627185367087687, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3519097566604614}', 13.6272, 'none', 'stable'),
(820, 227, 7, 4405, 162.097, 0.0686804, 0.963192, 'good', -0.391773, '2026-04-17 12:48:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06868039816617966, \"fatigue_index\": 7.525129228042397, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.27708351612091064}', 7.52513, 'none', 'stable'),
(821, 227, 8, 4443, 163.337, 0.0712643, 0.9656, 'good', -0.402081, '2026-04-17 12:48:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07126427441835403, \"fatigue_index\": 0.6728130605326244, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.24724909663200376}', 0.672813, 'none', 'recovering'),
(822, 228, 1, 3491, 166.352, 0.074133, 0.967643, 'good', -0.223472, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07413296401500702, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.26178357005119324}', 0, 'none', 'stable'),
(823, 228, 2, 3020, 165.234, 0.0430373, 0.974472, 'good', -0.117835, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.043037254363298416, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.21739260852336884}', 0, 'none', 'stable'),
(824, 228, 3, 16959, 173.795, 0.116615, 0.730175, 'good', -0.683567, '2026-04-17 13:00:54', '{\"reasons\": [\"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11661477386951448, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4016923904418946}', 0, 'none', 'stable'),
(825, 228, 4, 2839, 161.348, 0.0539824, 0.967637, 'good', -0.0695158, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.053982384502887726, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3377244472503662}', 0, 'none', 'stable'),
(826, 228, 5, 2986, 163.614, 0.0524169, 0.983423, 'good', -0.103336, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05241694301366806, \"fatigue_index\": 4.548917214075725, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2967841923236847}', 4.54892, 'none', 'stable'),
(827, 228, 6, 2997, 163.678, 0.0355173, 0.982347, 'good', -0.115942, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03551730513572693, \"fatigue_index\": 4.273394743601481, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.335244745016098}', 4.27339, 'none', 'stable'),
(828, 228, 7, 2811, 157.951, 0.0430043, 0.981107, 'good', -0.0490095, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04300428926944733, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.24854359030723572}', 0, 'none', 'stable'),
(829, 228, 8, 3183, 162.127, 0.0522329, 0.976561, 'good', -0.133091, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05223291739821434, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2613944411277771}', 0, 'none', 'stable'),
(830, 228, 9, 2519, 161.566, 0.0690349, 0.985517, 'good', -0.0172884, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06903492659330368, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.30272766947746277}', 0, 'none', 'stable'),
(831, 228, 10, 3013, 162.994, 0.0538584, 0.990429, 'good', -0.113818, '2026-04-17 13:00:54', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.053858403116464615, \"fatigue_index\": 0.6603863504197863, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3764556050300598}', 0.660386, 'none', 'stable'),
(832, 228, 11, 3037, 156.611, 0.073045, 0.982866, 'good', -0.0989738, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07304501533508301, \"fatigue_index\": 4.924688902166156, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.31852757930755615}', 4.92469, 'none', 'stable'),
(833, 228, 12, 3201, 156.037, 0.0795678, 0.985704, 'good', -0.134925, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0795678049325943, \"fatigue_index\": 5.593037025796043, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.27624502778053284}', 5.59304, 'none', 'stable'),
(834, 228, 13, 2303, 161.51, 0.0832406, 0.987577, 'good', 0.000496291, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0832405686378479, \"fatigue_index\": 6.68016862538126, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.34910696744918823}', 6.68017, 'none', 'stable'),
(835, 228, 14, 2931, 158.45, 0.0569493, 0.986935, 'good', -0.0744115, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05694931745529175, \"fatigue_index\": 5.919759058290058, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.31168389320373535}', 5.91976, 'none', 'stable'),
(836, 228, 15, 2898, 158.27, 0.0546605, 0.982204, 'good', -0.0656506, '2026-04-17 13:00:54', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05466048792004585, \"fatigue_index\": 2.150011145406299, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.28902530670166016}', 2.15001, 'none', 'stable'),
(837, 230, 1, 2869, 175.054, 0.12253, 0.961976, 'good', -0.219538, '2026-04-17 13:04:44', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.12252981215715408, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4404994249343872}', 0, 'none', 'stable'),
(838, 230, 2, 2786, 168.389, 0.0787726, 0.980897, 'good', -0.111184, '2026-04-17 13:04:44', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0787726417183876, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3645496070384979}', 0, 'none', 'stable'),
(839, 230, 3, 3413, 165.308, 0.0759605, 0.979438, 'good', -0.205949, '2026-04-17 13:04:44', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07596046477556229, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3181822597980499}', 0, 'none', 'stable'),
(840, 230, 4, 2705, 161.766, 0.0656181, 0.98139, 'good', -0.0506746, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0656181126832962, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.34641581773757935}', 0, 'none', 'stable'),
(841, 230, 5, 3151, 151.063, 0.0530263, 0.982407, 'good', -0.113352, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05302627757191658, \"fatigue_index\": 2.471544527573331, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.31256014108657837}', 2.47154, 'none', 'stable'),
(842, 230, 6, 2940, 152.931, 0.0572391, 0.970472, 'good', -0.0682719, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.057239141315221786, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.28462252020835876}', 0, 'none', 'stable'),
(843, 230, 7, 2868, 159.943, 0.0686889, 0.980748, 'good', -0.0693925, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06868888437747955, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.29152408242225647}', 0, 'none', 'stable'),
(844, 230, 8, 2871, 153.142, 0.0441077, 0.981503, 'good', -0.0562376, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04410770535469055, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.29659730195999146}', 0, 'none', 'stable'),
(845, 230, 9, 2887, 151.448, 0.069535, 0.983095, 'good', -0.0671412, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0695350393652916, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.31649282574653625}', 0, 'none', 'stable'),
(846, 230, 10, 4060, 143.913, 0.0629771, 0.984189, 'good', -0.32508, '2026-04-17 13:04:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06297709047794342, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2725829780101776}', 0, 'none', 'stable'),
(847, 230, 11, 4363, 151.315, 0.0589685, 0.985516, 'good', -0.373337, '2026-04-17 13:04:44', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05896848067641258, \"fatigue_index\": 18.592364109315096, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.32383307814598083}', 18.5924, 'low', 'rising'),
(848, 230, 12, 4077, 152.545, 0.088411, 0.983986, 'good', -0.333038, '2026-04-17 13:04:44', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08841097354888916, \"fatigue_index\": 18.891986960276135, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.3374800980091095}', 18.892, 'low', 'rising'),
(849, 230, 13, 3340, 155.47, 0.070208, 0.987398, 'good', -0.157119, '2026-04-17 13:04:44', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07020798325538635, \"fatigue_index\": 18.891986960276135, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.2820112109184265}', 18.892, 'low', 'rising'),
(850, 230, 14, 4347, 154.551, 0.0621165, 0.988278, 'good', -0.371359, '2026-04-17 13:04:44', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.062116507440805435, \"fatigue_index\": 18.891986960276135, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.33516213297843933}', 18.892, 'low', 'rising'),
(851, 230, 15, 5092, 154.251, 0.0634189, 0.986273, 'good', -0.498619, '2026-04-17 13:04:44', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0634189173579216, \"fatigue_index\": 23.69488833205626, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.22123287618160248}', 23.6949, 'low', 'rising'),
(852, 231, 1, 1268, 1.26489, 0.108759, 0.975333, 'bad', -0.0442262, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.1598721146583557}', 0, 'none', 'stable'),
(853, 231, 2, 2695, 1.30428, 0.126796, 0.962108, 'bad', -0.0536159, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Press more evenly\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.4588728547096253}', 0, 'none', 'stable'),
(854, 231, 3, 3564, 1.27455, 0.11547, 0.973856, 'good', -0.0826214, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.1944911777973175}', 0, 'none', 'stable'),
(855, 231, 4, 2826, 1.27708, 0.138698, 0.977639, 'good', -0.0412617, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.2828575074672699}', 0, 'none', 'stable'),
(856, 231, 5, 2417, 1.20952, 0.128467, 0.975413, 'bad', -0.0510869, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Press more evenly\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.2531410753726959}', 0, 'none', 'stable'),
(857, 231, 6, 2377, 1.25448, 0.11752, 0.978545, 'good', 0.0109876, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.24868503212928772}', 0, 'none', 'stable'),
(858, 231, 7, 1919, 1.0157, 0.110465, 0.985118, 'good', -0.289096, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.1831607073545456}', 0, 'none', 'stable'),
(859, 231, 8, 1897, 0.88582, 0.114273, 0.98289, 'bad', -0.430962, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Press more evenly\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.24279113113880155}', 0, 'none', 'stable'),
(860, 231, 9, 2060, 1.0661, 0.117253, 0.976889, 'good', -0.202914, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"wrist_stack_absmax\": 0.23606689274311063}', 0, 'none', 'stable'),
(861, 231, 10, 1847, 1.13129, 0.137823, 0.970865, 'good', -0.187773, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Brace core; reduce lean\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"wrist_stack_absmax\": 0.189219668507576}', 0, 'none', 'stable'),
(862, 231, 11, 2575, 1.10056, 0.108991, 0.968337, 'good', -0.14105, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"wrist_stack_absmax\": 0.28933706879615784}', 0, 'none', 'stable'),
(863, 231, 12, 1515, 1.10559, 0.126826, 0.970439, 'bad', -0.14253, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Press more evenly\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 6.7481629550457, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"wrist_stack_absmax\": 0.28105464577674866}', 6.74816, 'none', 'stable'),
(864, 231, 13, 5203, 1.20375, 0.114353, 0.976921, 'good', -0.317099, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Press more evenly\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 6.7481629550457, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"wrist_stack_absmax\": 0.19258493185043335}', 6.74816, 'none', 'stable'),
(865, 231, 14, 2537, 1.32349, 0.153012, 0.959141, 'bad', -0.12147, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Brace core; reduce lean\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"wrist_stack_absmax\": 0.17001977562904358}', 0, 'none', 'stable'),
(866, 231, 15, 2614, 0.578277, 0.0882635, 0.984872, 'bad', -0.529446, '2026-04-17 13:06:51', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Press more evenly\", \"Range dropping - lighten weight or rest\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"wrist_stack_absmax\": 0.1571820229291916}', 0, 'none', 'stable'),
(867, 232, 1, 1667, 1.34632, 0.103501, 0.933551, 'good', -0.110703, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(868, 232, 2, 1457, 1.28574, 0.128421, 0.931716, 'good', -0.380723, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(869, 232, 3, 1562, 1.22443, 0.0901429, 0.960803, 'good', -0.138215, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 60, \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(870, 232, 4, 1592, 1.49482, 0.331032, 0.958237, 'bad', -0.507309, '2026-04-17 13:08:45', '{\"arm\": \"R\", \"reasons\": [\"Avoid leaning / swinging (side-to-side)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 157.77685546875, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(871, 232, 5, 1116, 1.41557, 0.0883855, 0.942468, 'good', -0.123092, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(872, 232, 6, 793, 0.719881, 0.068379, 0.945287, 'good', -0.439361, '2026-04-17 13:08:45', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(873, 232, 7, 1334, 1.24317, 0.0888569, 0.938884, 'good', -0.112796, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(874, 232, 8, 1178, 1.27835, 0.0974615, 0.935744, 'good', -0.00988528, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(875, 232, 9, 1046, 0.765907, 0.0973598, 0.935739, 'good', -0.491476, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 161.25721740722656, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(876, 232, 10, 1271, 1.19451, 0.106924, 0.948297, 'good', -0.0363242, '2026-04-17 13:08:45', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(877, 232, 11, 894, 1.05101, 0.0785708, 0.936834, 'good', -0.305978, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(878, 232, 12, 1099, 0.917817, 0.104627, 0.937542, 'good', -0.501888, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 160.99752807617188, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(879, 232, 13, 1057, 1.05489, 0.0839558, 0.944085, 'good', -0.198739, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(880, 232, 14, 852, 0.898537, 0.0759708, 0.946882, 'good', -0.352203, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(881, 232, 15, 1172, 1.19227, 0.0930054, 0.934311, 'good', -0.0473425, '2026-04-17 13:08:45', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\"}', 0, 'none', 'stable'),
(882, 234, 1, 8393, 176.382, 0.55, 0.971144, 'good', -0.682747, '2026-04-17 13:49:49', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.5726147890090942}', 0, 'none', 'stable'),
(883, 234, 2, 3738, 164.484, 0.0485115, 0.97685, 'good', -0.263693, '2026-04-17 13:49:49', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.048511505126953125, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.34555214643478394}', 0, 'none', 'stable'),
(884, 234, 3, 4146, 163.788, 0.0411532, 0.984711, 'good', -0.345578, '2026-04-17 13:49:49', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.041153185069561005, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.35201379656791687}', 0, 'none', 'stable'),
(885, 234, 4, 3527, 164.456, 0.0476239, 0.986347, 'good', -0.217867, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.047623876482248306, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.31982511281967163}', 0, 'none', 'stable'),
(886, 234, 5, 3667, 167.922, 0.0293289, 0.981323, 'good', -0.269326, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.029328910633921623, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.29733917117118835}', 0, 'none', 'stable'),
(887, 234, 6, 4668, 166.749, 0.0631636, 0.982732, 'good', -0.449001, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06316360086202621, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.3142336308956146}', 0, 'none', 'stable'),
(888, 234, 7, 4310, 164.235, 0.0529198, 0.982843, 'good', -0.376218, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.052919819951057434, \"fatigue_index\": 6.128776859064619, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3212829530239105}', 6.12878, 'none', 'stable'),
(889, 234, 8, 3996, 168.49, 0.056011, 0.979226, 'good', -0.329209, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05601103603839874, \"fatigue_index\": 6.64397954028817, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.26308560371398926}', 6.64398, 'none', 'stable'),
(890, 234, 9, 4884, 160.461, 0.212453, 0.984054, 'good', -0.548543, '2026-04-17 13:49:49', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.21245285868644712, \"fatigue_index\": 6.64397954028817, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.36827218532562256}', 6.64398, 'none', 'stable'),
(891, 234, 10, 3633, 161.446, 0.0910416, 0.96927, 'good', -0.247874, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09104155749082564, \"fatigue_index\": 8.216609304161635, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.26868924498558044}', 8.21661, 'none', 'stable'),
(892, 234, 11, 4094, 164.568, 0.0827909, 0.978615, 'good', -0.345537, '2026-04-17 13:49:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08279092609882355, \"fatigue_index\": 9.543938755226948, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2737467288970947}', 9.54394, 'none', 'stable'),
(893, 235, 1, 2992, 157.851, 0.0623748, 0.981355, 'good', -0.08704, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0623747855424881, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3229607343673706}', 0, 'none', 'stable'),
(894, 235, 2, 2461, 166.111, 0.0615254, 0.978906, 'good', -0.034069, '2026-04-17 14:00:40', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06152540072798729, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3167360723018646}', 0, 'none', 'stable'),
(895, 235, 3, 2424, 162.119, 0.0606028, 0.97591, 'good', -0.00327162, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06060275062918663, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2962663471698761}', 0, 'none', 'stable'),
(896, 235, 4, 3177, 158.443, 0.0314406, 0.964842, 'good', -0.137872, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.031440604478120804, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3715759217739105}', 0, 'none', 'stable'),
(897, 235, 5, 2910, 154.854, 0.0542533, 0.960184, 'good', -0.0676112, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.054253291338682175, \"fatigue_index\": 2.3600525326199007, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3442012071609497}', 2.36005, 'none', 'stable'),
(898, 235, 6, 2572, 149.376, 0.0406321, 0.955638, 'good', -0.0211035, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04063213989138603, \"fatigue_index\": 5.401687489615547, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3730572462081909}', 5.40169, 'none', 'stable'),
(899, 235, 7, 2728, 155.878, 0.0485763, 0.960873, 'good', -0.0307204, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04857628047466278, \"fatigue_index\": 2.3600525326199007, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.28913530707359314}', 2.36005, 'none', 'stable'),
(900, 235, 8, 3948, 157.428, 0.0448604, 0.960385, 'good', -0.288115, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04486039653420448, \"fatigue_index\": 0.9906888008117676, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3318769335746765}', 0.990689, 'none', 'stable'),
(901, 235, 9, 4355, 156.362, 0.0585419, 0.960509, 'good', -0.373444, '2026-04-17 14:00:40', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05854186043143272, \"fatigue_index\": 16.606029886781222, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.34826916456222534}', 16.606, 'low', 'rising'),
(902, 235, 10, 3429, 157.547, 0.0560195, 0.966688, 'good', -0.179399, '2026-04-17 14:00:40', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05601949244737625, \"fatigue_index\": 18.427388885397757, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.3612533509731293}', 18.4274, 'low', 'rising'),
(903, 235, 11, 3464, 156.05, 0.046155, 0.969053, 'good', -0.183503, '2026-04-17 14:00:40', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04615502804517746, \"fatigue_index\": 10.371155351438976, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.352023720741272}', 10.3712, 'none', 'stable'),
(904, 235, 12, 2952, 152.969, 0.0459298, 0.969829, 'good', -0.0699233, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.045929763466119766, \"fatigue_index\": 9.762443116406294, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.278006374835968}', 9.76244, 'none', 'stable'),
(905, 235, 13, 2906, 156.437, 0.0633946, 0.972371, 'good', -0.0709224, '2026-04-17 14:00:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06339456886053085, \"fatigue_index\": 2.858185105853611, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.3486844003200531}', 2.85819, 'none', 'stable'),
(906, 235, 14, 2853, 155.658, 0.04529, 0.965519, 'good', -0.0629204, '2026-04-17 14:00:40', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0452900193631649, \"fatigue_index\": 2.858185105853611, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.37356463074684143}', 2.85819, 'none', 'recovering'),
(907, 235, 15, 2741, 151.153, 0.0443607, 0.964745, 'good', -0.0423962, '2026-04-17 14:00:40', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.044360727071762085, \"fatigue_index\": 4.850953817367554, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.3666193187236786}', 4.85095, 'none', 'recovering'),
(908, 237, 1, 5660, 176.309, 0.0457068, 0.943274, 'good', -0.592156, '2026-04-17 14:13:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04570676013827324, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.28737619519233704}', 0, 'none', 'stable'),
(909, 237, 2, 5773, 171.258, 0.0600561, 0.961643, 'good', -0.594154, '2026-04-17 14:13:58', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06005609408020973, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.25732338428497314}', 0, 'none', 'stable');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(910, 238, 1, 5111, 176.254, 0.0494508, 0.883071, 'good', -0.53764, '2026-04-17 14:18:53', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04945080727338791, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3191547691822052}', 0, 'none', 'stable'),
(911, 238, 2, 5095, 171.846, 0.0341787, 0.948171, 'good', -0.522989, '2026-04-17 14:18:53', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.034178733825683594, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.260436475276947}', 0, 'none', 'stable'),
(912, 238, 3, 5110, 172.909, 0.0403473, 0.953713, 'good', -0.527323, '2026-04-17 14:18:53', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04034733027219772, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2753121256828308}', 0, 'none', 'stable'),
(913, 239, 1, 6407, 171.893, 0.139905, 0.931772, 'good', -0.649372, '2026-04-17 14:22:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.13990518450737, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3530811071395874}', 0, 'none', 'stable'),
(914, 239, 2, 6123, 171.801, 0.0519683, 0.960144, 'good', -0.620707, '2026-04-17 14:22:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.051968324929475784, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2988887429237366}', 0, 'none', 'stable'),
(915, 239, 3, 6953, 175.668, 0.071611, 0.96431, 'good', -0.661167, '2026-04-17 14:22:41', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07161101698875427, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3063293695449829}', 0, 'none', 'stable'),
(916, 239, 4, 5949, 175.158, 0.0663418, 0.963407, 'good', -0.614448, '2026-04-17 14:22:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06634179502725601, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.32449227571487427}', 0, 'none', 'stable'),
(917, 241, 1, 3340, 171.878, 0.0531412, 0.958312, 'good', -0.299013, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05314123257994652, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(918, 241, 2, 3243, 176.462, 0.0483525, 0.953756, 'good', -0.242975, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.048352498561143875, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.27881917357444763}', 0, 'none', 'stable'),
(919, 241, 3, 3121, 170.194, 0.0510124, 0.95117, 'good', -0.169928, '2026-04-17 15:19:18', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05101244896650314, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2896736264228821}', 0, 'none', 'stable'),
(920, 241, 4, 3802, 175.432, 0.0577307, 0.945127, 'good', -0.333615, '2026-04-17 15:19:18', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05773073807358742, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29392287135124207}', 0, 'none', 'stable'),
(921, 241, 5, 3428, 176.847, 0.0503631, 0.967631, 'good', -0.281351, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05036313831806183, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.34002619981765747}', 0, 'none', 'stable'),
(922, 241, 6, 2996, 170.752, 0.0630619, 0.965305, 'good', -0.151649, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06306187063455582, \"fatigue_index\": 1.1197148511807125, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2704753875732422}', 1.11971, 'none', 'stable'),
(923, 241, 7, 3103, 173.306, 0.0566517, 0.957641, 'good', -0.192686, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05665165930986405, \"fatigue_index\": 2.6441771123144364, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.30926164984703064}', 2.64418, 'none', 'stable'),
(924, 241, 8, 3110, 169.171, 0.0509473, 0.966217, 'good', -0.159628, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05094728246331215, \"fatigue_index\": 0.93986839056015, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.27175864577293396}', 0.939868, 'none', 'stable'),
(925, 241, 9, 3180, 177.409, 0.0515471, 0.96202, 'good', -0.240296, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0515470951795578, \"fatigue_index\": 0.08910770217577618, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2701779901981354}', 0.0891077, 'none', 'stable'),
(926, 241, 10, 8852, 150.958, 0.0860595, 0.676207, 'good', -0.68188, '2026-04-17 15:19:18', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08605946600437164, \"fatigue_index\": 0.08910770217577618, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.3152047395706177}', 0.0891077, 'none', 'stable'),
(927, 241, 11, 887, 171.517, 0.0463207, 0.577639, 'good', -0.0525558, '2026-04-17 15:19:18', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04632065445184707, \"fatigue_index\": 0.08910770217577618, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2852649986743927}', 0.0891077, 'none', 'stable'),
(928, 241, 12, 43333, 136.948, 0.180929, 0.589782, 'good', -0.683567, '2026-04-17 15:19:18', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1809287667274475, \"fatigue_index\": 36.205821530686485, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.4865286648273468}', 36.2058, 'low', 'sharply_rising'),
(929, 242, 1, 790, 148.215, 0.113854, 0.812873, 'good', -0.00962967, '2026-04-17 23:59:50', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1138540506362915, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.4760892689228058}', 0, 'none', 'stable'),
(930, 242, 2, 1882, 169.939, 0.0544247, 0.974584, 'good', -0.00775445, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05442468822002411, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2581796944141388}', 0, 'none', 'stable'),
(931, 242, 3, 2847, 167.152, 0.0662978, 0.98413, 'good', -0.0993059, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06629779934883118, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24920323491096497}', 0, 'none', 'stable'),
(932, 242, 4, 2398, 165.286, 0.0569806, 0.969489, 'good', -0.015712, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.056980643421411514, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2231687754392624}', 0, 'none', 'stable'),
(933, 242, 5, 2239, 161.481, 0.065248, 0.965563, 'good', 0.0240229, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06524800509214401, \"fatigue_index\": 1.0688396589801854, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.24874335527420044}', 1.06884, 'none', 'stable'),
(934, 242, 6, 20037, 175.524, 0.540683, 0.823581, 'good', -0.683567, '2026-04-17 23:59:50', '{\"reasons\": [\"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.540683388710022, \"fatigue_index\": 1.0688396589801854, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.5360112190246582}', 1.06884, 'none', 'stable'),
(935, 242, 7, 2213, 163.85, 0.0452832, 0.945254, 'good', 0.0118892, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04528316482901573, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.232258602976799}', 0, 'none', 'stable'),
(936, 242, 8, 2315, 163.858, 0.0417047, 0.948914, 'good', -0.00138112, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04170474037528038, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.21024030447006223}', 0, 'none', 'stable'),
(937, 242, 9, 12497, 124.547, 0.55, 0.82314, 'bad', -0.683567, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(938, 242, 10, 4036, 125.662, 0.55, 0.809222, 'good', -0.589036, '2026-04-17 23:59:50', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 76.20380007357552, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 10; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 76.2038, 'moderate', 'sharply_rising'),
(939, 242, 11, 1205, 153.291, 0.0277233, 0.933575, 'good', 0.0395924, '2026-04-17 23:59:50', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.02772333100438118, \"fatigue_index\": 76.20380007357552, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 10; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.35076430439949036}', 76.2038, 'moderate', 'sharply_rising'),
(940, 242, 12, 13343, 134.594, 0.16725, 0.870907, 'bad', -0.683567, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.16724954545497894, \"fatigue_index\": 68.26336684778367, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 10; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 68.2634, 'moderate', 'sharply_rising'),
(941, 242, 13, 1965, 119.83, 0.0750551, 0.917286, 'bad', -0.307012, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07505510747432709, \"fatigue_index\": 24.897627184341683, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.7}', 24.8976, 'low', 'sharply_rising'),
(942, 242, 14, 1451, 111.925, 0.0914835, 0.914562, 'bad', -0.396559, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.09148353338241576, \"fatigue_index\": 35.80223561627096, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.7}', 35.8022, 'low', 'sharply_rising'),
(943, 242, 15, 1798, 167.097, 0.0707449, 0.881383, 'good', -0.00979825, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07074487954378128, \"fatigue_index\": 33.06416463158951, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.4847980737686157}', 33.0642, 'low', 'recovering'),
(944, 242, 16, 4861, 167.455, 0.252143, 0.930586, 'bad', -0.567263, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.25214338302612305, \"fatigue_index\": 24.37258804837863, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.6525717973709106}', 24.3726, 'low', 'recovering'),
(945, 242, 17, 3498, 171.338, 0.35268, 0.81984, 'good', -0.401755, '2026-04-17 23:59:50', '{\"reasons\": [\"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.35267961025238037, \"fatigue_index\": 66.08163630432703, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.7}', 66.0816, 'moderate', 'stable'),
(946, 242, 18, 1944, 174.639, 0.0381992, 0.877772, 'good', -0.0717361, '2026-04-17 23:59:50', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03819916397333145, \"fatigue_index\": 66.08163630432703, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 10; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.2787608206272125}', 66.0816, 'moderate', 'sharply_rising'),
(947, 242, 19, 2109, 174.584, 0.0319187, 0.907507, 'good', -0.0879794, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.031918663531541824, \"fatigue_index\": 3.2841761906941733, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2758437395095825}', 3.28418, 'none', 'recovering'),
(948, 242, 20, 2466, 174.018, 0.0596395, 0.911907, 'good', -0.103449, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05963953211903572, \"fatigue_index\": 3.2841761906941733, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.3115767538547516}', 3.28418, 'none', 'recovering'),
(949, 242, 21, 2019, 160.052, 0.0654624, 0.948387, 'good', 0.0500982, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06546242535114288, \"fatigue_index\": 4.460977183447945, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.28935202956199646}', 4.46098, 'none', 'recovering'),
(950, 242, 22, 2001, 159.077, 0.0705763, 0.937241, 'good', 0.053035, '2026-04-17 23:59:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07057633250951767, \"fatigue_index\": 5.1245859099759, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.29500287771224976}', 5.12459, 'none', 'recovering'),
(951, 242, 23, 7622, 169.858, 0.237578, 0.96505, 'bad', -0.679059, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Tempo slowing - stay controlled\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.2375777363777161, \"fatigue_index\": 5.976903769705031, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.5527657866477966}', 5.9769, 'none', 'recovering'),
(952, 242, 24, 4034, 125.87, 0.314154, 0.893681, 'bad', -0.543141, '2026-04-17 23:59:50', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.31415435671806335, \"fatigue_index\": 68, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 10; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 68, 'moderate', 'sharply_rising'),
(953, 243, 1, 2709, 174.27, 0.117339, 0.965091, 'good', -0.175183, '2026-04-18 00:52:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.11733904480934144, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2693043053150177}', 0, 'none', 'stable'),
(954, 243, 2, 2588, 168.762, 0.0505231, 0.993518, 'good', -0.0687728, '2026-04-18 00:52:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05052310973405838, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2466004490852356}', 0, 'none', 'stable'),
(955, 243, 3, 2192, 166.789, 0.0430263, 0.988315, 'good', -0.0110727, '2026-04-18 00:52:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04302629828453064, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.29559090733528137}', 0, 'none', 'stable'),
(956, 243, 4, 2381, 170.259, 0.0383387, 0.989691, 'good', -0.0622567, '2026-04-18 00:52:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03833873942494392, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.26499202847480774}', 0, 'none', 'stable'),
(957, 244, 1, 2250, 173.584, 0.0294798, 0.986472, 'good', -0.0898074, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.029479792341589928, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2263221740722656}', 0, 'none', 'stable'),
(958, 244, 2, 2293, 163.362, 0.0364927, 0.98517, 'good', -0.00013046, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0364927314221859, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.23459288477897644}', 0, 'none', 'stable'),
(959, 244, 3, 2212, 169.261, 0.0315504, 0.990779, 'good', -0.0416841, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03155035898089409, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.23685123026371}', 0, 'none', 'stable'),
(960, 244, 4, 2341, 169.362, 0.035116, 0.991042, 'good', -0.0529185, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.035116009414196014, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2686062157154083}', 0, 'none', 'stable'),
(961, 244, 5, 2277, 168.374, 0.0290195, 0.99266, 'good', -0.0459059, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.02901945821940899, \"fatigue_index\": 3.528331716855367, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2883651554584503}', 3.52833, 'none', 'stable'),
(962, 244, 6, 1926, 167.418, 0.027416, 0.989154, 'good', -0.0114606, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.027416041120886803, \"fatigue_index\": 3.528331716855367, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.2619403600692749}', 3.52833, 'none', 'stable'),
(963, 244, 7, 2106, 165.287, 0.0377816, 0.993449, 'good', 0.0066967, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.037781622260808945, \"fatigue_index\": 2.7876810895072093, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.22720147669315335}', 2.78768, 'none', 'stable'),
(964, 244, 8, 2012, 161.481, 0.0383253, 0.987111, 'good', 0.0375398, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03832532837986946, \"fatigue_index\": 2.0461885465515985, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.24592003226280212}', 2.04619, 'none', 'stable'),
(965, 244, 9, 1932, 167.999, 0.0309281, 0.991962, 'good', -0.0107711, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.030928079038858417, \"fatigue_index\": 1.038543879985809, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.23521924018859863}', 1.03854, 'none', 'stable'),
(966, 244, 10, 2078, 166.234, 0.0300963, 0.995013, 'good', -0.00846756, '2026-04-18 00:53:09', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03009631484746933, \"fatigue_index\": 1.0076446665657892, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.27186018228530884}', 1.00764, 'none', 'stable'),
(967, 244, 11, 2922, 161.575, 0.442454, 0.990503, 'bad', -0.196231, '2026-04-18 00:53:09', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.4424540400505066, \"fatigue_index\": 3.889883557955424, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.4072795808315277}', 3.88988, 'none', 'stable'),
(968, 244, 12, 2093, 130.066, 0.167201, 0.983828, 'bad', -0.246645, '2026-04-18 00:53:09', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.167200967669487, \"fatigue_index\": 38.936483396424194, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.7}', 38.9365, 'low', 'sharply_rising'),
(969, 244, 13, 4975, 134.266, 0.0869894, 0.987986, 'good', -0.525933, '2026-04-18 00:53:09', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08698942512273788, \"fatigue_index\": 56.01010290669224, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 13; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.39085331559181213}', 56.0101, 'moderate', 'sharply_rising'),
(970, 244, 14, 4220, 116.488, 0.070801, 0.982657, 'bad', -0.531217, '2026-04-18 00:53:09', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07080095261335373, \"fatigue_index\": 64.69693681314129, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 13; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 64.6969, 'moderate', 'sharply_rising'),
(971, 244, 15, 2654, 106.69, 0.0631453, 0.977871, 'bad', -0.472716, '2026-04-18 00:53:09', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06314534693956375, \"fatigue_index\": 69.33337005369023, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 13; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 69.3334, 'moderate', 'sharply_rising'),
(972, 245, 1, 2522, 176.847, 0.225704, 0.975121, 'good', -0.264158, '2026-04-18 01:03:27', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.22570393979549408, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.6812340617179871}', 0, 'none', 'stable'),
(973, 245, 2, 5244, 173.512, 0.385672, 0.997891, 'bad', -0.600434, '2026-04-18 01:03:27', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.3856721818447113, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.35852429270744324}', 0, 'none', 'stable'),
(974, 246, 1, 5649, 170.469, 0.099558, 0.999177, 'good', -0.59154, '2026-04-18 02:03:15', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.09955796599388124, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.24851930141448977}', 0, 'none', 'stable'),
(975, 246, 2, 3472, 178.482, 0.0678486, 0.997796, 'good', -0.29991, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06784861534833908, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.19922767579555511}', 0, 'none', 'stable'),
(976, 246, 3, 3739, 176.248, 0.0640513, 0.997765, 'good', -0.327698, '2026-04-18 02:03:15', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06405128538608551, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.20704704523086548}', 0, 'none', 'stable'),
(977, 246, 4, 3103, 175.919, 0.0727902, 0.996587, 'good', -0.218048, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0727902203798294, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.17897729575634003}', 0, 'none', 'stable'),
(978, 246, 5, 2910, 176.584, 0.0743373, 0.996945, 'good', -0.192971, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07433732599020004, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.21286895871162417}', 0, 'none', 'stable'),
(979, 246, 6, 3111, 178.236, 0.0952112, 0.997834, 'good', -0.255153, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0952112227678299, \"fatigue_index\": 0.2578509350617727, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.19600269198417664}', 0.257851, 'none', 'stable'),
(980, 246, 7, 5482, 178.91, 0.0529165, 0.997632, 'good', -0.581625, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0529165156185627, \"fatigue_index\": 0.9047302107016246, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data was limited for this session.\", \"elbow_drift_absmax\": 0.2177097648382187}', 0.90473, 'none', 'stable'),
(981, 246, 8, 4956, 178.988, 0.0651568, 0.998069, 'good', -0.528333, '2026-04-18 02:03:15', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06515681743621826, \"fatigue_index\": 20.403849349206833, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.22770017385482788}', 20.4038, 'low', 'rising'),
(982, 246, 9, 5736, 174.882, 0.0607778, 0.99624, 'good', -0.596478, '2026-04-18 02:03:15', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06077783554792404, \"fatigue_index\": 28.115897125342755, \"fatigue_level\": \"low\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.17046530544757843}', 28.1159, 'low', 'sharply_rising'),
(983, 246, 10, 4482, 177.147, 0.0700509, 0.997297, 'good', -0.45821, '2026-04-18 02:03:15', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.070050910115242, \"fatigue_index\": 19.219102726167588, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.19669662415981293}', 19.2191, 'low', 'rising'),
(984, 246, 11, 4481, 174.143, 0.0479713, 0.998122, 'good', -0.441003, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04797125980257988, \"fatigue_index\": 12.26356352081474, \"fatigue_level\": \"none\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.251213401556015}', 12.2636, 'none', 'rising'),
(985, 246, 12, 3119, 172.871, 0.0680818, 0.998317, 'good', -0.192222, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06808184832334518, \"fatigue_index\": 12.254509482829242, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.18125437200069427}', 12.2545, 'none', 'stable'),
(986, 246, 13, 2630, 172.769, 0.0924802, 0.99807, 'good', -0.129783, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09248021245002748, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.16884514689445496}', 0, 'none', 'recovering'),
(987, 246, 14, 2723, 175.779, 0.0764612, 0.998178, 'good', -0.158822, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07646115124225616, \"fatigue_index\": 0.6118218104044597, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.18840254843235016}', 0.611822, 'none', 'recovering'),
(988, 246, 15, 4333, 179.206, 0.0653753, 0.998179, 'good', -0.444736, '2026-04-18 02:03:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06537530571222305, \"fatigue_index\": 0.6118218104044597, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.24353636801242828}', 0.611822, 'none', 'recovering'),
(989, 247, 1, 7366, 133.953, 0.115644, 0.996409, 'bad', -0.674208, '2026-04-18 02:11:45', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11564362794160844, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(990, 247, 2, 36104, 173.932, 0.34396, 0.994706, 'bad', -0.683567, '2026-04-18 02:11:45', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.3439604341983795, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(991, 247, 3, 647, 89.1982, 0.0650247, 0.995619, 'good', -0.576523, '2026-04-18 02:11:45', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06502466648817062, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.3615623414516449}', 0, 'none', 'stable'),
(992, 247, 4, 6998, 177.12, 0.0937781, 0.99005, 'good', -0.664567, '2026-04-18 02:11:45', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0937781110405922, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.36039090156555176}', 0, 'none', 'stable'),
(993, 248, 1, 655, 0.954675, 0.0467133, 0.992689, 'good', -0.312399, '2026-04-18 02:13:22', '{\"arm\": \"L\", \"reasons\": [\"Stack wrists over elbows (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.3014300465583801}', 0, 'none', 'stable'),
(994, 248, 2, 655, 0.606016, 0.0193872, 0.992961, 'bad', -0.52861, '2026-04-18 02:13:22', '{\"arm\": \"L\", \"reasons\": [\"Wrists not stacked (both)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.4910357594490051}', 0, 'none', 'stable'),
(995, 248, 3, 1226, 0.607687, 1.05052, 0.907738, 'bad', -0.530507, '2026-04-18 02:13:22', '{\"arm\": \"R\", \"reasons\": [\"Keep arms even\", \"Brace core; reduce lean\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 4.452709674835205}', 0, 'none', 'stable'),
(996, 248, 4, 1178, 0.492465, 0.0758258, 0.99781, 'bad', -0.530362, '2026-04-18 02:13:22', '{\"arm\": \"L\", \"reasons\": [\"Keep arms even\", \"Press more evenly\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 0.305330365896225}', 0, 'none', 'stable'),
(997, 248, 5, 283, 0.774894, 0.344591, 0.930229, 'bad', -0.528397, '2026-04-18 02:13:22', '{\"arm\": \"R\", \"reasons\": [\"Avoid leaning / back arch\", \"Brace core; reduce lean\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"wrist_stack_absmax\": 1.1725974082946775}', 0, 'none', 'stable'),
(998, 249, 1, 910, 0.491073, 0.0430243, 0.931033, 'good', -0.111557, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 161.36729431152344, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(999, 249, 2, 310, 0.409147, 0.127812, 0.875849, 'bad', -0.4579, '2026-04-18 02:14:40', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1000, 249, 3, 1919, 5.06534, 14.0106, 0.721301, 'bad', -0.507309, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Avoid leaning / swinging (side-to-side)\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1001, 249, 4, 809, 1.10464, 0.180687, 0.895896, 'bad', -0.507306, '2026-04-18 02:14:40', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 90.79600524902344, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1002, 249, 5, 448, 1.76505, 0.262526, 0.971178, 'bad', -0.507309, '2026-04-18 02:14:40', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 125.29956817626952, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1003, 249, 6, 710, 0.987116, 0.0292706, 0.990634, 'bad', -0.151464, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 163.46009826660156, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1004, 249, 7, 816, 0.926829, 0.0317879, 0.992218, 'good', -0.127729, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 165.37062072753906, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1005, 249, 8, 894, 1.07705, 0.0293131, 0.992572, 'bad', -0.123175, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 167.2659149169922, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1006, 249, 9, 1182, 0.673907, 0.0281776, 0.991608, 'bad', -0.13745, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 169.8516387939453, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(1007, 249, 10, 640, 0.963266, 0.0373653, 0.990485, 'good', -0.215199, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 169.9490203857422, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1008, 249, 11, 762, 0.919261, 0.0268433, 0.989884, 'bad', -0.208561, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 169.8355712890625, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1009, 249, 12, 1027, 1.2085, 0.0629312, 0.989812, 'bad', -0.143903, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"unsafe\", \"elbow_min\": 167.43844604492188, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1010, 249, 13, 750, 4.97681, 1.68977, 0.774686, 'bad', -0.507309, '2026-04-18 02:14:40', '{\"arm\": \"R\", \"reasons\": [\"Avoid leaning / swinging (side-to-side)\"], \"label_ui\": \"unsafe\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\"}', 0, 'none', 'stable'),
(1011, 250, 1, 1609, 148.317, 0.55, 0.916854, 'bad', -0.335476, '2026-04-18 02:15:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(1012, 250, 2, 9109, 107.059, 0.55, 0.867654, 'good', -0.683479, '2026-04-18 02:15:47', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(1013, 250, 3, 24236, 170.641, 0.55, 0.966685, 'bad', -0.683567, '2026-04-18 02:15:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"Consistency drifting (ML)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(1014, 250, 4, 3975, 122.664, 0.55, 0.811095, 'bad', -0.594239, '2026-04-18 02:15:47', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(1015, 251, 1, 852, 95.1842, 0.509877, 0.675962, 'bad', -0.602787, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.5098766088485718, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.7}', 0, 'none', 'stable'),
(1016, 251, 2, 3795, 166.873, 0.0504817, 0.924084, 'good', -0.300252, '2026-04-18 03:46:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.050481703132390976, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.46684783697128296}', 0, 'none', 'stable'),
(1017, 251, 3, 2176, 173.628, 0.0348071, 0.888637, 'good', -0.0783558, '2026-04-18 03:46:55', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.034807104617357254, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.18043184280395508}', 0, 'none', 'stable'),
(1018, 251, 4, 4140, 177.941, 0.0440007, 0.871668, 'good', -0.406182, '2026-04-18 03:46:55', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04400068894028664, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.14857381582260132}', 0, 'none', 'stable'),
(1019, 251, 5, 5041, 171.61, 0.0348744, 0.847957, 'good', -0.514764, '2026-04-18 03:46:55', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03487437590956688, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.17979782819747925}', 0, 'none', 'stable'),
(1020, 251, 6, 3293, 177.633, 0.0363589, 0.888046, 'good', -0.265881, '2026-04-18 03:46:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.03635893017053604, \"fatigue_index\": 2.090257549749596, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.14659523963928223}', 2.09026, 'none', 'stable'),
(1021, 251, 7, 4634, 174.357, 0.0374676, 0.9469, 'good', -0.466098, '2026-04-18 03:46:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0374676026403904, \"fatigue_index\": 8.714248309848857, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.18307262659072876}', 8.71425, 'none', 'stable'),
(1022, 251, 8, 5243, 176.438, 0.0458078, 0.961529, 'good', -0.551586, '2026-04-18 03:46:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.045807838439941406, \"fatigue_index\": 8.899027054824584, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.16227537393569946}', 8.89903, 'none', 'stable'),
(1023, 251, 9, 4021, 177.494, 0.0453365, 0.958878, 'good', -0.382991, '2026-04-18 03:46:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.045336466282606125, \"fatigue_index\": 10.57437081666604, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.21192657947540283}', 10.5744, 'none', 'stable'),
(1024, 251, 10, 4097, 170.035, 0.149338, 0.948819, 'good', -0.421117, '2026-04-18 03:46:55', '{\"reasons\": [\"Keep torso stable\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1493384838104248, \"fatigue_index\": 6.659552204418906, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.25325536727905273}', 6.65955, 'none', 'stable'),
(1025, 251, 11, 14861, 163.277, 0.310567, 0.747012, 'bad', -0.683567, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.310567170381546, \"fatigue_index\": 28.506747299905022, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.5019551515579224}', 28.5067, 'low', 'rising'),
(1026, 251, 12, 8595, 135.327, 0.55, 0.743739, 'bad', -0.682985, '2026-04-18 03:46:55', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 68, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 12; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 68, 'moderate', 'sharply_rising'),
(1027, 251, 13, 2169, 164.016, 0.0806211, 0.913352, 'good', -0.00834291, '2026-04-18 03:46:55', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0806211307644844, \"fatigue_index\": 68, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 12; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.4363625049591065}', 68, 'moderate', 'sharply_rising'),
(1028, 251, 14, 14766, 121.132, 0.55, 0.766284, 'bad', -0.683567, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 74.45374458414132, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 12; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 74.4537, 'moderate', 'sharply_rising'),
(1029, 251, 15, 5119, 165.288, 0.55, 0.830742, 'good', -0.62138, '2026-04-18 03:46:55', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.55, \"fatigue_index\": 55.22169717106895, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 12; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.3464508056640625}', 55.2217, 'moderate', 'sharply_rising'),
(1030, 251, 16, 6479, 148.017, 0.55, 0.841924, 'bad', -0.668536, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Torso sway increasing - stay upright and controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 68, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 12; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.7}', 68, 'moderate', 'sharply_rising'),
(1031, 251, 17, 16506, 137.822, 0.55, 0.862235, 'bad', -0.683567, '2026-04-18 03:46:55', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 68, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.7}', 68, 'moderate', 'stable'),
(1032, 251, 18, 8505, 140.606, 0.55, 0.828724, 'bad', -0.682809, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (left)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.55, \"fatigue_index\": 71.67433486264348, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.6278168559074402}', 71.6743, 'moderate', 'stable'),
(1033, 251, 19, 11198, 173.008, 0.466828, 0.746393, 'bad', -0.683561, '2026-04-18 03:46:55', '{\"reasons\": [\"Avoid torso swinging\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.4668278396129608, \"fatigue_index\": 71.67433486264348, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.5528081655502319}', 71.6743, 'moderate', 'stable'),
(1034, 252, 1, 2232, 178.754, 0.0860046, 0.996073, 'good', -0.138813, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08600460737943649, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.18278510868549347}', 0, 'none', 'stable'),
(1035, 252, 2, 3197, 179.299, 0.099198, 0.99678, 'good', -0.28117, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09919804334640504, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.21754305064678192}', 0, 'none', 'stable'),
(1036, 252, 3, 3530, 179.288, 0.089967, 0.997141, 'good', -0.328292, '2026-04-18 17:56:55', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08996700495481491, \"fatigue_index\": 6.938232550262489, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.19859670102596283}', 6.93823, 'none', 'stable'),
(1037, 252, 4, 3499, 174.995, 0.0975853, 0.996501, 'good', -0.298301, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0975852757692337, \"fatigue_index\": 7.4273150507761025, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.1617203652858734}', 7.42732, 'none', 'stable'),
(1038, 252, 5, 3590, 174.325, 0.0879203, 0.99656, 'good', -0.301358, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08792025595903397, \"fatigue_index\": 8.187091118580492, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.1722586452960968}', 8.18709, 'none', 'stable'),
(1039, 252, 6, 3837, 177.036, 0.0878254, 0.996963, 'good', -0.362139, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08782535791397095, \"fatigue_index\": 13.37191296347308, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.19891810417175293}', 13.3719, 'none', 'stable'),
(1040, 252, 7, 3164, 175.573, 0.0592955, 0.997167, 'good', -0.230238, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.05929550901055336, \"fatigue_index\": 15, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.3886806666851044}', 15, 'low', 'stable'),
(1041, 252, 8, 3033, 175.044, 0.0702424, 0.996233, 'good', -0.201155, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07024240493774414, \"fatigue_index\": 13.54736415669322, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.3431019186973572}', 13.5474, 'none', 'stable'),
(1042, 252, 9, 3352, 176.211, 0.0846206, 0.996661, 'good', -0.269942, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08462061733007431, \"fatigue_index\": 11.574362158090617, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.28758180141448975}', 11.5744, 'none', 'stable'),
(1043, 252, 10, 2872, 174.132, 0.0824745, 0.996508, 'good', -0.172176, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08247445523738861, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.14546547830104828}', 0, 'none', 'stable'),
(1044, 252, 11, 4374, 175.602, 0.0811669, 0.997198, 'good', -0.439974, '2026-04-18 17:56:55', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08116687089204788, \"fatigue_index\": 24.539938410261804, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.1523108333349228}', 24.5399, 'low', 'stable'),
(1045, 252, 12, 8193, 171.957, 0.0662277, 0.997105, 'good', -0.679016, '2026-04-18 17:56:55', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06622769683599472, \"fatigue_index\": 30, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.13152384757995603}', 30, 'low', 'rising'),
(1046, 252, 13, 5440, 168.545, 0.0562912, 0.996828, 'good', -0.557233, '2026-04-18 17:56:55', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05629123374819755, \"fatigue_index\": 30, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.14333833754062653}', 30, 'low', 'rising'),
(1047, 252, 14, 5425, 170.933, 0.0450194, 0.996879, 'good', -0.558979, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.04501944035291672, \"fatigue_index\": 34.350355826318264, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.24500049650669095}', 34.3504, 'low', 'rising'),
(1048, 252, 15, 3605, 167.411, 0.0447656, 0.996974, 'bad', -0.255441, '2026-04-18 17:56:55', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.044765617698431015, \"fatigue_index\": 23.509038349587023, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.38676080107688904}', 23.509, 'low', 'rising'),
(1049, 252, 16, 4847, 172.454, 0.0637797, 0.996367, 'good', -0.491875, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06377971172332764, \"fatigue_index\": 30.282143242657185, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.2016062289476395}', 30.2821, 'low', 'stable'),
(1050, 252, 17, 4248, 175.981, 0.0954132, 0.996242, 'good', -0.429795, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0954132005572319, \"fatigue_index\": 32.61968122905253, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.3040834963321686}', 32.6197, 'low', 'stable'),
(1051, 252, 18, 4901, 168.132, 0.0591099, 0.995745, 'good', -0.488241, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.059109874069690704, \"fatigue_index\": 40.937250684946775, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.31526070833206177}', 40.9373, 'moderate', 'stable'),
(1052, 252, 19, 5962, 172.742, 0.049431, 0.997043, 'good', -0.610097, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.0494309663772583, \"fatigue_index\": 34.055599216371775, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.2418564260005951}', 34.0556, 'low', 'stable'),
(1053, 252, 20, 8126, 171.585, 0.0664659, 0.99769, 'good', -0.678549, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06646592915058136, \"fatigue_index\": 38.81108874455094, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 18; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.2925816476345062}', 38.8111, 'moderate', 'rising'),
(1054, 252, 21, 7336, 172.249, 0.0632946, 0.997792, 'good', -0.668488, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06329461187124252, \"fatigue_index\": 34.61293011903763, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.2478012889623642}', 34.6129, 'low', 'stable'),
(1055, 252, 22, 7081, 172.199, 0.0766623, 0.997957, 'good', -0.664491, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07666226476430893, \"fatigue_index\": 44.99999999999999, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 18; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.47182920575141907}', 45, 'moderate', 'rising'),
(1056, 252, 23, 5117, 175.31, 0.0631014, 0.997758, 'good', -0.536861, '2026-04-18 17:56:55', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06310144066810608, \"fatigue_index\": 40.63057640567422, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.31198951601982117}', 40.6306, 'moderate', 'stable'),
(1057, 252, 24, 4562, 177.881, 0.0670501, 0.997589, 'bad', -0.488559, '2026-04-18 17:56:55', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06705007702112198, \"fatigue_index\": 43.45862595852704, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.5313872694969177}', 43.4586, 'moderate', 'stable'),
(1058, 252, 25, 5682, 174.24, 0.0583795, 0.998268, 'bad', -0.595587, '2026-04-18 17:56:55', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.05837947875261307, \"fatigue_index\": 44.99999999999999, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.4667810797691345}', 45, 'moderate', 'stable'),
(1059, 252, 26, 4822, 157.292, 0.0671661, 0.998264, 'bad', -0.468675, '2026-04-18 17:56:55', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06716611981391907, \"fatigue_index\": 48.02469560915197, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 18; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.45744839310646057}', 48.0247, 'moderate', 'rising'),
(1060, 252, 27, 4674, 166.195, 0.0584215, 0.997531, 'good', -0.449933, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.05842151120305061, \"fatigue_index\": 44.99999999999999, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.3645121455192566}', 45, 'moderate', 'stable'),
(1061, 252, 28, 4636, 168.993, 0.0851881, 0.997364, 'good', -0.464841, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08518814295530319, \"fatigue_index\": 44.995010383452026, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.43024420738220215}', 44.995, 'moderate', 'stable'),
(1062, 252, 29, 4521, 174.924, 0.084379, 0.997876, 'good', -0.460698, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08437903970479965, \"fatigue_index\": 33.981717910153, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.26656049489974976}', 33.9817, 'low', 'stable'),
(1063, 252, 30, 5564, 172.969, 0.0680099, 0.997993, 'good', -0.580872, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06800985336303711, \"fatigue_index\": 44.6161881275475, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.35450270771980286}', 44.6162, 'moderate', 'stable'),
(1064, 252, 31, 5676, 171.351, 0.0765413, 0.997963, 'good', -0.593417, '2026-04-18 17:56:55', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07654128968715668, \"fatigue_index\": 44.99999999999999, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.4679151177406311}', 45, 'moderate', 'stable'),
(1065, 253, 1, 3321, 173.703, 0.0817217, 0.995791, 'good', -0.243101, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08172167092561722, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.18070322275161743}', 0, 'none', 'stable'),
(1066, 253, 2, 2835, 174.759, 0.0815667, 0.994397, 'good', -0.171059, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08156673610210419, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.15171204507350922}', 0, 'none', 'stable'),
(1067, 253, 3, 3477, 172.318, 0.0802373, 0.994338, 'good', -0.262513, '2026-04-18 18:02:38', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08023732155561447, \"fatigue_index\": 5.516151335359007, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.14539834856987}', 5.51615, 'none', 'stable'),
(1068, 253, 4, 3863, 172.399, 0.0917712, 0.996711, 'good', -0.34252, '2026-04-18 18:02:38', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0917711704969406, \"fatigue_index\": 18.31940772924901, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.17310018837451935}', 18.3194, 'low', 'stable'),
(1069, 253, 5, 3659, 168.331, 0.0765965, 0.995994, 'good', -0.270802, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07659654319286346, \"fatigue_index\": 10.370169208897142, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.15563184022903442}', 10.3702, 'none', 'stable'),
(1070, 253, 6, 3784, 170.783, 0.0715778, 0.994565, 'good', -0.305995, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07157780975103378, \"fatigue_index\": 13.136122105816142, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.1454610675573349}', 13.1361, 'low', 'stable'),
(1071, 253, 7, 3489, 170.688, 0.0789804, 0.995875, 'good', -0.253587, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0789804458618164, \"fatigue_index\": 5.80639391821928, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.1390945464372635}', 5.80639, 'none', 'stable'),
(1072, 253, 8, 3207, 169.387, 0.0773517, 0.995064, 'good', -0.190247, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07735171169042587, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.13948920369148254}', 0, 'none', 'stable'),
(1073, 253, 9, 3333, 165.396, 0.0776705, 0.995786, 'good', -0.190954, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07767049968242645, \"fatigue_index\": 2.25748557049015, \"fatigue_level\": \"none\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.1553916186094284}', 2.25749, 'none', 'recovering'),
(1074, 253, 10, 3216, 173.71, 0.0910658, 0.99665, 'good', -0.235309, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09106580913066864, \"fatigue_index\": 1.2665430704752605, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.12581680715084076}', 1.26654, 'none', 'stable'),
(1075, 253, 11, 3545, 169.074, 0.0783211, 0.996895, 'good', -0.253201, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07832114398479462, \"fatigue_index\": 7.969844511901054, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.1605503410100937}', 7.96984, 'none', 'stable'),
(1076, 253, 12, 3418, 171.838, 0.0854074, 0.996797, 'good', -0.249377, '2026-04-18 18:02:38', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08540738373994827, \"fatigue_index\": 9.620983992981738, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2102099061012268}', 9.62098, 'none', 'stable'),
(1077, 253, 13, 6256, 175.288, 0.0931294, 0.997333, 'good', -0.636315, '2026-04-18 18:02:38', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.09312938898801804, \"fatigue_index\": 39.42414689064026, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 13; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.20804812014102936}', 39.4241, 'moderate', 'sharply_rising'),
(1078, 253, 14, 5329, 178.741, 0.0813334, 0.997535, 'good', -0.571827, '2026-04-18 18:02:38', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08133344352245331, \"fatigue_index\": 37.76950844128927, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 13; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.20674483478069303}', 37.7695, 'moderate', 'sharply_rising'),
(1079, 253, 15, 4587, 174.612, 0.0757598, 0.996992, 'good', -0.466245, '2026-04-18 18:02:38', '{\"reasons\": [\"Keep elbow steadier (right)\", \"High fatigue - stop the set or reduce load\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07575982809066772, \"fatigue_index\": 45.9728455344836, \"fatigue_level\": \"high\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"High fatigue detected from around Rep 13; stopping is recommended.\", \"elbow_drift_absmax\": 0.30139872431755066}', 45.9728, 'high', 'sharply_rising'),
(1080, 254, 1, 3989, 170.375, 0.0673934, 0.993684, 'good', -0.339574, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06739343702793121, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.2071649730205536}', 0, 'none', 'stable'),
(1081, 254, 2, 3820, 168.269, 0.0688658, 0.99524, 'good', -0.297492, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06886584311723709, \"fatigue_index\": 0, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Fatigue data is still calibrating.\", \"elbow_drift_absmax\": 0.17295202612876892}', 0, 'none', 'stable'),
(1082, 254, 3, 4086, 167.794, 0.0706702, 0.994369, 'good', -0.349277, '2026-04-18 18:06:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07067020237445831, \"fatigue_index\": 3.886560878667737, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.14785270392894745}', 3.88656, 'none', 'stable'),
(1083, 254, 4, 4114, 169.534, 0.0827962, 0.99535, 'good', -0.368643, '2026-04-18 18:06:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08279615640640259, \"fatigue_index\": 6.089586745685155, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.16192500293254852}', 6.08959, 'none', 'stable'),
(1084, 254, 5, 3847, 168.285, 0.0791341, 0.995349, 'good', -0.310687, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07913411408662796, \"fatigue_index\": 1.3691027959187827, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.13674546778202057}', 1.3691, 'none', 'stable'),
(1085, 254, 6, 3854, 165.176, 0.0784403, 0.994477, 'good', -0.297733, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.0784403458237648, \"fatigue_index\": 1.276600360870361, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.14883077144622803}', 1.2766, 'none', 'stable'),
(1086, 254, 7, 3956, 167.439, 0.0826621, 0.994997, 'good', -0.330953, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08266209810972214, \"fatigue_index\": 2.8031479332085656, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.13336384296417236}', 2.80315, 'none', 'stable'),
(1087, 254, 8, 3701, 163.752, 0.0823536, 0.995413, 'good', -0.264214, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08235356211662292, \"fatigue_index\": 1.7983625332514444, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"No clear fatigue escalation was detected in this session.\", \"elbow_drift_absmax\": 0.14793431758880615}', 1.79836, 'none', 'stable'),
(1088, 254, 9, 6323, 178.771, 0.110606, 0.993775, 'good', -0.645438, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.11060608178377151, \"fatigue_index\": 39.27764006455739, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.18117058277130127}', 39.2776, 'moderate', 'sharply_rising'),
(1089, 254, 10, 4319, 176.594, 0.047019, 0.994685, 'good', -0.426525, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.04701904579997063, \"fatigue_index\": 9.638243207941208, \"fatigue_level\": \"none\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.1863342672586441}', 9.63824, 'none', 'rising'),
(1090, 254, 11, 3817, 173.977, 0.0549735, 0.995472, 'good', -0.32506, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.05497349053621292, \"fatigue_index\": 7.049132188161216, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.2542881667613983}', 7.04913, 'none', 'stable'),
(1091, 254, 12, 3507, 177.201, 0.0774709, 0.994147, 'good', -0.299841, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07747088372707367, \"fatigue_index\": 4.241561591625214, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.20865459740161896}', 4.24156, 'none', 'stable'),
(1092, 254, 13, 4431, 178.236, 0.0728323, 0.994908, 'good', -0.457718, '2026-04-18 18:06:30', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07283227145671844, \"fatigue_index\": 22.071652982626144, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.2970949411392212}', 22.0717, 'low', 'rising'),
(1093, 254, 14, 4323, 177.272, 0.0708206, 0.995731, 'good', -0.437292, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07082061469554901, \"fatigue_index\": 21.82084268743977, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.33484581112861633}', 21.8208, 'low', 'recovering'),
(1094, 254, 15, 3763, 178.22, 0.0679955, 0.994832, 'good', -0.347882, '2026-04-18 18:06:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06799548864364624, \"fatigue_index\": 8.671831885973614, \"fatigue_level\": \"none\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Minor fatigue-related changes were detected, but they did not reach warning level.\", \"elbow_drift_absmax\": 0.27301162481307983}', 8.67183, 'none', 'stable'),
(1095, 254, 16, 4037, 177.475, 0.0753195, 0.994752, 'good', -0.396507, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07531949877738953, \"fatigue_index\": 16.51095941943372, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.3747486472129822}', 16.511, 'low', 'stable'),
(1096, 254, 17, 4704, 177.824, 0.0776838, 0.995972, 'good', -0.495468, '2026-04-18 18:06:30', '{\"reasons\": [\"Early fatigue signs - keep elbows steady and control the rep\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07768375426530838, \"fatigue_index\": 19.984053100152696, \"fatigue_level\": \"low\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Early fatigue signs detected; maintain control and monitor form.\", \"elbow_drift_absmax\": 0.2003571540117264}', 19.9841, 'low', 'rising'),
(1097, 254, 18, 5904, 179.083, 0.0782038, 0.993053, 'good', -0.618102, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07820384204387665, \"fatigue_index\": 44.314808527628585, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.28914135694503784}', 44.3148, 'moderate', 'rising');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`, `fatigue_score`, `fatigue_level`, `fatigue_trend`) VALUES
(1098, 254, 19, 4518, 177.9, 0.0776495, 0.993619, 'good', -0.469679, '2026-04-18 18:06:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07764947414398193, \"fatigue_index\": 16.287580976247167, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.20224575698375705}', 16.2876, 'low', 'stable'),
(1099, 254, 20, 5444, 178.207, 0.0807001, 0.995559, 'good', -0.581213, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.08070013672113419, \"fatigue_index\": 40.34731648713688, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"sharply_rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.25415632128715515}', 40.3473, 'moderate', 'sharply_rising'),
(1100, 254, 21, 6472, 178.612, 0.0684215, 0.992621, 'good', -0.64619, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06842152774333954, \"fatigue_index\": 41.23380331198375, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.2679574489593506}', 41.2338, 'moderate', 'rising'),
(1101, 254, 22, 5952, 179.218, 0.0709218, 0.994944, 'good', -0.620147, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\", \"Consistency drifting (ML)\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07092182338237762, \"fatigue_index\": 41.147533535957336, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.2637989819049835}', 41.1475, 'moderate', 'rising'),
(1102, 254, 23, 5857, 178.732, 0.0682644, 0.995961, 'good', -0.613263, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06826438754796982, \"fatigue_index\": 45.26516167322795, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.31447312235832214}', 45.2652, 'moderate', 'stable'),
(1103, 254, 24, 4291, 178.04, 0.0714628, 0.995528, 'good', -0.438675, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07146284729242325, \"fatigue_index\": 21.234199343704, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.37692099809646606}', 21.2342, 'low', 'stable'),
(1104, 254, 25, 4670, 165.263, 0.0781375, 0.994631, 'bad', -0.459959, '2026-04-18 18:06:30', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.07813754677772522, \"fatigue_index\": 29.976350584297805, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.4601399600505829}', 29.9764, 'low', 'recovering'),
(1105, 254, 26, 5972, 176.345, 0.0844447, 0.996962, 'good', -0.620877, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.08444466441869736, \"fatigue_index\": 48.07717617352804, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.37447911500930786}', 48.0772, 'moderate', 'stable'),
(1106, 254, 27, 6362, 178.77, 0.0655604, 0.99491, 'good', -0.641121, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.06556037068367004, \"fatigue_index\": 34.20595653851827, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.1868669092655182}', 34.206, 'moderate', 'stable'),
(1107, 254, 28, 5792, 176.214, 0.0737498, 0.99546, 'good', -0.605032, '2026-04-18 18:06:30', '{\"reasons\": [\"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.07374976575374603, \"fatigue_index\": 41.755030830701195, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.2664578855037689}', 41.755, 'moderate', 'stable'),
(1108, 254, 29, 8728, 177.072, 0.113802, 0.994876, 'good', -0.682106, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep torso stable\", \"Fatigue rising - prioritize control and consider rest\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11380179971456528, \"fatigue_index\": 48.9592467546463, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"Fatigue has been building since around Rep 9; form may degrade if the set continues.\", \"elbow_drift_absmax\": 0.28796494007110596}', 48.9592, 'moderate', 'rising'),
(1109, 254, 30, 4594, 171.288, 0.133302, 0.994292, 'good', -0.490126, '2026-04-18 18:06:30', '{\"reasons\": [\"Keep torso stable\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.13330213725566864, \"fatigue_index\": 27.574185487062874, \"fatigue_level\": \"low\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.2286866158246994}', 27.5742, 'low', 'stable'),
(1110, 254, 31, 4235, 171.642, 0.102978, 0.993109, 'good', -0.414576, '2026-04-18 18:06:31', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.10297846794128418, \"fatigue_index\": 24.28308271803833, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.3502442538738251}', 24.2831, 'low', 'recovering'),
(1111, 254, 32, 4534, 169.376, 0.113114, 0.996869, 'good', -0.462314, '2026-04-18 18:06:31', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue rising - prioritize control and consider rest\"], \"label_ui\": \"fatigue\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.11311399191617966, \"fatigue_index\": 31.812504911552704, \"fatigue_level\": \"moderate\", \"fatigue_trend\": \"stable\", \"fatigue_summary\": \"Moderate fatigue detected; monitor form closely and consider resting.\", \"elbow_drift_absmax\": 0.34810224175453186}', 31.8125, 'moderate', 'stable'),
(1112, 254, 33, 4704, 168.314, 0.0614479, 0.995582, 'good', -0.457849, '2026-04-18 18:06:31', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"trunk_absmax\": 0.061447933316230774, \"fatigue_index\": 25.66362691336296, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.2793387174606323}', 25.6636, 'low', 'recovering'),
(1113, 254, 34, 4196, 165.537, 0.0636112, 0.990258, 'good', -0.366072, '2026-04-18 18:06:31', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"trunk_absmax\": 0.06361116468906403, \"fatigue_index\": 18.92267529719375, \"fatigue_level\": \"low\", \"fatigue_trend\": \"recovering\", \"fatigue_summary\": \"Low fatigue signs detected, but form remains manageable.\", \"elbow_drift_absmax\": 0.3967595398426056}', 18.9227, 'low', 'recovering'),
(1114, 254, 35, 5250, 148.675, 0.132621, 0.995233, 'bad', -0.568901, '2026-04-18 18:06:31', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep torso stable\", \"High fatigue - stop the set or reduce load\"], \"label_ui\": \"unsafe\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"trunk_absmax\": 0.1326206922531128, \"fatigue_index\": 55.117912978771685, \"fatigue_level\": \"high\", \"fatigue_trend\": \"rising\", \"fatigue_summary\": \"High fatigue detected from around Rep 9; stopping is recommended.\", \"elbow_drift_absmax\": 0.6423595547676086}', 55.1179, 'high', 'rising');

-- --------------------------------------------------------

--
-- Table structure for table `rep_snapshots`
--

CREATE TABLE `rep_snapshots` (
  `snapshot_id` bigint NOT NULL,
  `log_id` bigint NOT NULL,
  `rep_index` int NOT NULL,
  `image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `captured_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rep_snapshots`
--

INSERT INTO `rep_snapshots` (`snapshot_id`, `log_id`, `rep_index`, `image_path`, `captured_at`) VALUES
(1, 170, 1, 'uploads/rep_snapshots/log_170/rep_1.jpg', '2026-04-01 06:04:54'),
(2, 170, 2, 'uploads/rep_snapshots/log_170/rep_2.jpg', '2026-04-01 06:04:56'),
(3, 170, 3, 'uploads/rep_snapshots/log_170/rep_3.jpg', '2026-04-01 06:04:59'),
(4, 172, 1, 'uploads/rep_snapshots/log_172/rep_1.jpg', '2026-04-01 06:11:03'),
(5, 172, 2, 'uploads/rep_snapshots/log_172/rep_2.jpg', '2026-04-01 06:11:06'),
(6, 172, 3, 'uploads/rep_snapshots/log_172/rep_3.jpg', '2026-04-01 06:11:09'),
(7, 172, 4, 'uploads/rep_snapshots/log_172/rep_4.jpg', '2026-04-01 06:11:13'),
(8, 172, 5, 'uploads/rep_snapshots/log_172/rep_5.jpg', '2026-04-01 06:11:16'),
(9, 172, 6, 'uploads/rep_snapshots/log_172/rep_6.jpg', '2026-04-01 06:11:19'),
(10, 173, 1, 'uploads/rep_snapshots/log_173/rep_1.jpg', '2026-04-01 06:11:54'),
(11, 173, 2, 'uploads/rep_snapshots/log_173/rep_2.jpg', '2026-04-01 06:11:58'),
(12, 173, 3, 'uploads/rep_snapshots/log_173/rep_3.jpg', '2026-04-01 06:12:01'),
(13, 173, 4, 'uploads/rep_snapshots/log_173/rep_4.jpg', '2026-04-01 06:12:04'),
(14, 173, 5, 'uploads/rep_snapshots/log_173/rep_5.jpg', '2026-04-01 06:12:07'),
(15, 173, 6, 'uploads/rep_snapshots/log_173/rep_6.jpg', '2026-04-01 06:12:11'),
(16, 173, 7, 'uploads/rep_snapshots/log_173/rep_7.jpg', '2026-04-01 06:12:15'),
(17, 173, 8, 'uploads/rep_snapshots/log_173/rep_8.jpg', '2026-04-01 06:12:18'),
(18, 173, 9, 'uploads/rep_snapshots/log_173/rep_9.jpg', '2026-04-01 06:12:21'),
(19, 173, 10, 'uploads/rep_snapshots/log_173/rep_10.jpg', '2026-04-01 06:12:24'),
(20, 174, 1, 'uploads/rep_snapshots/log_174/rep_1.jpg', '2026-04-01 06:27:44'),
(21, 174, 2, 'uploads/rep_snapshots/log_174/rep_2.jpg', '2026-04-01 06:27:47'),
(22, 174, 3, 'uploads/rep_snapshots/log_174/rep_3.jpg', '2026-04-01 06:27:49'),
(23, 174, 4, 'uploads/rep_snapshots/log_174/rep_4.jpg', '2026-04-01 06:27:52'),
(24, 174, 5, 'uploads/rep_snapshots/log_174/rep_5.jpg', '2026-04-01 06:27:55'),
(25, 174, 6, 'uploads/rep_snapshots/log_174/rep_6.jpg', '2026-04-01 06:27:58'),
(26, 174, 7, 'uploads/rep_snapshots/log_174/rep_7.jpg', '2026-04-01 06:28:01'),
(28, 174, 8, 'uploads/rep_snapshots/log_174/rep_8.jpg', '2026-04-01 06:28:04'),
(29, 174, 9, 'uploads/rep_snapshots/log_174/rep_9.jpg', '2026-04-01 06:28:06'),
(32, 174, 10, 'uploads/rep_snapshots/log_174/rep_10.jpg', '2026-04-01 06:28:09'),
(34, 174, 11, 'uploads/rep_snapshots/log_174/rep_11.jpg', '2026-04-01 06:28:11'),
(35, 179, 1, 'uploads/rep_snapshots/log_179/rep_1.jpg', '2026-04-06 08:11:48'),
(36, 179, 2, 'uploads/rep_snapshots/log_179/rep_2.jpg', '2026-04-06 08:11:53'),
(37, 179, 3, 'uploads/rep_snapshots/log_179/rep_3.jpg', '2026-04-06 08:11:58'),
(38, 180, 1, 'uploads/rep_snapshots/log_180/rep_1.jpg', '2026-04-06 08:27:10'),
(39, 180, 2, 'uploads/rep_snapshots/log_180/rep_2.jpg', '2026-04-06 08:27:14'),
(40, 180, 3, 'uploads/rep_snapshots/log_180/rep_3.jpg', '2026-04-06 08:27:18'),
(41, 180, 4, 'uploads/rep_snapshots/log_180/rep_4.jpg', '2026-04-06 08:27:21'),
(42, 180, 5, 'uploads/rep_snapshots/log_180/rep_5.jpg', '2026-04-06 08:27:25'),
(43, 180, 6, 'uploads/rep_snapshots/log_180/rep_6.jpg', '2026-04-06 08:27:30'),
(44, 180, 7, 'uploads/rep_snapshots/log_180/rep_7.jpg', '2026-04-06 08:27:35'),
(45, 180, 8, 'uploads/rep_snapshots/log_180/rep_8.jpg', '2026-04-06 08:27:41'),
(46, 180, 9, 'uploads/rep_snapshots/log_180/rep_9.jpg', '2026-04-06 08:27:46'),
(47, 180, 10, 'uploads/rep_snapshots/log_180/rep_10.jpg', '2026-04-06 08:27:50'),
(48, 180, 11, 'uploads/rep_snapshots/log_180/rep_11.jpg', '2026-04-06 08:27:54'),
(49, 181, 1, 'uploads/rep_snapshots/log_181/rep_1.jpg', '2026-04-08 03:31:43'),
(50, 181, 2, 'uploads/rep_snapshots/log_181/rep_2.jpg', '2026-04-08 03:31:48'),
(51, 181, 3, 'uploads/rep_snapshots/log_181/rep_3.jpg', '2026-04-08 03:31:54'),
(53, 182, 1, 'uploads/rep_snapshots/log_182/rep_1.jpg', '2026-04-08 09:35:43'),
(54, 182, 2, 'uploads/rep_snapshots/log_182/rep_2.jpg', '2026-04-08 09:35:47'),
(55, 182, 3, 'uploads/rep_snapshots/log_182/rep_3.jpg', '2026-04-08 09:35:50'),
(56, 182, 4, 'uploads/rep_snapshots/log_182/rep_4.jpg', '2026-04-08 09:35:54'),
(57, 182, 5, 'uploads/rep_snapshots/log_182/rep_5.jpg', '2026-04-08 09:35:58'),
(58, 182, 6, 'uploads/rep_snapshots/log_182/rep_6.jpg', '2026-04-08 09:36:02'),
(59, 182, 7, 'uploads/rep_snapshots/log_182/rep_7.jpg', '2026-04-08 09:36:04'),
(60, 182, 8, 'uploads/rep_snapshots/log_182/rep_8.jpg', '2026-04-08 09:36:13'),
(62, 182, 9, 'uploads/rep_snapshots/log_182/rep_9.jpg', '2026-04-08 09:36:17'),
(63, 182, 10, 'uploads/rep_snapshots/log_182/rep_10.jpg', '2026-04-08 09:36:20'),
(94, 190, 1, 'uploads/rep_snapshots/log_190/rep_1.jpg', '2026-04-09 12:52:33'),
(95, 190, 2, 'uploads/rep_snapshots/log_190/rep_2.jpg', '2026-04-09 12:52:36'),
(96, 190, 3, 'uploads/rep_snapshots/log_190/rep_3.jpg', '2026-04-09 12:52:39'),
(97, 190, 4, 'uploads/rep_snapshots/log_190/rep_4.jpg', '2026-04-09 12:52:42'),
(98, 190, 5, 'uploads/rep_snapshots/log_190/rep_5.jpg', '2026-04-09 12:52:45'),
(99, 190, 6, 'uploads/rep_snapshots/log_190/rep_6.jpg', '2026-04-09 12:52:48'),
(100, 191, 1, 'uploads/rep_snapshots/log_191/rep_1.jpg', '2026-04-09 13:09:16'),
(101, 191, 2, 'uploads/rep_snapshots/log_191/rep_2.jpg', '2026-04-09 13:09:39'),
(102, 191, 3, 'uploads/rep_snapshots/log_191/rep_3.jpg', '2026-04-09 13:09:44'),
(103, 192, 1, 'uploads/rep_snapshots/log_192/rep_1.jpg', '2026-04-09 14:10:34'),
(106, 192, 2, 'uploads/rep_snapshots/log_192/rep_2.jpg', '2026-04-09 14:10:36'),
(108, 192, 3, 'uploads/rep_snapshots/log_192/rep_3.jpg', '2026-04-09 14:10:39'),
(112, 192, 4, 'uploads/rep_snapshots/log_192/rep_4.jpg', '2026-04-09 14:10:42'),
(118, 192, 5, 'uploads/rep_snapshots/log_192/rep_5.jpg', '2026-04-09 14:10:44'),
(121, 192, 6, 'uploads/rep_snapshots/log_192/rep_6.jpg', '2026-04-09 14:10:47'),
(124, 192, 7, 'uploads/rep_snapshots/log_192/rep_7.jpg', '2026-04-09 14:10:53'),
(127, 192, 8, 'uploads/rep_snapshots/log_192/rep_8.jpg', '2026-04-09 14:10:57'),
(130, 193, 1, 'uploads/rep_snapshots/log_193/rep_1.jpg', '2026-04-09 16:30:06'),
(133, 193, 2, 'uploads/rep_snapshots/log_193/rep_2.jpg', '2026-04-09 16:30:14'),
(136, 193, 3, 'uploads/rep_snapshots/log_193/rep_3.jpg', '2026-04-09 16:30:20'),
(139, 193, 4, 'uploads/rep_snapshots/log_193/rep_4.jpg', '2026-04-09 16:30:24'),
(141, 193, 5, 'uploads/rep_snapshots/log_193/rep_5.jpg', '2026-04-09 16:30:30'),
(143, 193, 6, 'uploads/rep_snapshots/log_193/rep_6.jpg', '2026-04-09 16:30:56'),
(148, 194, 1, 'uploads/rep_snapshots/log_194/rep_1.jpg', '2026-04-09 16:33:22'),
(149, 194, 2, 'uploads/rep_snapshots/log_194/rep_2.jpg', '2026-04-09 16:33:30'),
(151, 194, 3, 'uploads/rep_snapshots/log_194/rep_3.jpg', '2026-04-09 16:33:36'),
(155, 194, 4, 'uploads/rep_snapshots/log_194/rep_4.jpg', '2026-04-09 16:33:42'),
(157, 194, 5, 'uploads/rep_snapshots/log_194/rep_5.jpg', '2026-04-09 16:33:46'),
(158, 194, 6, 'uploads/rep_snapshots/log_194/rep_6.jpg', '2026-04-09 16:33:52'),
(160, 194, 7, 'uploads/rep_snapshots/log_194/rep_7.jpg', '2026-04-09 16:33:59'),
(162, 194, 8, 'uploads/rep_snapshots/log_194/rep_8.jpg', '2026-04-09 16:34:05'),
(164, 194, 9, 'uploads/rep_snapshots/log_194/rep_9.jpg', '2026-04-09 16:34:09'),
(166, 194, 10, 'uploads/rep_snapshots/log_194/rep_10.jpg', '2026-04-09 16:34:15'),
(168, 194, 11, 'uploads/rep_snapshots/log_194/rep_11.jpg', '2026-04-09 16:34:20'),
(169, 195, 1, 'uploads/rep_snapshots/log_195/rep_1.jpg', '2026-04-11 01:50:17'),
(172, 195, 2, 'uploads/rep_snapshots/log_195/rep_2.jpg', '2026-04-11 01:50:19'),
(174, 195, 3, 'uploads/rep_snapshots/log_195/rep_3.jpg', '2026-04-11 01:50:23'),
(178, 195, 4, 'uploads/rep_snapshots/log_195/rep_4.jpg', '2026-04-11 01:50:25'),
(181, 195, 5, 'uploads/rep_snapshots/log_195/rep_5.jpg', '2026-04-11 01:50:27'),
(184, 196, 1, 'uploads/rep_snapshots/log_196/rep_1.jpg', '2026-04-13 02:18:01'),
(187, 196, 2, 'uploads/rep_snapshots/log_196/rep_2.jpg', '2026-04-13 02:18:04'),
(190, 196, 3, 'uploads/rep_snapshots/log_196/rep_3.jpg', '2026-04-13 02:18:06'),
(196, 196, 4, 'uploads/rep_snapshots/log_196/rep_4.jpg', '2026-04-13 02:18:11'),
(202, 196, 5, 'uploads/rep_snapshots/log_196/rep_5.jpg', '2026-04-13 02:18:14'),
(208, 196, 6, 'uploads/rep_snapshots/log_196/rep_6.jpg', '2026-04-13 02:18:18'),
(211, 197, 1, 'uploads/rep_snapshots/log_197/rep_1.jpg', '2026-04-13 02:22:42'),
(213, 197, 2, 'uploads/rep_snapshots/log_197/rep_2.jpg', '2026-04-13 02:22:50'),
(219, 197, 3, 'uploads/rep_snapshots/log_197/rep_3.jpg', '2026-04-13 02:22:55'),
(222, 197, 4, 'uploads/rep_snapshots/log_197/rep_4.jpg', '2026-04-13 02:22:58'),
(225, 197, 5, 'uploads/rep_snapshots/log_197/rep_5.jpg', '2026-04-13 02:23:03'),
(231, 197, 6, 'uploads/rep_snapshots/log_197/rep_6.jpg', '2026-04-13 02:23:04'),
(234, 198, 1, 'uploads/rep_snapshots/log_198/rep_1.jpg', '2026-04-13 02:24:06'),
(237, 198, 2, 'uploads/rep_snapshots/log_198/rep_2.jpg', '2026-04-13 02:24:09'),
(240, 198, 3, 'uploads/rep_snapshots/log_198/rep_3.jpg', '2026-04-13 02:24:12'),
(243, 198, 4, 'uploads/rep_snapshots/log_198/rep_4.jpg', '2026-04-13 02:24:16'),
(246, 198, 5, 'uploads/rep_snapshots/log_198/rep_5.jpg', '2026-04-13 02:24:19'),
(247, 198, 6, 'uploads/rep_snapshots/log_198/rep_6.jpg', '2026-04-13 02:24:22'),
(250, 198, 7, 'uploads/rep_snapshots/log_198/rep_7.jpg', '2026-04-13 02:24:25'),
(251, 198, 8, 'uploads/rep_snapshots/log_198/rep_8.jpg', '2026-04-13 02:24:27'),
(254, 198, 9, 'uploads/rep_snapshots/log_198/rep_9.jpg', '2026-04-13 02:24:29'),
(257, 198, 10, 'uploads/rep_snapshots/log_198/rep_10.jpg', '2026-04-13 02:24:33'),
(260, 199, 1, 'uploads/rep_snapshots/log_199/rep_1.jpg', '2026-04-13 02:24:50'),
(263, 200, 1, 'uploads/rep_snapshots/log_200/rep_1.jpg', '2026-04-15 13:40:34'),
(265, 200, 2, 'uploads/rep_snapshots/log_200/rep_2.jpg', '2026-04-15 13:40:38'),
(267, 200, 3, 'uploads/rep_snapshots/log_200/rep_3.jpg', '2026-04-15 13:40:42'),
(270, 200, 4, 'uploads/rep_snapshots/log_200/rep_4.jpg', '2026-04-15 13:40:46'),
(271, 201, 1, 'uploads/rep_snapshots/log_201/rep_1.jpg', '2026-04-15 13:43:19'),
(272, 201, 2, 'uploads/rep_snapshots/log_201/rep_2.jpg', '2026-04-15 13:43:23'),
(275, 201, 3, 'uploads/rep_snapshots/log_201/rep_3.jpg', '2026-04-15 13:43:44'),
(278, 201, 4, 'uploads/rep_snapshots/log_201/rep_4.jpg', '2026-04-15 13:43:47'),
(281, 201, 5, 'uploads/rep_snapshots/log_201/rep_5.jpg', '2026-04-15 13:43:53'),
(283, 201, 6, 'uploads/rep_snapshots/log_201/rep_6.jpg', '2026-04-15 13:43:56'),
(286, 202, 1, 'uploads/rep_snapshots/log_202/rep_1.jpg', '2026-04-16 09:08:25'),
(291, 202, 2, 'uploads/rep_snapshots/log_202/rep_2.jpg', '2026-04-16 09:08:28'),
(293, 202, 3, 'uploads/rep_snapshots/log_202/rep_3.jpg', '2026-04-16 09:08:36'),
(298, 202, 4, 'uploads/rep_snapshots/log_202/rep_4.jpg', '2026-04-16 09:08:44'),
(301, 202, 5, 'uploads/rep_snapshots/log_202/rep_5.jpg', '2026-04-16 09:08:47'),
(307, 202, 6, 'uploads/rep_snapshots/log_202/rep_6.jpg', '2026-04-16 09:08:56'),
(310, 202, 7, 'uploads/rep_snapshots/log_202/rep_7.jpg', '2026-04-16 09:09:03'),
(313, 202, 8, 'uploads/rep_snapshots/log_202/rep_8.jpg', '2026-04-16 09:09:07'),
(318, 203, 1, 'uploads/rep_snapshots/log_203/rep_1.jpg', '2026-04-17 10:30:57'),
(326, 203, 2, 'uploads/rep_snapshots/log_203/rep_2.jpg', '2026-04-17 10:31:04'),
(327, 203, 3, 'uploads/rep_snapshots/log_203/rep_3.jpg', '2026-04-17 10:31:07'),
(329, 203, 4, 'uploads/rep_snapshots/log_203/rep_4.jpg', '2026-04-17 10:31:10'),
(333, 203, 5, 'uploads/rep_snapshots/log_203/rep_5.jpg', '2026-04-17 10:31:12'),
(335, 203, 6, 'uploads/rep_snapshots/log_203/rep_6.jpg', '2026-04-17 10:31:14'),
(337, 203, 7, 'uploads/rep_snapshots/log_203/rep_7.jpg', '2026-04-17 10:31:19'),
(341, 204, 1, 'uploads/rep_snapshots/log_204/rep_1.jpg', '2026-04-17 10:35:26'),
(342, 205, 1, 'uploads/rep_snapshots/log_205/rep_1.jpg', '2026-04-17 10:35:54'),
(344, 205, 2, 'uploads/rep_snapshots/log_205/rep_2.jpg', '2026-04-17 10:35:56'),
(346, 205, 3, 'uploads/rep_snapshots/log_205/rep_3.jpg', '2026-04-17 10:35:59'),
(349, 205, 4, 'uploads/rep_snapshots/log_205/rep_4.jpg', '2026-04-17 10:36:03'),
(351, 205, 5, 'uploads/rep_snapshots/log_205/rep_5.jpg', '2026-04-17 10:36:06'),
(353, 205, 6, 'uploads/rep_snapshots/log_205/rep_6.jpg', '2026-04-17 10:36:09'),
(354, 205, 7, 'uploads/rep_snapshots/log_205/rep_7.jpg', '2026-04-17 10:36:15'),
(355, 205, 8, 'uploads/rep_snapshots/log_205/rep_8.jpg', '2026-04-17 10:36:18'),
(357, 206, 1, 'uploads/rep_snapshots/log_206/rep_1.jpg', '2026-04-17 10:53:41'),
(359, 206, 2, 'uploads/rep_snapshots/log_206/rep_2.jpg', '2026-04-17 10:53:44'),
(361, 206, 3, 'uploads/rep_snapshots/log_206/rep_3.jpg', '2026-04-17 10:53:48'),
(362, 206, 4, 'uploads/rep_snapshots/log_206/rep_4.jpg', '2026-04-17 10:53:51'),
(363, 206, 5, 'uploads/rep_snapshots/log_206/rep_5.jpg', '2026-04-17 10:53:55'),
(364, 206, 6, 'uploads/rep_snapshots/log_206/rep_6.jpg', '2026-04-17 10:54:00'),
(368, 206, 7, 'uploads/rep_snapshots/log_206/rep_7.jpg', '2026-04-17 10:54:02'),
(370, 206, 8, 'uploads/rep_snapshots/log_206/rep_8.jpg', '2026-04-17 10:54:05'),
(371, 207, 1, 'uploads/rep_snapshots/log_207/rep_1.jpg', '2026-04-17 10:56:50'),
(372, 207, 2, 'uploads/rep_snapshots/log_207/rep_2.jpg', '2026-04-17 10:56:54'),
(373, 207, 3, 'uploads/rep_snapshots/log_207/rep_3.jpg', '2026-04-17 10:56:59'),
(374, 207, 4, 'uploads/rep_snapshots/log_207/rep_4.jpg', '2026-04-17 10:57:05'),
(377, 207, 5, 'uploads/rep_snapshots/log_207/rep_5.jpg', '2026-04-17 10:57:08'),
(378, 207, 6, 'uploads/rep_snapshots/log_207/rep_6.jpg', '2026-04-17 10:57:18'),
(380, 208, 1, 'uploads/rep_snapshots/log_208/rep_1.jpg', '2026-04-17 11:01:23'),
(381, 208, 2, 'uploads/rep_snapshots/log_208/rep_2.jpg', '2026-04-17 11:01:26'),
(382, 208, 3, 'uploads/rep_snapshots/log_208/rep_3.jpg', '2026-04-17 11:01:27'),
(383, 209, 1, 'uploads/rep_snapshots/log_209/rep_1.jpg', '2026-04-17 11:04:21'),
(384, 209, 2, 'uploads/rep_snapshots/log_209/rep_2.jpg', '2026-04-17 11:04:26'),
(386, 209, 3, 'uploads/rep_snapshots/log_209/rep_3.jpg', '2026-04-17 11:04:31'),
(387, 209, 4, 'uploads/rep_snapshots/log_209/rep_4.jpg', '2026-04-17 11:04:36'),
(391, 209, 5, 'uploads/rep_snapshots/log_209/rep_5.jpg', '2026-04-17 11:04:41'),
(396, 209, 6, 'uploads/rep_snapshots/log_209/rep_6.jpg', '2026-04-17 11:06:29'),
(399, 209, 7, 'uploads/rep_snapshots/log_209/rep_7.jpg', '2026-04-17 11:06:32'),
(402, 209, 8, 'uploads/rep_snapshots/log_209/rep_8.jpg', '2026-04-17 11:06:33'),
(405, 209, 9, 'uploads/rep_snapshots/log_209/rep_9.jpg', '2026-04-17 11:06:35'),
(406, 209, 10, 'uploads/rep_snapshots/log_209/rep_10.jpg', '2026-04-17 11:06:36'),
(408, 209, 11, 'uploads/rep_snapshots/log_209/rep_11.jpg', '2026-04-17 11:06:38'),
(411, 209, 12, 'uploads/rep_snapshots/log_209/rep_12.jpg', '2026-04-17 11:06:39'),
(413, 209, 13, 'uploads/rep_snapshots/log_209/rep_13.jpg', '2026-04-17 11:06:41'),
(415, 209, 14, 'uploads/rep_snapshots/log_209/rep_14.jpg', '2026-04-17 11:06:43'),
(418, 209, 15, 'uploads/rep_snapshots/log_209/rep_15.jpg', '2026-04-17 11:06:48'),
(421, 209, 16, 'uploads/rep_snapshots/log_209/rep_16.jpg', '2026-04-17 11:07:22'),
(424, 209, 17, 'uploads/rep_snapshots/log_209/rep_17.jpg', '2026-04-17 11:07:26'),
(426, 209, 18, 'uploads/rep_snapshots/log_209/rep_18.jpg', '2026-04-17 11:07:28'),
(428, 210, 1, 'uploads/rep_snapshots/log_210/rep_1.jpg', '2026-04-17 11:09:09'),
(429, 210, 2, 'uploads/rep_snapshots/log_210/rep_2.jpg', '2026-04-17 11:09:10'),
(431, 210, 3, 'uploads/rep_snapshots/log_210/rep_3.jpg', '2026-04-17 11:09:48'),
(434, 210, 4, 'uploads/rep_snapshots/log_210/rep_4.jpg', '2026-04-17 11:09:54'),
(437, 210, 5, 'uploads/rep_snapshots/log_210/rep_5.jpg', '2026-04-17 11:09:56'),
(439, 210, 6, 'uploads/rep_snapshots/log_210/rep_6.jpg', '2026-04-17 11:10:00'),
(442, 210, 7, 'uploads/rep_snapshots/log_210/rep_7.jpg', '2026-04-17 11:10:02'),
(445, 210, 8, 'uploads/rep_snapshots/log_210/rep_8.jpg', '2026-04-17 11:10:03'),
(448, 210, 9, 'uploads/rep_snapshots/log_210/rep_9.jpg', '2026-04-17 11:10:05'),
(454, 211, 1, 'uploads/rep_snapshots/log_211/rep_1.jpg', '2026-04-17 11:12:42'),
(456, 211, 2, 'uploads/rep_snapshots/log_211/rep_2.jpg', '2026-04-17 11:12:46'),
(459, 211, 3, 'uploads/rep_snapshots/log_211/rep_3.jpg', '2026-04-17 11:12:48'),
(461, 211, 4, 'uploads/rep_snapshots/log_211/rep_4.jpg', '2026-04-17 11:12:52'),
(462, 211, 5, 'uploads/rep_snapshots/log_211/rep_5.jpg', '2026-04-17 11:12:56'),
(466, 211, 6, 'uploads/rep_snapshots/log_211/rep_6.jpg', '2026-04-17 11:12:58'),
(469, 211, 7, 'uploads/rep_snapshots/log_211/rep_7.jpg', '2026-04-17 11:13:01'),
(473, 212, 1, 'uploads/rep_snapshots/log_212/rep_1.jpg', '2026-04-17 11:16:10'),
(477, 212, 2, 'uploads/rep_snapshots/log_212/rep_2.jpg', '2026-04-17 11:16:15'),
(480, 213, 1, 'uploads/rep_snapshots/log_213/rep_1.jpg', '2026-04-17 11:17:46'),
(481, 215, 1, 'uploads/rep_snapshots/log_215/rep_1.jpg', '2026-04-17 11:19:11'),
(484, 215, 2, 'uploads/rep_snapshots/log_215/rep_2.jpg', '2026-04-17 11:19:14'),
(486, 215, 3, 'uploads/rep_snapshots/log_215/rep_3.jpg', '2026-04-17 11:19:16'),
(488, 215, 4, 'uploads/rep_snapshots/log_215/rep_4.jpg', '2026-04-17 11:19:29'),
(491, 215, 5, 'uploads/rep_snapshots/log_215/rep_5.jpg', '2026-04-17 11:19:51'),
(494, 216, 1, 'uploads/rep_snapshots/log_216/rep_1.jpg', '2026-04-17 11:22:47'),
(497, 217, 1, 'uploads/rep_snapshots/log_217/rep_1.jpg', '2026-04-17 11:23:11'),
(500, 217, 2, 'uploads/rep_snapshots/log_217/rep_2.jpg', '2026-04-17 11:23:14'),
(503, 217, 3, 'uploads/rep_snapshots/log_217/rep_3.jpg', '2026-04-17 11:23:16'),
(504, 217, 4, 'uploads/rep_snapshots/log_217/rep_4.jpg', '2026-04-17 11:23:19'),
(506, 217, 5, 'uploads/rep_snapshots/log_217/rep_5.jpg', '2026-04-17 11:23:22'),
(508, 217, 6, 'uploads/rep_snapshots/log_217/rep_6.jpg', '2026-04-17 11:23:24'),
(511, 217, 7, 'uploads/rep_snapshots/log_217/rep_7.jpg', '2026-04-17 11:23:27'),
(514, 217, 8, 'uploads/rep_snapshots/log_217/rep_8.jpg', '2026-04-17 11:23:29'),
(517, 217, 9, 'uploads/rep_snapshots/log_217/rep_9.jpg', '2026-04-17 11:23:31'),
(520, 217, 10, 'uploads/rep_snapshots/log_217/rep_10.jpg', '2026-04-17 11:23:33'),
(523, 217, 11, 'uploads/rep_snapshots/log_217/rep_11.jpg', '2026-04-17 11:23:35'),
(524, 217, 12, 'uploads/rep_snapshots/log_217/rep_12.jpg', '2026-04-17 11:23:39'),
(527, 218, 1, 'uploads/rep_snapshots/log_218/rep_1.jpg', '2026-04-17 11:30:07'),
(530, 218, 2, 'uploads/rep_snapshots/log_218/rep_2.jpg', '2026-04-17 11:30:11'),
(533, 218, 3, 'uploads/rep_snapshots/log_218/rep_3.jpg', '2026-04-17 11:30:13'),
(536, 218, 4, 'uploads/rep_snapshots/log_218/rep_4.jpg', '2026-04-17 11:30:15'),
(539, 218, 5, 'uploads/rep_snapshots/log_218/rep_5.jpg', '2026-04-17 11:30:19'),
(542, 218, 6, 'uploads/rep_snapshots/log_218/rep_6.jpg', '2026-04-17 11:30:21'),
(545, 218, 7, 'uploads/rep_snapshots/log_218/rep_7.jpg', '2026-04-17 11:30:24'),
(547, 218, 8, 'uploads/rep_snapshots/log_218/rep_8.jpg', '2026-04-17 11:30:27'),
(550, 218, 9, 'uploads/rep_snapshots/log_218/rep_9.jpg', '2026-04-17 11:30:29'),
(553, 218, 10, 'uploads/rep_snapshots/log_218/rep_10.jpg', '2026-04-17 11:30:32'),
(556, 218, 11, 'uploads/rep_snapshots/log_218/rep_11.jpg', '2026-04-17 11:30:34'),
(559, 218, 12, 'uploads/rep_snapshots/log_218/rep_12.jpg', '2026-04-17 11:30:37'),
(561, 218, 13, 'uploads/rep_snapshots/log_218/rep_13.jpg', '2026-04-17 11:30:39'),
(564, 218, 14, 'uploads/rep_snapshots/log_218/rep_14.jpg', '2026-04-17 11:30:41'),
(565, 218, 15, 'uploads/rep_snapshots/log_218/rep_15.jpg', '2026-04-17 11:30:44'),
(568, 218, 16, 'uploads/rep_snapshots/log_218/rep_16.jpg', '2026-04-17 11:30:46'),
(570, 218, 17, 'uploads/rep_snapshots/log_218/rep_17.jpg', '2026-04-17 11:30:48'),
(571, 218, 18, 'uploads/rep_snapshots/log_218/rep_18.jpg', '2026-04-17 11:30:51'),
(574, 218, 19, 'uploads/rep_snapshots/log_218/rep_19.jpg', '2026-04-17 11:30:52'),
(576, 218, 20, 'uploads/rep_snapshots/log_218/rep_20.jpg', '2026-04-17 11:30:56'),
(579, 218, 21, 'uploads/rep_snapshots/log_218/rep_21.jpg', '2026-04-17 11:30:59'),
(583, 218, 22, 'uploads/rep_snapshots/log_218/rep_22.jpg', '2026-04-17 11:31:01'),
(588, 218, 23, 'uploads/rep_snapshots/log_218/rep_23.jpg', '2026-04-17 11:31:04'),
(592, 218, 24, 'uploads/rep_snapshots/log_218/rep_24.jpg', '2026-04-17 11:31:06'),
(594, 218, 25, 'uploads/rep_snapshots/log_218/rep_25.jpg', '2026-04-17 11:31:09'),
(598, 218, 26, 'uploads/rep_snapshots/log_218/rep_26.jpg', '2026-04-17 11:31:10'),
(601, 219, 1, 'uploads/rep_snapshots/log_219/rep_1.jpg', '2026-04-17 11:36:23'),
(604, 219, 2, 'uploads/rep_snapshots/log_219/rep_2.jpg', '2026-04-17 11:36:24'),
(605, 219, 3, 'uploads/rep_snapshots/log_219/rep_3.jpg', '2026-04-17 11:36:34'),
(607, 220, 1, 'uploads/rep_snapshots/log_220/rep_1.jpg', '2026-04-17 11:37:22'),
(609, 220, 2, 'uploads/rep_snapshots/log_220/rep_2.jpg', '2026-04-17 11:37:28'),
(614, 220, 3, 'uploads/rep_snapshots/log_220/rep_3.jpg', '2026-04-17 11:37:35'),
(621, 220, 4, 'uploads/rep_snapshots/log_220/rep_4.jpg', '2026-04-17 11:37:37'),
(624, 220, 5, 'uploads/rep_snapshots/log_220/rep_5.jpg', '2026-04-17 11:37:42'),
(629, 220, 6, 'uploads/rep_snapshots/log_220/rep_6.jpg', '2026-04-17 11:37:46'),
(634, 220, 7, 'uploads/rep_snapshots/log_220/rep_7.jpg', '2026-04-17 11:37:51'),
(638, 220, 8, 'uploads/rep_snapshots/log_220/rep_8.jpg', '2026-04-17 11:37:56'),
(644, 220, 9, 'uploads/rep_snapshots/log_220/rep_9.jpg', '2026-04-17 11:38:01'),
(649, 220, 10, 'uploads/rep_snapshots/log_220/rep_10.jpg', '2026-04-17 11:38:06'),
(656, 220, 11, 'uploads/rep_snapshots/log_220/rep_11.jpg', '2026-04-17 11:38:08'),
(658, 221, 1, 'uploads/rep_snapshots/log_221/rep_1.jpg', '2026-04-17 11:40:38'),
(661, 221, 2, 'uploads/rep_snapshots/log_221/rep_2.jpg', '2026-04-17 11:40:46'),
(664, 221, 3, 'uploads/rep_snapshots/log_221/rep_3.jpg', '2026-04-17 11:40:50'),
(667, 222, 1, 'uploads/rep_snapshots/log_222/rep_1.jpg', '2026-04-17 11:49:46'),
(670, 222, 2, 'uploads/rep_snapshots/log_222/rep_2.jpg', '2026-04-17 11:49:51'),
(673, 222, 3, 'uploads/rep_snapshots/log_222/rep_3.jpg', '2026-04-17 11:49:55'),
(674, 222, 4, 'uploads/rep_snapshots/log_222/rep_4.jpg', '2026-04-17 11:49:58'),
(676, 222, 5, 'uploads/rep_snapshots/log_222/rep_5.jpg', '2026-04-17 11:50:07'),
(680, 222, 6, 'uploads/rep_snapshots/log_222/rep_6.jpg', '2026-04-17 11:50:10'),
(683, 222, 7, 'uploads/rep_snapshots/log_222/rep_7.jpg', '2026-04-17 11:50:13'),
(685, 222, 8, 'uploads/rep_snapshots/log_222/rep_8.jpg', '2026-04-17 11:50:15'),
(686, 222, 9, 'uploads/rep_snapshots/log_222/rep_9.jpg', '2026-04-17 11:50:21'),
(689, 222, 10, 'uploads/rep_snapshots/log_222/rep_10.jpg', '2026-04-17 11:50:25'),
(695, 223, 1, 'uploads/rep_snapshots/log_223/rep_1.jpg', '2026-04-17 11:54:05'),
(698, 223, 2, 'uploads/rep_snapshots/log_223/rep_2.jpg', '2026-04-17 11:54:09'),
(699, 223, 3, 'uploads/rep_snapshots/log_223/rep_3.jpg', '2026-04-17 11:54:11'),
(702, 223, 4, 'uploads/rep_snapshots/log_223/rep_4.jpg', '2026-04-17 11:54:13'),
(706, 223, 5, 'uploads/rep_snapshots/log_223/rep_5.jpg', '2026-04-17 11:54:20'),
(707, 223, 6, 'uploads/rep_snapshots/log_223/rep_6.jpg', '2026-04-17 11:54:23'),
(712, 223, 7, 'uploads/rep_snapshots/log_223/rep_7.jpg', '2026-04-17 11:54:26'),
(716, 223, 8, 'uploads/rep_snapshots/log_223/rep_8.jpg', '2026-04-17 11:54:28'),
(719, 223, 9, 'uploads/rep_snapshots/log_223/rep_9.jpg', '2026-04-17 11:54:30'),
(721, 223, 10, 'uploads/rep_snapshots/log_223/rep_10.jpg', '2026-04-17 11:54:33'),
(722, 223, 11, 'uploads/rep_snapshots/log_223/rep_11.jpg', '2026-04-17 11:54:35'),
(725, 223, 12, 'uploads/rep_snapshots/log_223/rep_12.jpg', '2026-04-17 11:54:41'),
(728, 223, 13, 'uploads/rep_snapshots/log_223/rep_13.jpg', '2026-04-17 11:54:43'),
(732, 223, 14, 'uploads/rep_snapshots/log_223/rep_14.jpg', '2026-04-17 11:54:47'),
(734, 223, 15, 'uploads/rep_snapshots/log_223/rep_15.jpg', '2026-04-17 11:54:50'),
(737, 223, 16, 'uploads/rep_snapshots/log_223/rep_16.jpg', '2026-04-17 11:54:56'),
(739, 223, 17, 'uploads/rep_snapshots/log_223/rep_17.jpg', '2026-04-17 11:54:58'),
(741, 223, 18, 'uploads/rep_snapshots/log_223/rep_18.jpg', '2026-04-17 11:55:00'),
(744, 223, 19, 'uploads/rep_snapshots/log_223/rep_19.jpg', '2026-04-17 11:55:03'),
(747, 223, 20, 'uploads/rep_snapshots/log_223/rep_20.jpg', '2026-04-17 11:55:05'),
(749, 223, 21, 'uploads/rep_snapshots/log_223/rep_21.jpg', '2026-04-17 11:55:07'),
(752, 223, 22, 'uploads/rep_snapshots/log_223/rep_22.jpg', '2026-04-17 11:55:10'),
(755, 223, 23, 'uploads/rep_snapshots/log_223/rep_23.jpg', '2026-04-17 11:55:13'),
(757, 223, 24, 'uploads/rep_snapshots/log_223/rep_24.jpg', '2026-04-17 11:55:16'),
(760, 223, 25, 'uploads/rep_snapshots/log_223/rep_25.jpg', '2026-04-17 11:55:18'),
(762, 223, 26, 'uploads/rep_snapshots/log_223/rep_26.jpg', '2026-04-17 11:55:21'),
(765, 224, 1, 'uploads/rep_snapshots/log_224/rep_1.jpg', '2026-04-17 11:57:11'),
(767, 224, 2, 'uploads/rep_snapshots/log_224/rep_2.jpg', '2026-04-17 11:57:14'),
(771, 224, 3, 'uploads/rep_snapshots/log_224/rep_3.jpg', '2026-04-17 11:57:18'),
(777, 224, 4, 'uploads/rep_snapshots/log_224/rep_4.jpg', '2026-04-17 11:57:20'),
(779, 224, 5, 'uploads/rep_snapshots/log_224/rep_5.jpg', '2026-04-17 11:57:23'),
(785, 224, 6, 'uploads/rep_snapshots/log_224/rep_6.jpg', '2026-04-17 11:57:32'),
(788, 224, 7, 'uploads/rep_snapshots/log_224/rep_7.jpg', '2026-04-17 11:57:33'),
(791, 224, 8, 'uploads/rep_snapshots/log_224/rep_8.jpg', '2026-04-17 11:57:35'),
(796, 224, 9, 'uploads/rep_snapshots/log_224/rep_9.jpg', '2026-04-17 11:57:37'),
(799, 224, 10, 'uploads/rep_snapshots/log_224/rep_10.jpg', '2026-04-17 11:57:40'),
(802, 225, 1, 'uploads/rep_snapshots/log_225/rep_1.jpg', '2026-04-17 12:11:45'),
(805, 225, 2, 'uploads/rep_snapshots/log_225/rep_2.jpg', '2026-04-17 12:11:50'),
(809, 225, 3, 'uploads/rep_snapshots/log_225/rep_3.jpg', '2026-04-17 12:12:00'),
(812, 225, 4, 'uploads/rep_snapshots/log_225/rep_4.jpg', '2026-04-17 12:12:05'),
(814, 226, 1, 'uploads/rep_snapshots/log_226/rep_1.jpg', '2026-04-17 12:33:35'),
(817, 226, 2, 'uploads/rep_snapshots/log_226/rep_2.jpg', '2026-04-17 12:33:39'),
(821, 226, 3, 'uploads/rep_snapshots/log_226/rep_3.jpg', '2026-04-17 12:33:41'),
(824, 226, 4, 'uploads/rep_snapshots/log_226/rep_4.jpg', '2026-04-17 12:33:44'),
(825, 226, 5, 'uploads/rep_snapshots/log_226/rep_5.jpg', '2026-04-17 12:33:48'),
(828, 226, 6, 'uploads/rep_snapshots/log_226/rep_6.jpg', '2026-04-17 12:33:53'),
(831, 226, 7, 'uploads/rep_snapshots/log_226/rep_7.jpg', '2026-04-17 12:33:57'),
(834, 226, 8, 'uploads/rep_snapshots/log_226/rep_8.jpg', '2026-04-17 12:34:00'),
(837, 226, 9, 'uploads/rep_snapshots/log_226/rep_9.jpg', '2026-04-17 12:34:04'),
(840, 226, 10, 'uploads/rep_snapshots/log_226/rep_10.jpg', '2026-04-17 12:34:08'),
(843, 226, 11, 'uploads/rep_snapshots/log_226/rep_11.jpg', '2026-04-17 12:34:13'),
(849, 226, 12, 'uploads/rep_snapshots/log_226/rep_12.jpg', '2026-04-17 12:34:14'),
(852, 227, 1, 'uploads/rep_snapshots/log_227/rep_1.jpg', '2026-04-17 12:47:27'),
(855, 227, 2, 'uploads/rep_snapshots/log_227/rep_2.jpg', '2026-04-17 12:47:30'),
(858, 227, 3, 'uploads/rep_snapshots/log_227/rep_3.jpg', '2026-04-17 12:47:35'),
(862, 227, 4, 'uploads/rep_snapshots/log_227/rep_4.jpg', '2026-04-17 12:47:39'),
(866, 227, 5, 'uploads/rep_snapshots/log_227/rep_5.jpg', '2026-04-17 12:47:44'),
(872, 227, 6, 'uploads/rep_snapshots/log_227/rep_6.jpg', '2026-04-17 12:47:49'),
(876, 227, 7, 'uploads/rep_snapshots/log_227/rep_7.jpg', '2026-04-17 12:47:54'),
(879, 227, 8, 'uploads/rep_snapshots/log_227/rep_8.jpg', '2026-04-17 12:47:58'),
(882, 227, 9, 'uploads/rep_snapshots/log_227/rep_9.jpg', '2026-04-17 12:48:02'),
(883, 228, 1, 'uploads/rep_snapshots/log_228/rep_1.jpg', '2026-04-17 12:59:32'),
(886, 228, 2, 'uploads/rep_snapshots/log_228/rep_2.jpg', '2026-04-17 12:59:35'),
(889, 228, 3, 'uploads/rep_snapshots/log_228/rep_3.jpg', '2026-04-17 12:59:38'),
(890, 228, 4, 'uploads/rep_snapshots/log_228/rep_4.jpg', '2026-04-17 12:59:55'),
(893, 228, 5, 'uploads/rep_snapshots/log_228/rep_5.jpg', '2026-04-17 12:59:58'),
(896, 228, 6, 'uploads/rep_snapshots/log_228/rep_6.jpg', '2026-04-17 13:00:01'),
(899, 228, 7, 'uploads/rep_snapshots/log_228/rep_7.jpg', '2026-04-17 13:00:04'),
(902, 228, 8, 'uploads/rep_snapshots/log_228/rep_8.jpg', '2026-04-17 13:00:07'),
(905, 228, 9, 'uploads/rep_snapshots/log_228/rep_9.jpg', '2026-04-17 13:00:10'),
(908, 228, 10, 'uploads/rep_snapshots/log_228/rep_10.jpg', '2026-04-17 13:00:13'),
(912, 228, 11, 'uploads/rep_snapshots/log_228/rep_11.jpg', '2026-04-17 13:00:16'),
(915, 228, 12, 'uploads/rep_snapshots/log_228/rep_12.jpg', '2026-04-17 13:00:19'),
(918, 228, 13, 'uploads/rep_snapshots/log_228/rep_13.jpg', '2026-04-17 13:00:21'),
(921, 228, 14, 'uploads/rep_snapshots/log_228/rep_14.jpg', '2026-04-17 13:00:24'),
(924, 228, 15, 'uploads/rep_snapshots/log_228/rep_15.jpg', '2026-04-17 13:00:27'),
(927, 230, 1, 'uploads/rep_snapshots/log_230/rep_1.jpg', '2026-04-17 13:02:41'),
(928, 230, 2, 'uploads/rep_snapshots/log_230/rep_2.jpg', '2026-04-17 13:02:46'),
(931, 230, 3, 'uploads/rep_snapshots/log_230/rep_3.jpg', '2026-04-17 13:02:49'),
(934, 230, 4, 'uploads/rep_snapshots/log_230/rep_4.jpg', '2026-04-17 13:02:51'),
(937, 230, 5, 'uploads/rep_snapshots/log_230/rep_5.jpg', '2026-04-17 13:02:55'),
(940, 230, 6, 'uploads/rep_snapshots/log_230/rep_6.jpg', '2026-04-17 13:02:58'),
(943, 230, 7, 'uploads/rep_snapshots/log_230/rep_7.jpg', '2026-04-17 13:03:00'),
(946, 230, 8, 'uploads/rep_snapshots/log_230/rep_8.jpg', '2026-04-17 13:03:03'),
(948, 230, 9, 'uploads/rep_snapshots/log_230/rep_9.jpg', '2026-04-17 13:03:06'),
(951, 230, 10, 'uploads/rep_snapshots/log_230/rep_10.jpg', '2026-04-17 13:03:12'),
(953, 230, 11, 'uploads/rep_snapshots/log_230/rep_11.jpg', '2026-04-17 13:03:14'),
(954, 230, 12, 'uploads/rep_snapshots/log_230/rep_12.jpg', '2026-04-17 13:03:19'),
(956, 230, 13, 'uploads/rep_snapshots/log_230/rep_13.jpg', '2026-04-17 13:03:22'),
(958, 230, 14, 'uploads/rep_snapshots/log_230/rep_14.jpg', '2026-04-17 13:03:26'),
(960, 230, 15, 'uploads/rep_snapshots/log_230/rep_15.jpg', '2026-04-17 13:03:31'),
(961, 230, 16, 'uploads/rep_snapshots/log_230/rep_16.jpg', '2026-04-17 13:03:36'),
(967, 231, 1, 'uploads/rep_snapshots/log_231/rep_1.jpg', '2026-04-17 13:05:04'),
(970, 231, 2, 'uploads/rep_snapshots/log_231/rep_2.jpg', '2026-04-17 13:05:08'),
(974, 231, 3, 'uploads/rep_snapshots/log_231/rep_3.jpg', '2026-04-17 13:05:12'),
(978, 231, 4, 'uploads/rep_snapshots/log_231/rep_4.jpg', '2026-04-17 13:05:16'),
(981, 231, 5, 'uploads/rep_snapshots/log_231/rep_5.jpg', '2026-04-17 13:05:20'),
(984, 231, 6, 'uploads/rep_snapshots/log_231/rep_6.jpg', '2026-04-17 13:05:24'),
(989, 231, 7, 'uploads/rep_snapshots/log_231/rep_7.jpg', '2026-04-17 13:05:29'),
(993, 231, 8, 'uploads/rep_snapshots/log_231/rep_8.jpg', '2026-04-17 13:05:33'),
(998, 231, 9, 'uploads/rep_snapshots/log_231/rep_9.jpg', '2026-04-17 13:05:35'),
(1001, 231, 10, 'uploads/rep_snapshots/log_231/rep_10.jpg', '2026-04-17 13:05:40'),
(1005, 231, 11, 'uploads/rep_snapshots/log_231/rep_11.jpg', '2026-04-17 13:05:42'),
(1009, 231, 12, 'uploads/rep_snapshots/log_231/rep_12.jpg', '2026-04-17 13:05:46'),
(1012, 231, 13, 'uploads/rep_snapshots/log_231/rep_13.jpg', '2026-04-17 13:05:53'),
(1015, 231, 14, 'uploads/rep_snapshots/log_231/rep_14.jpg', '2026-04-17 13:06:10'),
(1019, 231, 15, 'uploads/rep_snapshots/log_231/rep_15.jpg', '2026-04-17 13:06:15'),
(1024, 231, 16, 'uploads/rep_snapshots/log_231/rep_16.jpg', '2026-04-17 13:06:19'),
(1029, 232, 1, 'uploads/rep_snapshots/log_232/rep_1.jpg', '2026-04-17 13:07:23'),
(1032, 232, 2, 'uploads/rep_snapshots/log_232/rep_2.jpg', '2026-04-17 13:07:26'),
(1034, 232, 3, 'uploads/rep_snapshots/log_232/rep_3.jpg', '2026-04-17 13:07:30'),
(1037, 232, 4, 'uploads/rep_snapshots/log_232/rep_4.jpg', '2026-04-17 13:07:33'),
(1042, 232, 5, 'uploads/rep_snapshots/log_232/rep_5.jpg', '2026-04-17 13:07:36'),
(1045, 232, 6, 'uploads/rep_snapshots/log_232/rep_6.jpg', '2026-04-17 13:07:42'),
(1048, 232, 7, 'uploads/rep_snapshots/log_232/rep_7.jpg', '2026-04-17 13:07:44'),
(1051, 232, 8, 'uploads/rep_snapshots/log_232/rep_8.jpg', '2026-04-17 13:07:47'),
(1054, 232, 9, 'uploads/rep_snapshots/log_232/rep_9.jpg', '2026-04-17 13:07:50'),
(1056, 232, 10, 'uploads/rep_snapshots/log_232/rep_10.jpg', '2026-04-17 13:07:54'),
(1057, 232, 11, 'uploads/rep_snapshots/log_232/rep_11.jpg', '2026-04-17 13:07:57'),
(1059, 232, 12, 'uploads/rep_snapshots/log_232/rep_12.jpg', '2026-04-17 13:08:00'),
(1061, 232, 13, 'uploads/rep_snapshots/log_232/rep_13.jpg', '2026-04-17 13:08:03'),
(1064, 232, 14, 'uploads/rep_snapshots/log_232/rep_14.jpg', '2026-04-17 13:08:07'),
(1066, 232, 15, 'uploads/rep_snapshots/log_232/rep_15.jpg', '2026-04-17 13:08:09'),
(1067, 232, 16, 'uploads/rep_snapshots/log_232/rep_16.jpg', '2026-04-17 13:08:12'),
(1070, 233, 1, 'uploads/rep_snapshots/log_233/rep_1.jpg', '2026-04-17 13:46:17'),
(1071, 233, 2, 'uploads/rep_snapshots/log_233/rep_2.jpg', '2026-04-17 13:46:32'),
(1077, 233, 3, 'uploads/rep_snapshots/log_233/rep_3.jpg', '2026-04-17 13:46:34'),
(1080, 234, 1, 'uploads/rep_snapshots/log_234/rep_1.jpg', '2026-04-17 13:48:57'),
(1082, 234, 2, 'uploads/rep_snapshots/log_234/rep_2.jpg', '2026-04-17 13:49:08'),
(1087, 234, 3, 'uploads/rep_snapshots/log_234/rep_3.jpg', '2026-04-17 13:49:12'),
(1091, 234, 4, 'uploads/rep_snapshots/log_234/rep_4.jpg', '2026-04-17 13:49:15'),
(1094, 234, 5, 'uploads/rep_snapshots/log_234/rep_5.jpg', '2026-04-17 13:49:19'),
(1097, 234, 6, 'uploads/rep_snapshots/log_234/rep_6.jpg', '2026-04-17 13:49:23'),
(1100, 234, 7, 'uploads/rep_snapshots/log_234/rep_7.jpg', '2026-04-17 13:49:27'),
(1103, 234, 8, 'uploads/rep_snapshots/log_234/rep_8.jpg', '2026-04-17 13:49:32'),
(1106, 234, 9, 'uploads/rep_snapshots/log_234/rep_9.jpg', '2026-04-17 13:49:35'),
(1109, 234, 10, 'uploads/rep_snapshots/log_234/rep_10.jpg', '2026-04-17 13:49:40'),
(1112, 234, 11, 'uploads/rep_snapshots/log_234/rep_11.jpg', '2026-04-17 13:49:44'),
(1115, 235, 1, 'uploads/rep_snapshots/log_235/rep_1.jpg', '2026-04-17 13:59:54'),
(1117, 235, 2, 'uploads/rep_snapshots/log_235/rep_2.jpg', '2026-04-17 13:59:57'),
(1121, 235, 3, 'uploads/rep_snapshots/log_235/rep_3.jpg', '2026-04-17 13:59:59'),
(1124, 235, 4, 'uploads/rep_snapshots/log_235/rep_4.jpg', '2026-04-17 14:00:02'),
(1125, 235, 5, 'uploads/rep_snapshots/log_235/rep_5.jpg', '2026-04-17 14:00:05'),
(1128, 235, 6, 'uploads/rep_snapshots/log_235/rep_6.jpg', '2026-04-17 14:00:07'),
(1129, 235, 7, 'uploads/rep_snapshots/log_235/rep_7.jpg', '2026-04-17 14:00:10'),
(1130, 235, 8, 'uploads/rep_snapshots/log_235/rep_8.jpg', '2026-04-17 14:00:13'),
(1132, 235, 9, 'uploads/rep_snapshots/log_235/rep_9.jpg', '2026-04-17 14:00:17'),
(1135, 235, 10, 'uploads/rep_snapshots/log_235/rep_10.jpg', '2026-04-17 14:00:21'),
(1137, 235, 11, 'uploads/rep_snapshots/log_235/rep_11.jpg', '2026-04-17 14:00:25'),
(1139, 235, 12, 'uploads/rep_snapshots/log_235/rep_12.jpg', '2026-04-17 14:00:28'),
(1142, 235, 13, 'uploads/rep_snapshots/log_235/rep_13.jpg', '2026-04-17 14:00:31'),
(1145, 235, 14, 'uploads/rep_snapshots/log_235/rep_14.jpg', '2026-04-17 14:00:35'),
(1150, 235, 15, 'uploads/rep_snapshots/log_235/rep_15.jpg', '2026-04-17 14:00:38'),
(1154, 235, 16, 'uploads/rep_snapshots/log_235/rep_16.jpg', '2026-04-17 14:00:40'),
(1159, 236, 1, 'uploads/rep_snapshots/log_236/rep_1.jpg', '2026-04-17 14:12:20'),
(1160, 237, 1, 'uploads/rep_snapshots/log_237/rep_1.jpg', '2026-04-17 14:13:39'),
(1161, 237, 2, 'uploads/rep_snapshots/log_237/rep_2.jpg', '2026-04-17 14:13:45'),
(1163, 237, 3, 'uploads/rep_snapshots/log_237/rep_3.jpg', '2026-04-17 14:13:50'),
(1164, 238, 1, 'uploads/rep_snapshots/log_238/rep_1.jpg', '2026-04-17 14:18:16'),
(1165, 238, 2, 'uploads/rep_snapshots/log_238/rep_2.jpg', '2026-04-17 14:18:22'),
(1166, 238, 3, 'uploads/rep_snapshots/log_238/rep_3.jpg', '2026-04-17 14:18:26'),
(1167, 238, 4, 'uploads/rep_snapshots/log_238/rep_4.jpg', '2026-04-17 14:18:32'),
(1168, 239, 1, 'uploads/rep_snapshots/log_239/rep_1.jpg', '2026-04-17 14:22:13'),
(1169, 239, 2, 'uploads/rep_snapshots/log_239/rep_2.jpg', '2026-04-17 14:22:22'),
(1170, 239, 3, 'uploads/rep_snapshots/log_239/rep_3.jpg', '2026-04-17 14:22:29'),
(1171, 239, 4, 'uploads/rep_snapshots/log_239/rep_4.jpg', '2026-04-17 14:22:35'),
(1172, 239, 5, 'uploads/rep_snapshots/log_239/rep_5.jpg', '2026-04-17 14:22:41'),
(1173, 240, 1, 'uploads/rep_snapshots/log_240/rep_1.jpg', '2026-04-17 15:16:52'),
(1175, 241, 1, 'uploads/rep_snapshots/log_241/rep_1.jpg', '2026-04-17 15:17:56'),
(1176, 241, 2, 'uploads/rep_snapshots/log_241/rep_2.jpg', '2026-04-17 15:18:00'),
(1178, 241, 3, 'uploads/rep_snapshots/log_241/rep_3.jpg', '2026-04-17 15:18:03'),
(1179, 241, 4, 'uploads/rep_snapshots/log_241/rep_4.jpg', '2026-04-17 15:18:07'),
(1180, 241, 5, 'uploads/rep_snapshots/log_241/rep_5.jpg', '2026-04-17 15:18:11'),
(1181, 241, 6, 'uploads/rep_snapshots/log_241/rep_6.jpg', '2026-04-17 15:18:14'),
(1184, 241, 7, 'uploads/rep_snapshots/log_241/rep_7.jpg', '2026-04-17 15:18:17'),
(1186, 241, 8, 'uploads/rep_snapshots/log_241/rep_8.jpg', '2026-04-17 15:18:20'),
(1189, 241, 9, 'uploads/rep_snapshots/log_241/rep_9.jpg', '2026-04-17 15:18:23'),
(1191, 241, 10, 'uploads/rep_snapshots/log_241/rep_10.jpg', '2026-04-17 15:18:34'),
(1192, 241, 11, 'uploads/rep_snapshots/log_241/rep_11.jpg', '2026-04-17 15:18:34'),
(1195, 241, 12, 'uploads/rep_snapshots/log_241/rep_12.jpg', '2026-04-17 15:19:17'),
(1198, 241, 13, 'uploads/rep_snapshots/log_241/rep_13.jpg', '2026-04-17 15:19:18'),
(1200, 242, 1, 'uploads/rep_snapshots/log_242/rep_1.jpg', '2026-04-17 23:58:07'),
(1202, 242, 2, 'uploads/rep_snapshots/log_242/rep_2.jpg', '2026-04-17 23:58:08'),
(1205, 242, 3, 'uploads/rep_snapshots/log_242/rep_3.jpg', '2026-04-17 23:58:11'),
(1208, 242, 4, 'uploads/rep_snapshots/log_242/rep_4.jpg', '2026-04-17 23:58:13'),
(1211, 242, 5, 'uploads/rep_snapshots/log_242/rep_5.jpg', '2026-04-17 23:58:16'),
(1214, 242, 6, 'uploads/rep_snapshots/log_242/rep_6.jpg', '2026-04-17 23:58:19'),
(1220, 242, 7, 'uploads/rep_snapshots/log_242/rep_7.jpg', '2026-04-17 23:58:38'),
(1223, 242, 8, 'uploads/rep_snapshots/log_242/rep_8.jpg', '2026-04-17 23:58:40'),
(1226, 242, 9, 'uploads/rep_snapshots/log_242/rep_9.jpg', '2026-04-17 23:58:42'),
(1232, 242, 10, 'uploads/rep_snapshots/log_242/rep_10.jpg', '2026-04-17 23:58:54'),
(1237, 242, 11, 'uploads/rep_snapshots/log_242/rep_11.jpg', '2026-04-17 23:58:58'),
(1241, 242, 12, 'uploads/rep_snapshots/log_242/rep_12.jpg', '2026-04-17 23:59:00'),
(1244, 242, 13, 'uploads/rep_snapshots/log_242/rep_13.jpg', '2026-04-17 23:59:13'),
(1250, 242, 14, 'uploads/rep_snapshots/log_242/rep_14.jpg', '2026-04-17 23:59:15'),
(1256, 242, 15, 'uploads/rep_snapshots/log_242/rep_15.jpg', '2026-04-17 23:59:16'),
(1259, 242, 16, 'uploads/rep_snapshots/log_242/rep_16.jpg', '2026-04-17 23:59:20'),
(1268, 242, 17, 'uploads/rep_snapshots/log_242/rep_17.jpg', '2026-04-17 23:59:23'),
(1271, 242, 18, 'uploads/rep_snapshots/log_242/rep_18.jpg', '2026-04-17 23:59:27'),
(1273, 242, 19, 'uploads/rep_snapshots/log_242/rep_19.jpg', '2026-04-17 23:59:29'),
(1276, 242, 20, 'uploads/rep_snapshots/log_242/rep_20.jpg', '2026-04-17 23:59:32'),
(1279, 242, 21, 'uploads/rep_snapshots/log_242/rep_21.jpg', '2026-04-17 23:59:33'),
(1282, 242, 22, 'uploads/rep_snapshots/log_242/rep_22.jpg', '2026-04-17 23:59:35'),
(1285, 242, 23, 'uploads/rep_snapshots/log_242/rep_23.jpg', '2026-04-17 23:59:39'),
(1292, 242, 24, 'uploads/rep_snapshots/log_242/rep_24.jpg', '2026-04-17 23:59:45'),
(1297, 242, 25, 'uploads/rep_snapshots/log_242/rep_25.jpg', '2026-04-17 23:59:49'),
(1298, 243, 1, 'uploads/rep_snapshots/log_243/rep_1.jpg', '2026-04-18 00:51:44'),
(1299, 243, 2, 'uploads/rep_snapshots/log_243/rep_2.jpg', '2026-04-18 00:51:48'),
(1302, 243, 3, 'uploads/rep_snapshots/log_243/rep_3.jpg', '2026-04-18 00:51:51'),
(1305, 243, 4, 'uploads/rep_snapshots/log_243/rep_4.jpg', '2026-04-18 00:51:53'),
(1308, 244, 1, 'uploads/rep_snapshots/log_244/rep_1.jpg', '2026-04-18 00:52:27'),
(1309, 244, 2, 'uploads/rep_snapshots/log_244/rep_2.jpg', '2026-04-18 00:52:29'),
(1312, 244, 3, 'uploads/rep_snapshots/log_244/rep_3.jpg', '2026-04-18 00:52:32'),
(1315, 244, 4, 'uploads/rep_snapshots/log_244/rep_4.jpg', '2026-04-18 00:52:34'),
(1317, 244, 5, 'uploads/rep_snapshots/log_244/rep_5.jpg', '2026-04-18 00:52:36'),
(1320, 244, 6, 'uploads/rep_snapshots/log_244/rep_6.jpg', '2026-04-18 00:52:38'),
(1323, 244, 7, 'uploads/rep_snapshots/log_244/rep_7.jpg', '2026-04-18 00:52:40'),
(1326, 244, 8, 'uploads/rep_snapshots/log_244/rep_8.jpg', '2026-04-18 00:52:42'),
(1328, 244, 9, 'uploads/rep_snapshots/log_244/rep_9.jpg', '2026-04-18 00:52:44'),
(1331, 244, 10, 'uploads/rep_snapshots/log_244/rep_10.jpg', '2026-04-18 00:52:46'),
(1334, 244, 11, 'uploads/rep_snapshots/log_244/rep_11.jpg', '2026-04-18 00:52:48'),
(1337, 244, 12, 'uploads/rep_snapshots/log_244/rep_12.jpg', '2026-04-18 00:52:51'),
(1342, 244, 13, 'uploads/rep_snapshots/log_244/rep_13.jpg', '2026-04-18 00:52:52'),
(1344, 244, 14, 'uploads/rep_snapshots/log_244/rep_14.jpg', '2026-04-18 00:53:00'),
(1348, 244, 15, 'uploads/rep_snapshots/log_244/rep_15.jpg', '2026-04-18 00:53:03'),
(1353, 244, 16, 'uploads/rep_snapshots/log_244/rep_16.jpg', '2026-04-18 00:53:05'),
(1359, 245, 1, 'uploads/rep_snapshots/log_245/rep_1.jpg', '2026-04-18 01:03:17'),
(1361, 245, 2, 'uploads/rep_snapshots/log_245/rep_2.jpg', '2026-04-18 01:03:21'),
(1367, 245, 3, 'uploads/rep_snapshots/log_245/rep_3.jpg', '2026-04-18 01:03:27'),
(1371, 246, 1, 'uploads/rep_snapshots/log_246/rep_1.jpg', '2026-04-18 02:02:13'),
(1376, 246, 2, 'uploads/rep_snapshots/log_246/rep_2.jpg', '2026-04-18 02:02:19'),
(1379, 246, 3, 'uploads/rep_snapshots/log_246/rep_3.jpg', '2026-04-18 02:02:22'),
(1381, 246, 4, 'uploads/rep_snapshots/log_246/rep_4.jpg', '2026-04-18 02:02:26'),
(1384, 246, 5, 'uploads/rep_snapshots/log_246/rep_5.jpg', '2026-04-18 02:02:29'),
(1387, 246, 6, 'uploads/rep_snapshots/log_246/rep_6.jpg', '2026-04-18 02:02:32'),
(1390, 246, 7, 'uploads/rep_snapshots/log_246/rep_7.jpg', '2026-04-18 02:02:36'),
(1392, 246, 8, 'uploads/rep_snapshots/log_246/rep_8.jpg', '2026-04-18 02:02:43'),
(1396, 246, 9, 'uploads/rep_snapshots/log_246/rep_9.jpg', '2026-04-18 02:02:47'),
(1399, 246, 10, 'uploads/rep_snapshots/log_246/rep_10.jpg', '2026-04-18 02:02:52'),
(1402, 246, 11, 'uploads/rep_snapshots/log_246/rep_11.jpg', '2026-04-18 02:02:56'),
(1405, 246, 12, 'uploads/rep_snapshots/log_246/rep_12.jpg', '2026-04-18 02:03:01'),
(1408, 246, 13, 'uploads/rep_snapshots/log_246/rep_13.jpg', '2026-04-18 02:03:03'),
(1411, 246, 14, 'uploads/rep_snapshots/log_246/rep_14.jpg', '2026-04-18 02:03:06'),
(1414, 246, 15, 'uploads/rep_snapshots/log_246/rep_15.jpg', '2026-04-18 02:03:09'),
(1417, 246, 16, 'uploads/rep_snapshots/log_246/rep_16.jpg', '2026-04-18 02:03:14'),
(1423, 247, 1, 'uploads/rep_snapshots/log_247/rep_1.jpg', '2026-04-18 02:10:54'),
(1427, 247, 2, 'uploads/rep_snapshots/log_247/rep_2.jpg', '2026-04-18 02:10:58'),
(1430, 247, 3, 'uploads/rep_snapshots/log_247/rep_3.jpg', '2026-04-18 02:11:34'),
(1432, 247, 4, 'uploads/rep_snapshots/log_247/rep_4.jpg', '2026-04-18 02:11:39'),
(1433, 247, 5, 'uploads/rep_snapshots/log_247/rep_5.jpg', '2026-04-18 02:11:42'),
(1439, 248, 1, 'uploads/rep_snapshots/log_248/rep_1.jpg', '2026-04-18 02:12:44'),
(1441, 248, 2, 'uploads/rep_snapshots/log_248/rep_2.jpg', '2026-04-18 02:12:47'),
(1447, 248, 3, 'uploads/rep_snapshots/log_248/rep_3.jpg', '2026-04-18 02:12:50'),
(1450, 248, 4, 'uploads/rep_snapshots/log_248/rep_4.jpg', '2026-04-18 02:12:53'),
(1453, 248, 5, 'uploads/rep_snapshots/log_248/rep_5.jpg', '2026-04-18 02:12:56'),
(1457, 248, 6, 'uploads/rep_snapshots/log_248/rep_6.jpg', '2026-04-18 02:13:08'),
(1460, 249, 1, 'uploads/rep_snapshots/log_249/rep_1.jpg', '2026-04-18 02:13:50'),
(1463, 249, 2, 'uploads/rep_snapshots/log_249/rep_2.jpg', '2026-04-18 02:14:00'),
(1466, 249, 3, 'uploads/rep_snapshots/log_249/rep_3.jpg', '2026-04-18 02:14:01'),
(1469, 249, 4, 'uploads/rep_snapshots/log_249/rep_4.jpg', '2026-04-18 02:14:04'),
(1472, 249, 5, 'uploads/rep_snapshots/log_249/rep_5.jpg', '2026-04-18 02:14:07'),
(1475, 249, 6, 'uploads/rep_snapshots/log_249/rep_6.jpg', '2026-04-18 02:14:16'),
(1478, 249, 7, 'uploads/rep_snapshots/log_249/rep_7.jpg', '2026-04-18 02:14:23'),
(1481, 249, 8, 'uploads/rep_snapshots/log_249/rep_8.jpg', '2026-04-18 02:14:24'),
(1486, 249, 9, 'uploads/rep_snapshots/log_249/rep_9.jpg', '2026-04-18 02:14:26'),
(1492, 249, 10, 'uploads/rep_snapshots/log_249/rep_10.jpg', '2026-04-18 02:14:28'),
(1495, 249, 11, 'uploads/rep_snapshots/log_249/rep_11.jpg', '2026-04-18 02:14:30'),
(1501, 249, 12, 'uploads/rep_snapshots/log_249/rep_12.jpg', '2026-04-18 02:14:31'),
(1506, 249, 13, 'uploads/rep_snapshots/log_249/rep_13.jpg', '2026-04-18 02:14:32'),
(1508, 249, 14, 'uploads/rep_snapshots/log_249/rep_14.jpg', '2026-04-18 02:14:39'),
(1510, 250, 1, 'uploads/rep_snapshots/log_250/rep_1.jpg', '2026-04-18 02:15:08'),
(1515, 250, 2, 'uploads/rep_snapshots/log_250/rep_2.jpg', '2026-04-18 02:15:13'),
(1521, 250, 3, 'uploads/rep_snapshots/log_250/rep_3.jpg', '2026-04-18 02:15:19'),
(1527, 250, 4, 'uploads/rep_snapshots/log_250/rep_4.jpg', '2026-04-18 02:15:43'),
(1530, 251, 1, 'uploads/rep_snapshots/log_251/rep_1.jpg', '2026-04-18 03:44:49'),
(1535, 251, 2, 'uploads/rep_snapshots/log_251/rep_2.jpg', '2026-04-18 03:44:50'),
(1538, 251, 3, 'uploads/rep_snapshots/log_251/rep_3.jpg', '2026-04-18 03:44:54'),
(1540, 251, 4, 'uploads/rep_snapshots/log_251/rep_4.jpg', '2026-04-18 03:44:57'),
(1543, 251, 5, 'uploads/rep_snapshots/log_251/rep_5.jpg', '2026-04-18 03:45:03'),
(1546, 251, 6, 'uploads/rep_snapshots/log_251/rep_6.jpg', '2026-04-18 03:45:06'),
(1549, 251, 7, 'uploads/rep_snapshots/log_251/rep_7.jpg', '2026-04-18 03:45:10'),
(1552, 251, 8, 'uploads/rep_snapshots/log_251/rep_8.jpg', '2026-04-18 03:45:14'),
(1554, 251, 9, 'uploads/rep_snapshots/log_251/rep_9.jpg', '2026-04-18 03:45:19'),
(1557, 251, 10, 'uploads/rep_snapshots/log_251/rep_10.jpg', '2026-04-18 03:45:23'),
(1559, 251, 11, 'uploads/rep_snapshots/log_251/rep_11.jpg', '2026-04-18 03:45:38'),
(1565, 251, 12, 'uploads/rep_snapshots/log_251/rep_12.jpg', '2026-04-18 03:45:44'),
(1568, 251, 13, 'uploads/rep_snapshots/log_251/rep_13.jpg', '2026-04-18 03:45:50'),
(1571, 251, 14, 'uploads/rep_snapshots/log_251/rep_14.jpg', '2026-04-18 03:45:58'),
(1575, 251, 15, 'uploads/rep_snapshots/log_251/rep_15.jpg', '2026-04-18 03:46:06'),
(1578, 251, 16, 'uploads/rep_snapshots/log_251/rep_16.jpg', '2026-04-18 03:46:17'),
(1582, 251, 17, 'uploads/rep_snapshots/log_251/rep_17.jpg', '2026-04-18 03:46:18'),
(1585, 251, 18, 'uploads/rep_snapshots/log_251/rep_18.jpg', '2026-04-18 03:46:34'),
(1588, 251, 19, 'uploads/rep_snapshots/log_251/rep_19.jpg', '2026-04-18 03:46:43'),
(1591, 252, 1, 'uploads/rep_snapshots/log_252/rep_1.jpg', '2026-04-18 17:54:26'),
(1594, 252, 2, 'uploads/rep_snapshots/log_252/rep_2.jpg', '2026-04-18 17:54:29'),
(1597, 252, 3, 'uploads/rep_snapshots/log_252/rep_3.jpg', '2026-04-18 17:54:33'),
(1600, 252, 4, 'uploads/rep_snapshots/log_252/rep_4.jpg', '2026-04-18 17:54:36'),
(1603, 252, 5, 'uploads/rep_snapshots/log_252/rep_5.jpg', '2026-04-18 17:54:40'),
(1606, 252, 6, 'uploads/rep_snapshots/log_252/rep_6.jpg', '2026-04-18 17:54:45'),
(1611, 252, 7, 'uploads/rep_snapshots/log_252/rep_7.jpg', '2026-04-18 17:54:47'),
(1617, 252, 8, 'uploads/rep_snapshots/log_252/rep_8.jpg', '2026-04-18 17:54:50'),
(1620, 252, 9, 'uploads/rep_snapshots/log_252/rep_9.jpg', '2026-04-18 17:54:53'),
(1626, 252, 10, 'uploads/rep_snapshots/log_252/rep_10.jpg', '2026-04-18 17:54:56'),
(1629, 252, 11, 'uploads/rep_snapshots/log_252/rep_11.jpg', '2026-04-18 17:54:59'),
(1632, 252, 12, 'uploads/rep_snapshots/log_252/rep_12.jpg', '2026-04-18 17:55:06'),
(1635, 252, 13, 'uploads/rep_snapshots/log_252/rep_13.jpg', '2026-04-18 17:55:13'),
(1638, 252, 14, 'uploads/rep_snapshots/log_252/rep_14.jpg', '2026-04-18 17:55:20'),
(1642, 252, 15, 'uploads/rep_snapshots/log_252/rep_15.jpg', '2026-04-18 17:55:23'),
(1648, 252, 16, 'uploads/rep_snapshots/log_252/rep_16.jpg', '2026-04-18 17:55:28'),
(1654, 252, 17, 'uploads/rep_snapshots/log_252/rep_17.jpg', '2026-04-18 17:55:32'),
(1660, 252, 18, 'uploads/rep_snapshots/log_252/rep_18.jpg', '2026-04-18 17:55:37'),
(1666, 252, 19, 'uploads/rep_snapshots/log_252/rep_19.jpg', '2026-04-18 17:55:42'),
(1672, 252, 20, 'uploads/rep_snapshots/log_252/rep_20.jpg', '2026-04-18 17:55:49'),
(1676, 252, 21, 'uploads/rep_snapshots/log_252/rep_21.jpg', '2026-04-18 17:55:58'),
(1681, 252, 22, 'uploads/rep_snapshots/log_252/rep_22.jpg', '2026-04-18 17:56:04'),
(1687, 252, 23, 'uploads/rep_snapshots/log_252/rep_23.jpg', '2026-04-18 17:56:09'),
(1690, 252, 24, 'uploads/rep_snapshots/log_252/rep_24.jpg', '2026-04-18 17:56:16'),
(1699, 252, 25, 'uploads/rep_snapshots/log_252/rep_25.jpg', '2026-04-18 17:56:20'),
(1707, 252, 26, 'uploads/rep_snapshots/log_252/rep_26.jpg', '2026-04-18 17:56:26'),
(1716, 252, 27, 'uploads/rep_snapshots/log_252/rep_27.jpg', '2026-04-18 17:56:30'),
(1722, 252, 28, 'uploads/rep_snapshots/log_252/rep_28.jpg', '2026-04-18 17:56:35'),
(1728, 252, 29, 'uploads/rep_snapshots/log_252/rep_29.jpg', '2026-04-18 17:56:39'),
(1734, 252, 30, 'uploads/rep_snapshots/log_252/rep_30.jpg', '2026-04-18 17:56:44'),
(1739, 252, 31, 'uploads/rep_snapshots/log_252/rep_31.jpg', '2026-04-18 17:56:50'),
(1745, 252, 32, 'uploads/rep_snapshots/log_252/rep_32.jpg', '2026-04-18 17:56:54'),
(1747, 253, 1, 'uploads/rep_snapshots/log_253/rep_1.jpg', '2026-04-18 18:01:43'),
(1750, 253, 2, 'uploads/rep_snapshots/log_253/rep_2.jpg', '2026-04-18 18:01:46'),
(1753, 253, 3, 'uploads/rep_snapshots/log_253/rep_3.jpg', '2026-04-18 18:01:49'),
(1756, 253, 4, 'uploads/rep_snapshots/log_253/rep_4.jpg', '2026-04-18 18:01:52'),
(1759, 253, 5, 'uploads/rep_snapshots/log_253/rep_5.jpg', '2026-04-18 18:01:56'),
(1762, 253, 6, 'uploads/rep_snapshots/log_253/rep_6.jpg', '2026-04-18 18:02:00'),
(1765, 253, 7, 'uploads/rep_snapshots/log_253/rep_7.jpg', '2026-04-18 18:02:03'),
(1768, 253, 8, 'uploads/rep_snapshots/log_253/rep_8.jpg', '2026-04-18 18:02:07'),
(1771, 253, 9, 'uploads/rep_snapshots/log_253/rep_9.jpg', '2026-04-18 18:02:10'),
(1774, 253, 10, 'uploads/rep_snapshots/log_253/rep_10.jpg', '2026-04-18 18:02:13'),
(1777, 253, 11, 'uploads/rep_snapshots/log_253/rep_11.jpg', '2026-04-18 18:02:17'),
(1780, 253, 12, 'uploads/rep_snapshots/log_253/rep_12.jpg', '2026-04-18 18:02:20'),
(1783, 253, 13, 'uploads/rep_snapshots/log_253/rep_13.jpg', '2026-04-18 18:02:25'),
(1786, 253, 14, 'uploads/rep_snapshots/log_253/rep_14.jpg', '2026-04-18 18:02:30'),
(1789, 253, 15, 'uploads/rep_snapshots/log_253/rep_15.jpg', '2026-04-18 18:02:36'),
(1794, 254, 1, 'uploads/rep_snapshots/log_254/rep_1.jpg', '2026-04-18 18:03:44'),
(1797, 254, 2, 'uploads/rep_snapshots/log_254/rep_2.jpg', '2026-04-18 18:03:48'),
(1800, 254, 3, 'uploads/rep_snapshots/log_254/rep_3.jpg', '2026-04-18 18:03:53'),
(1803, 254, 4, 'uploads/rep_snapshots/log_254/rep_4.jpg', '2026-04-18 18:03:56'),
(1806, 254, 5, 'uploads/rep_snapshots/log_254/rep_5.jpg', '2026-04-18 18:04:00'),
(1809, 254, 6, 'uploads/rep_snapshots/log_254/rep_6.jpg', '2026-04-18 18:04:04');
INSERT INTO `rep_snapshots` (`snapshot_id`, `log_id`, `rep_index`, `image_path`, `captured_at`) VALUES
(1812, 254, 7, 'uploads/rep_snapshots/log_254/rep_7.jpg', '2026-04-18 18:04:08'),
(1815, 254, 8, 'uploads/rep_snapshots/log_254/rep_8.jpg', '2026-04-18 18:04:12'),
(1818, 254, 9, 'uploads/rep_snapshots/log_254/rep_9.jpg', '2026-04-18 18:04:14'),
(1820, 254, 10, 'uploads/rep_snapshots/log_254/rep_10.jpg', '2026-04-18 18:04:23'),
(1823, 254, 11, 'uploads/rep_snapshots/log_254/rep_11.jpg', '2026-04-18 18:04:26'),
(1826, 254, 12, 'uploads/rep_snapshots/log_254/rep_12.jpg', '2026-04-18 18:04:30'),
(1829, 254, 13, 'uploads/rep_snapshots/log_254/rep_13.jpg', '2026-04-18 18:04:34'),
(1832, 254, 14, 'uploads/rep_snapshots/log_254/rep_14.jpg', '2026-04-18 18:04:39'),
(1837, 254, 15, 'uploads/rep_snapshots/log_254/rep_15.jpg', '2026-04-18 18:04:43'),
(1840, 254, 16, 'uploads/rep_snapshots/log_254/rep_16.jpg', '2026-04-18 18:04:47'),
(1846, 254, 17, 'uploads/rep_snapshots/log_254/rep_17.jpg', '2026-04-18 18:04:50'),
(1849, 254, 18, 'uploads/rep_snapshots/log_254/rep_18.jpg', '2026-04-18 18:04:57'),
(1852, 254, 19, 'uploads/rep_snapshots/log_254/rep_19.jpg', '2026-04-18 18:05:01'),
(1855, 254, 20, 'uploads/rep_snapshots/log_254/rep_20.jpg', '2026-04-18 18:05:05'),
(1858, 254, 21, 'uploads/rep_snapshots/log_254/rep_21.jpg', '2026-04-18 18:05:13'),
(1861, 254, 22, 'uploads/rep_snapshots/log_254/rep_22.jpg', '2026-04-18 18:05:19'),
(1864, 254, 23, 'uploads/rep_snapshots/log_254/rep_23.jpg', '2026-04-18 18:05:24'),
(1867, 254, 24, 'uploads/rep_snapshots/log_254/rep_24.jpg', '2026-04-18 18:05:31'),
(1873, 254, 25, 'uploads/rep_snapshots/log_254/rep_25.jpg', '2026-04-18 18:05:34'),
(1880, 254, 26, 'uploads/rep_snapshots/log_254/rep_26.jpg', '2026-04-18 18:05:39'),
(1886, 254, 27, 'uploads/rep_snapshots/log_254/rep_27.jpg', '2026-04-18 18:05:45'),
(1889, 254, 28, 'uploads/rep_snapshots/log_254/rep_28.jpg', '2026-04-18 18:05:52'),
(1892, 254, 29, 'uploads/rep_snapshots/log_254/rep_29.jpg', '2026-04-18 18:06:01'),
(1898, 254, 30, 'uploads/rep_snapshots/log_254/rep_30.jpg', '2026-04-18 18:06:05'),
(1904, 254, 31, 'uploads/rep_snapshots/log_254/rep_31.jpg', '2026-04-18 18:06:10'),
(1908, 254, 32, 'uploads/rep_snapshots/log_254/rep_32.jpg', '2026-04-18 18:06:14'),
(1914, 254, 33, 'uploads/rep_snapshots/log_254/rep_33.jpg', '2026-04-18 18:06:19'),
(1917, 254, 34, 'uploads/rep_snapshots/log_254/rep_34.jpg', '2026-04-18 18:06:23'),
(1922, 254, 35, 'uploads/rep_snapshots/log_254/rep_35.jpg', '2026-04-18 18:06:28');

-- --------------------------------------------------------

--
-- Table structure for table `sus_responses`
--

CREATE TABLE `sus_responses` (
  `sus_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `q1` tinyint NOT NULL,
  `q2` tinyint NOT NULL,
  `q3` tinyint NOT NULL,
  `q4` tinyint NOT NULL,
  `q5` tinyint NOT NULL,
  `q6` tinyint NOT NULL,
  `q7` tinyint NOT NULL,
  `q8` tinyint NOT NULL,
  `q9` tinyint NOT NULL,
  `q10` tinyint NOT NULL,
  `sus_score` float DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `trainer_applications`
--

CREATE TABLE `trainer_applications` (
  `app_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `affiliation` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `credential_type` enum('cpt','scs','pt','student','other') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `credential_ref` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statement` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `proof_file` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `proof_mime` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','approved','rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `reviewed_by` int DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `admin_notes` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `trainer_invites`
--

CREATE TABLE `trainer_invites` (
  `invite_id` bigint NOT NULL,
  `trainee_id` int NOT NULL,
  `trainer_id` int NOT NULL,
  `status` enum('pending','accepted','declined','cancelled','expired','unlink_requested') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `token` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `responded_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trainer_invites`
--

INSERT INTO `trainer_invites` (`invite_id`, `trainee_id`, `trainer_id`, `status`, `token`, `expires_at`, `created_at`, `responded_at`) VALUES
(9, 3, 2, 'cancelled', 'dde00d5d0dbfe7c9e6f4117e0586f606d7198ae499c6774a76b57f69cc5df824', '2026-03-25 09:44:27', '2026-03-18 09:44:27', '2026-03-18 09:47:51'),
(10, 3, 2, 'accepted', '8706c4857a38d6c14e2d788d55b7e029b80f1abe17e2d7c31ee6db6c6bf71c86', '2026-04-08 06:30:11', '2026-04-01 06:30:11', '2026-04-01 06:30:19'),
(11, 12, 2, 'cancelled', '14e7246542dc849b251b942762af0ea67b9dfd0d39d5c2ead4818cd4362a0a61', '2026-04-16 16:35:48', '2026-04-09 16:35:48', '2026-04-10 00:13:47'),
(12, 12, 2, 'accepted', '15dab4939033067261152aec5c8474cf18d91ef86bd6489ceb6ff69d93dd5bb1', '2026-04-17 00:14:01', '2026-04-10 00:14:01', '2026-04-10 00:15:02'),
(13, 13, 2, 'accepted', 'ae917f8a08fb1a0dc9968d5140825367ba915da77e287923a698571c16baabfe', '2026-04-23 09:06:43', '2026-04-16 09:06:43', '2026-04-16 09:11:54');

-- --------------------------------------------------------

--
-- Table structure for table `trainer_rating_summary`
--

CREATE TABLE `trainer_rating_summary` (
  `trainer_id` int NOT NULL,
  `avg_rating` decimal(6,2) DEFAULT NULL,
  `review_count` bigint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trainer_rating_summary`
--

INSERT INTO `trainer_rating_summary` (`trainer_id`, `avg_rating`, `review_count`) VALUES
(2, 4.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `trainer_reviews`
--

CREATE TABLE `trainer_reviews` (
  `review_id` bigint NOT NULL,
  `trainer_id` int NOT NULL,
  `trainee_id` int NOT NULL,
  `rating` tinyint NOT NULL,
  `review_text` text,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'approved',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trainer_reviews`
--

INSERT INTO `trainer_reviews` (`review_id`, `trainer_id`, `trainee_id`, `rating`, `review_text`, `status`, `created_at`, `updated_at`) VALUES
(3, 2, 3, 4, 'Ang galeng!', 'approved', '2026-02-28 15:11:56', '2026-02-28 15:11:59');

--
-- Triggers `trainer_reviews`
--
DELIMITER $$
CREATE TRIGGER `trg_reviews_ad` AFTER DELETE ON `trainer_reviews` FOR EACH ROW BEGIN
  CALL recompute_trainer_summary(OLD.trainer_id);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_reviews_ai` AFTER INSERT ON `trainer_reviews` FOR EACH ROW BEGIN
  CALL recompute_trainer_summary(NEW.trainer_id);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_reviews_au` AFTER UPDATE ON `trainer_reviews` FOR EACH ROW BEGIN
  IF NEW.trainer_id <> OLD.trainer_id THEN
    CALL recompute_trainer_summary(OLD.trainer_id);
  END IF;

  CALL recompute_trainer_summary(NEW.trainer_id);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `trainer_review_flags`
--

CREATE TABLE `trainer_review_flags` (
  `flag_id` bigint NOT NULL,
  `review_id` bigint NOT NULL,
  `trainer_id` int NOT NULL,
  `reason` varchar(255) NOT NULL,
  `details` text,
  `status` enum('pending','resolved','dismissed') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `training_logs`
--

CREATE TABLE `training_logs` (
  `log_id` bigint NOT NULL,
  `user_id` int NOT NULL,
  `exercise_type` enum('bicep_curl','shoulder_press','lateral_raise') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_type` enum('upload','webcam') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'upload',
  `video_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `result_json_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reps_total` int NOT NULL DEFAULT '0',
  `reps_good` int NOT NULL DEFAULT '0',
  `reps_bad` int NOT NULL DEFAULT '0',
  `form_error_count` int NOT NULL DEFAULT '0',
  `fatigue_flag` tinyint(1) NOT NULL DEFAULT '0',
  `started_at` timestamp NULL DEFAULT NULL,
  `finished_at` timestamp NULL DEFAULT NULL,
  `processing_ms` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fatigue_peak_score` float DEFAULT NULL,
  `fatigue_final_score` float DEFAULT NULL,
  `fatigue_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fatigue_trend` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fatigue_since_rep` int DEFAULT NULL,
  `fatigue_summary` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `training_logs`
--

INSERT INTO `training_logs` (`log_id`, `user_id`, `exercise_type`, `source_type`, `video_path`, `result_json_path`, `reps_total`, `reps_good`, `reps_bad`, `form_error_count`, `fatigue_flag`, `started_at`, `finished_at`, `processing_ms`, `created_at`, `fatigue_peak_score`, `fatigue_final_score`, `fatigue_level`, `fatigue_trend`, `fatigue_since_rep`, `fatigue_summary`) VALUES
(1, 3, 'bicep_curl', 'upload', 'assets/data/uploads/bc_001.mp4', 'assets/data/tmp/bc_001.json', 12, 10, 2, 3, 0, '2025-12-14 15:18:44', '2025-12-14 15:18:53', 9100, '2025-12-14 15:18:44', NULL, NULL, NULL, NULL, NULL, NULL),
(2, 3, 'shoulder_press', 'upload', 'assets/data/uploads/sp_001.mp4', 'assets/data/tmp/sp_001.json', 10, 7, 3, 6, 1, '2025-12-15 15:18:44', '2025-12-15 15:18:55', 11200, '2025-12-15 15:18:44', NULL, NULL, NULL, NULL, NULL, NULL),
(3, 3, 'lateral_raise', 'upload', 'assets/data/uploads/lr_001.mp4', 'assets/data/tmp/lr_001.json', 14, 11, 3, 5, 1, '2025-12-16 12:18:44', '2025-12-16 12:18:54', 10300, '2025-12-16 12:18:44', NULL, NULL, NULL, NULL, NULL, NULL),
(4, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:39:44', '2025-12-16 15:40:40', 5, '2025-12-16 15:39:44', NULL, NULL, NULL, NULL, NULL, NULL),
(5, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:41:12', NULL, NULL, '2025-12-16 15:41:12', NULL, NULL, NULL, NULL, NULL, NULL),
(6, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 6, 5, 62, 0, '2025-12-16 15:41:27', '2025-12-16 15:42:00', 3, '2025-12-16 15:41:27', NULL, NULL, NULL, NULL, NULL, NULL),
(7, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 0, 3, 40, 0, '2025-12-16 15:43:56', '2025-12-16 15:44:27', 4, '2025-12-16 15:43:56', NULL, NULL, NULL, NULL, NULL, NULL),
(8, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:49:52', '2025-12-16 15:49:54', 3, '2025-12-16 15:49:52', NULL, NULL, NULL, NULL, NULL, NULL),
(9, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 4, 5, 66, 1, '2025-12-16 16:04:57', '2025-12-16 16:05:50', 4, '2025-12-16 16:04:57', NULL, NULL, NULL, NULL, NULL, NULL),
(10, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 35, 0, '2025-12-16 16:06:21', '2025-12-16 16:06:30', 2, '2025-12-16 16:06:21', NULL, NULL, NULL, NULL, NULL, NULL),
(11, 3, 'shoulder_press', 'webcam', NULL, NULL, 7, 0, 7, 18, 0, '2025-12-16 16:25:38', '2025-12-16 16:26:05', 6, '2025-12-16 16:25:38', NULL, NULL, NULL, NULL, NULL, NULL),
(12, 3, 'lateral_raise', 'webcam', NULL, NULL, 6, 1, 5, 1, 0, '2025-12-16 16:26:19', '2025-12-16 16:27:11', 3, '2025-12-16 16:26:19', NULL, NULL, NULL, NULL, NULL, NULL),
(13, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 3, 7, 39, 0, '2025-12-18 03:10:18', '2025-12-18 03:11:08', 5, '2025-12-18 03:10:18', NULL, NULL, NULL, NULL, NULL, NULL),
(14, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 2, 0, '2025-12-18 03:33:37', '2025-12-18 03:33:42', 4, '2025-12-18 03:33:37', NULL, NULL, NULL, NULL, NULL, NULL),
(15, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 2, 4, 96, 0, '2025-12-18 03:34:11', '2025-12-18 03:34:58', 8, '2025-12-18 03:34:11', NULL, NULL, NULL, NULL, NULL, NULL),
(16, 3, 'shoulder_press', 'webcam', NULL, NULL, 2, 0, 2, 60, 0, '2025-12-18 03:35:05', '2025-12-18 03:35:50', 9, '2025-12-18 03:35:05', NULL, NULL, NULL, NULL, NULL, NULL),
(17, 3, 'lateral_raise', 'webcam', NULL, NULL, 1, 0, 1, 104, 1, '2025-12-18 03:35:55', '2025-12-18 03:36:27', 4, '2025-12-18 03:35:55', NULL, NULL, NULL, NULL, NULL, NULL),
(18, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 1, 2, 60, 0, '2025-12-18 03:54:30', '2025-12-18 03:55:07', 9, '2025-12-18 03:54:30', NULL, NULL, NULL, NULL, NULL, NULL),
(19, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 03:31:14', '2026-01-21 03:31:17', 6, '2026-01-21 03:31:14', NULL, NULL, NULL, NULL, NULL, NULL),
(20, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 1, 9, 22, 0, '2026-01-21 05:13:02', '2026-01-21 05:13:41', 3, '2026-01-21 05:13:02', NULL, NULL, NULL, NULL, NULL, NULL),
(21, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 2, 16, 0, '2026-01-21 05:19:09', '2026-01-21 05:19:28', 4, '2026-01-21 05:19:09', NULL, NULL, NULL, NULL, NULL, NULL),
(22, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 24, 0, '2026-01-21 05:22:47', '2026-01-21 05:22:59', 2, '2026-01-21 05:22:47', NULL, NULL, NULL, NULL, NULL, NULL),
(23, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 2, 22, 1, '2026-01-21 05:26:01', '2026-01-21 05:26:18', 6, '2026-01-21 05:26:01', NULL, NULL, NULL, NULL, NULL, NULL),
(24, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 0, 4, 33, 0, '2026-01-21 05:28:51', '2026-01-21 05:29:19', 3, '2026-01-21 05:28:51', NULL, NULL, NULL, NULL, NULL, NULL),
(25, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 0, 3, 14, 0, '2026-01-21 05:32:38', '2026-01-21 05:33:02', 3, '2026-01-21 05:32:38', NULL, NULL, NULL, NULL, NULL, NULL),
(26, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 05:35:10', '2026-01-21 05:35:11', 2, '2026-01-21 05:35:10', NULL, NULL, NULL, NULL, NULL, NULL),
(27, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 05:44:50', '2026-01-21 05:44:52', 4, '2026-01-21 05:44:50', NULL, NULL, NULL, NULL, NULL, NULL),
(29, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 0, 0, 0, '2026-01-21 05:48:38', '2026-01-21 05:48:54', 6, '2026-01-21 05:48:38', NULL, NULL, NULL, NULL, NULL, NULL),
(30, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 0, 0, 0, '2026-01-21 05:52:35', '2026-01-21 05:52:51', 4, '2026-01-21 05:52:35', NULL, NULL, NULL, NULL, NULL, NULL),
(31, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 0, 0, 0, '2026-01-21 06:05:38', '2026-01-21 06:05:56', 5, '2026-01-21 06:05:38', NULL, NULL, NULL, NULL, NULL, NULL),
(32, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:06:59', '2026-01-21 06:07:03', 4, '2026-01-21 06:06:59', NULL, NULL, NULL, NULL, NULL, NULL),
(33, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:07:28', '2026-01-21 06:08:03', 3, '2026-01-21 06:07:28', NULL, NULL, NULL, NULL, NULL, NULL),
(34, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:13:32', '2026-01-21 06:15:07', 6, '2026-01-21 06:13:32', NULL, NULL, NULL, NULL, NULL, NULL),
(35, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 0, 0, 0, '2026-01-21 06:19:17', '2026-01-21 06:19:59', 3, '2026-01-21 06:19:17', NULL, NULL, NULL, NULL, NULL, NULL),
(36, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 0, 0, 0, '2026-01-21 06:20:03', '2026-01-21 06:20:25', 3, '2026-01-21 06:20:03', NULL, NULL, NULL, NULL, NULL, NULL),
(37, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:35:29', '2026-01-21 06:35:40', 5, '2026-01-21 06:35:29', NULL, NULL, NULL, NULL, NULL, NULL),
(38, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 6, 0, 0, 0, '2026-01-21 06:55:37', '2026-01-21 06:56:09', 9, '2026-01-21 06:55:37', NULL, NULL, NULL, NULL, NULL, NULL),
(39, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-01-21 07:00:48', '2026-01-21 07:01:21', 4, '2026-01-21 07:00:48', NULL, NULL, NULL, NULL, NULL, NULL),
(40, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-01-21 07:01:26', '2026-01-21 07:01:44', 3, '2026-01-21 07:01:26', NULL, NULL, NULL, NULL, NULL, NULL),
(41, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-01-21 07:01:45', '2026-01-21 07:02:09', 3, '2026-01-21 07:01:45', NULL, NULL, NULL, NULL, NULL, NULL),
(43, 3, 'bicep_curl', 'webcam', NULL, NULL, 20, 0, 20, 29, 0, '2026-01-21 07:45:47', '2026-01-21 07:47:03', 5, '2026-01-21 07:45:47', NULL, NULL, NULL, NULL, NULL, NULL),
(44, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 0, 6, 0, 0, '2026-01-21 07:47:19', '2026-01-21 07:47:35', 3, '2026-01-21 07:47:19', NULL, NULL, NULL, NULL, NULL, NULL),
(45, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 0, 8, 14, 0, '2026-01-21 08:00:59', '2026-01-21 08:01:40', 5, '2026-01-21 08:00:59', NULL, NULL, NULL, NULL, NULL, NULL),
(47, 3, 'bicep_curl', 'webcam', NULL, NULL, 14, 5, 9, 53, 0, '2026-01-21 08:17:09', '2026-01-21 08:17:58', 7, '2026-01-21 08:17:09', NULL, NULL, NULL, NULL, NULL, NULL),
(50, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 7, 7, 0, '2026-01-21 08:34:50', '2026-01-21 08:35:18', 8, '2026-01-21 08:34:50', NULL, NULL, NULL, NULL, NULL, NULL),
(51, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 08:36:20', '2026-01-21 08:36:21', 4, '2026-01-21 08:36:20', NULL, NULL, NULL, NULL, NULL, NULL),
(52, 3, 'bicep_curl', 'webcam', NULL, NULL, 14, 0, 14, 48, 1, '2026-01-21 08:38:28', '2026-01-21 08:39:43', 7, '2026-01-21 08:38:28', NULL, NULL, NULL, NULL, NULL, NULL),
(53, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:09', '2026-01-21 09:03:21', 10, '2026-01-21 09:03:09', NULL, NULL, NULL, NULL, NULL, NULL),
(54, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:37', '2026-01-21 09:03:44', 13, '2026-01-21 09:03:37', NULL, NULL, NULL, NULL, NULL, NULL),
(55, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:57', '2026-01-21 09:04:00', 4, '2026-01-21 09:03:57', NULL, NULL, NULL, NULL, NULL, NULL),
(56, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:04:22', '2026-01-21 09:04:36', 14, '2026-01-21 09:04:22', NULL, NULL, NULL, NULL, NULL, NULL),
(57, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:08:58', '2026-01-21 09:09:01', 8, '2026-01-21 09:08:58', NULL, NULL, NULL, NULL, NULL, NULL),
(58, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:09:07', '2026-01-21 09:09:14', 7, '2026-01-21 09:09:07', NULL, NULL, NULL, NULL, NULL, NULL),
(59, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-01-21 09:09:23', '2026-01-21 09:10:04', 10, '2026-01-21 09:09:23', NULL, NULL, NULL, NULL, NULL, NULL),
(60, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:11:13', '2026-01-21 09:11:19', 4, '2026-01-21 09:11:13', NULL, NULL, NULL, NULL, NULL, NULL),
(61, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:17:48', '2026-01-21 09:18:01', 4, '2026-01-21 09:17:48', NULL, NULL, NULL, NULL, NULL, NULL),
(62, 3, 'bicep_curl', 'webcam', NULL, NULL, 15, 13, 2, 2, 0, '2026-01-21 09:20:42', '2026-01-21 09:21:47', 8, '2026-01-21 09:20:42', NULL, NULL, NULL, NULL, NULL, NULL),
(63, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 6, 2, 2, 0, '2026-01-21 09:22:52', '2026-01-21 09:23:23', 8, '2026-01-21 09:22:52', NULL, NULL, NULL, NULL, NULL, NULL),
(64, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 7, 3, 3, 0, '2026-01-21 09:23:57', '2026-01-21 09:24:35', 5, '2026-01-21 09:23:57', NULL, NULL, NULL, NULL, NULL, NULL),
(65, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 9, 2, 2, 0, '2026-01-21 09:30:38', '2026-01-21 09:31:14', 16, '2026-01-21 09:30:38', NULL, NULL, NULL, NULL, NULL, NULL),
(66, 3, 'bicep_curl', 'webcam', NULL, NULL, 13, 13, 0, 0, 0, '2026-01-21 09:36:36', '2026-01-21 09:37:11', 7, '2026-01-21 09:36:36', NULL, NULL, NULL, NULL, NULL, NULL),
(67, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:41:48', '2026-01-21 09:41:57', 4, '2026-01-21 09:41:48', NULL, NULL, NULL, NULL, NULL, NULL),
(68, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:42:49', '2026-01-21 09:43:05', 5, '2026-01-21 09:42:49', NULL, NULL, NULL, NULL, NULL, NULL),
(69, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 9, 1, 1, 0, '2026-01-21 09:47:45', '2026-01-21 09:48:16', 5, '2026-01-21 09:47:45', NULL, NULL, NULL, NULL, NULL, NULL),
(71, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 10:03:34', '2026-01-21 10:03:37', 4, '2026-01-21 10:03:34', NULL, NULL, NULL, NULL, NULL, NULL),
(72, 3, 'lateral_raise', 'webcam', NULL, NULL, 4, 2, 2, 2, 0, '2026-01-22 06:44:01', '2026-01-22 06:44:36', 13, '2026-01-22 06:44:01', NULL, NULL, NULL, NULL, NULL, NULL),
(73, 3, 'lateral_raise', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-01-22 06:44:39', '2026-01-22 06:45:29', 10, '2026-01-22 06:44:39', NULL, NULL, NULL, NULL, NULL, NULL),
(74, 3, 'shoulder_press', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-01-22 06:45:32', '2026-01-22 06:46:31', 8, '2026-01-22 06:45:32', NULL, NULL, NULL, NULL, NULL, NULL),
(81, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:24:33', '2026-02-23 01:24:38', 9, '2026-02-23 01:24:33', NULL, NULL, NULL, NULL, NULL, NULL),
(82, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-23 01:24:43', '2026-02-23 01:25:00', 7, '2026-02-23 01:24:43', NULL, NULL, NULL, NULL, NULL, NULL),
(83, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-23 01:25:09', '2026-02-23 01:25:26', 12, '2026-02-23 01:25:09', NULL, NULL, NULL, NULL, NULL, NULL),
(84, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:33:36', '2026-02-23 01:33:53', 6, '2026-02-23 01:33:36', NULL, NULL, NULL, NULL, NULL, NULL),
(85, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:34:45', '2026-02-23 01:34:48', 5, '2026-02-23 01:34:45', NULL, NULL, NULL, NULL, NULL, NULL),
(86, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:41:04', '2026-02-23 01:41:05', 7, '2026-02-23 01:41:04', NULL, NULL, NULL, NULL, NULL, NULL),
(87, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:41:20', '2026-02-23 01:41:22', 6, '2026-02-23 01:41:20', NULL, NULL, NULL, NULL, NULL, NULL),
(88, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-23 01:50:13', '2026-02-23 01:50:44', 6, '2026-02-23 01:50:13', NULL, NULL, NULL, NULL, NULL, NULL),
(89, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-23 02:07:46', '2026-02-23 02:08:06', 4, '2026-02-23 02:07:46', NULL, NULL, NULL, NULL, NULL, NULL),
(90, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 02:09:58', '2026-02-23 02:10:02', 5, '2026-02-23 02:09:58', NULL, NULL, NULL, NULL, NULL, NULL),
(91, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-23 02:12:34', '2026-02-23 02:12:52', 5, '2026-02-23 02:12:34', NULL, NULL, NULL, NULL, NULL, NULL),
(92, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 02:18:21', '2026-02-23 02:18:30', 6, '2026-02-23 02:18:21', NULL, NULL, NULL, NULL, NULL, NULL),
(93, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-02-23 02:18:47', '2026-02-23 02:19:12', 6, '2026-02-23 02:18:47', NULL, NULL, NULL, NULL, NULL, NULL),
(94, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 10, 2, 2, 0, '2026-02-23 02:53:50', '2026-02-23 02:54:41', 8, '2026-02-23 02:53:50', NULL, NULL, NULL, NULL, NULL, NULL),
(95, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-23 02:55:22', '2026-02-23 02:55:44', 7, '2026-02-23 02:55:22', NULL, NULL, NULL, NULL, NULL, NULL),
(96, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-23 02:56:22', '2026-02-23 02:56:41', 4, '2026-02-23 02:56:22', NULL, NULL, NULL, NULL, NULL, NULL),
(97, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-23 03:22:55', '2026-02-23 03:23:16', 9, '2026-02-23 03:22:55', NULL, NULL, NULL, NULL, NULL, NULL),
(99, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 12:14:52', '2026-02-23 12:14:56', 11, '2026-02-23 12:14:52', NULL, NULL, NULL, NULL, NULL, NULL),
(100, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-24 04:10:12', '2026-02-24 04:11:02', 12, '2026-02-24 04:10:12', NULL, NULL, NULL, NULL, NULL, NULL),
(101, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-25 06:30:34', '2026-02-25 06:30:51', 20, '2026-02-25 06:30:34', NULL, NULL, NULL, NULL, NULL, NULL),
(102, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-25 06:31:27', '2026-02-25 06:31:39', 12, '2026-02-25 06:31:27', NULL, NULL, NULL, NULL, NULL, NULL),
(103, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 06:33:41', '2026-02-25 06:34:49', 15, '2026-02-25 06:33:41', NULL, NULL, NULL, NULL, NULL, NULL),
(104, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 06:36:16', '2026-02-25 06:37:52', 8, '2026-02-25 06:36:16', NULL, NULL, NULL, NULL, NULL, NULL),
(105, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 3, 4, 4, 0, '2026-02-25 06:58:43', '2026-02-25 06:59:08', 20, '2026-02-25 06:58:43', NULL, NULL, NULL, NULL, NULL, NULL),
(106, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-25 06:59:22', '2026-02-25 06:59:40', 9, '2026-02-25 06:59:22', NULL, NULL, NULL, NULL, NULL, NULL),
(107, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-25 06:59:57', '2026-02-25 07:00:13', 12, '2026-02-25 06:59:57', NULL, NULL, NULL, NULL, NULL, NULL),
(108, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-25 07:00:40', '2026-02-25 07:00:50', 7, '2026-02-25 07:00:40', NULL, NULL, NULL, NULL, NULL, NULL),
(109, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-25 07:01:17', '2026-02-25 07:01:30', 11, '2026-02-25 07:01:17', NULL, NULL, NULL, NULL, NULL, NULL),
(110, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-25 07:04:06', '2026-02-25 07:04:22', 13, '2026-02-25 07:04:06', NULL, NULL, NULL, NULL, NULL, NULL),
(111, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-25 07:04:41', '2026-02-25 07:04:45', 15, '2026-02-25 07:04:41', NULL, NULL, NULL, NULL, NULL, NULL),
(112, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:23:11', '2026-02-25 07:23:51', 10, '2026-02-25 07:23:11', NULL, NULL, NULL, NULL, NULL, NULL),
(113, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:27:05', '2026-02-25 07:27:14', 8, '2026-02-25 07:27:05', NULL, NULL, NULL, NULL, NULL, NULL),
(114, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:40:01', '2026-02-25 07:40:54', 17, '2026-02-25 07:40:01', NULL, NULL, NULL, NULL, NULL, NULL),
(115, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:45:52', '2026-02-25 07:46:10', 33, '2026-02-25 07:45:52', NULL, NULL, NULL, NULL, NULL, NULL),
(116, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:47:35', '2026-02-25 07:47:42', 58, '2026-02-25 07:47:35', NULL, NULL, NULL, NULL, NULL, NULL),
(117, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:48:42', '2026-02-25 07:48:54', 8, '2026-02-25 07:48:42', NULL, NULL, NULL, NULL, NULL, NULL),
(118, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:53:26', '2026-02-25 07:53:31', 6, '2026-02-25 07:53:26', NULL, NULL, NULL, NULL, NULL, NULL),
(119, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:54:33', '2026-02-25 07:54:37', 11, '2026-02-25 07:54:33', NULL, NULL, NULL, NULL, NULL, NULL),
(120, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:58:12', '2026-02-25 07:58:35', 10, '2026-02-25 07:58:12', NULL, NULL, NULL, NULL, NULL, NULL),
(121, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 08:12:04', '2026-02-25 08:12:12', 26, '2026-02-25 08:12:04', NULL, NULL, NULL, NULL, NULL, NULL),
(122, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 9, 3, 3, 0, '2026-02-25 08:16:35', '2026-02-25 08:17:07', 7, '2026-02-25 08:16:35', NULL, NULL, NULL, NULL, NULL, NULL),
(123, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 7, 4, 4, 0, '2026-02-25 08:17:27', '2026-02-25 08:17:56', 24, '2026-02-25 08:17:27', NULL, NULL, NULL, NULL, NULL, NULL),
(124, 3, 'lateral_raise', 'webcam', NULL, NULL, 15, 10, 5, 5, 0, '2026-02-25 08:18:09', '2026-02-25 08:19:10', 24, '2026-02-25 08:18:09', NULL, NULL, NULL, NULL, NULL, NULL),
(125, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 11, 1, 1, 0, '2026-02-25 08:20:30', '2026-02-25 08:21:25', 6, '2026-02-25 08:20:30', NULL, NULL, NULL, NULL, NULL, NULL),
(126, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 08:21:49', '2026-02-25 08:22:37', 5, '2026-02-25 08:21:49', NULL, NULL, NULL, NULL, NULL, NULL),
(127, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:09:41', '2026-02-25 09:09:46', 15, '2026-02-25 09:09:41', NULL, NULL, NULL, NULL, NULL, NULL),
(128, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:10:10', '2026-02-25 09:10:52', 5, '2026-02-25 09:10:10', NULL, NULL, NULL, NULL, NULL, NULL),
(129, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:20:55', '2026-02-25 09:21:05', 10, '2026-02-25 09:20:55', NULL, NULL, NULL, NULL, NULL, NULL),
(130, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:21:20', '2026-02-25 09:21:26', 5, '2026-02-25 09:21:20', NULL, NULL, NULL, NULL, NULL, NULL),
(131, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:34:26', NULL, NULL, '2026-02-25 09:34:26', NULL, NULL, NULL, NULL, NULL, NULL),
(132, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:35:12', NULL, NULL, '2026-02-25 09:35:12', NULL, NULL, NULL, NULL, NULL, NULL),
(133, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:38:48', '2026-02-25 09:38:55', 9, '2026-02-25 09:38:48', NULL, NULL, NULL, NULL, NULL, NULL),
(134, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:42:27', NULL, NULL, '2026-02-25 09:42:27', NULL, NULL, NULL, NULL, NULL, NULL),
(135, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:47:26', '2026-02-25 09:47:37', 11, '2026-02-25 09:47:26', NULL, NULL, NULL, NULL, NULL, NULL),
(136, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 07:52:20', '2026-02-27 07:52:31', 14, '2026-02-27 07:52:20', NULL, NULL, NULL, NULL, NULL, NULL),
(137, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 9, 2, 2, 0, '2026-02-27 08:09:19', '2026-02-27 08:09:52', 6, '2026-02-27 08:09:19', NULL, NULL, NULL, NULL, NULL, NULL),
(138, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-02-27 08:13:38', '2026-02-27 08:13:56', 7, '2026-02-27 08:13:38', NULL, NULL, NULL, NULL, NULL, NULL),
(139, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:33:41', '2026-02-27 08:33:50', 19, '2026-02-27 08:33:41', NULL, NULL, NULL, NULL, NULL, NULL),
(140, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 08:33:57', '2026-02-27 08:34:18', 15, '2026-02-27 08:33:57', NULL, NULL, NULL, NULL, NULL, NULL),
(141, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:35:25', '2026-02-27 08:35:46', 10, '2026-02-27 08:35:25', NULL, NULL, NULL, NULL, NULL, NULL),
(142, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:37:57', '2026-02-27 08:38:27', 11, '2026-02-27 08:37:57', NULL, NULL, NULL, NULL, NULL, NULL),
(143, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-02-27 08:57:02', '2026-02-27 08:57:33', 13, '2026-02-27 08:57:02', NULL, NULL, NULL, NULL, NULL, NULL),
(144, 3, 'shoulder_press', 'webcam', NULL, NULL, 11, 8, 3, 3, 0, '2026-02-27 08:57:45', '2026-02-27 08:58:37', 7, '2026-02-27 08:57:45', NULL, NULL, NULL, NULL, NULL, NULL),
(145, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 09:08:38', '2026-02-27 09:08:41', 5, '2026-02-27 09:08:38', NULL, NULL, NULL, NULL, NULL, NULL),
(146, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 09:12:05', '2026-02-27 09:13:02', 44, '2026-02-27 09:12:05', NULL, NULL, NULL, NULL, NULL, NULL),
(147, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-27 09:35:14', '2026-02-27 09:35:30', 7, '2026-02-27 09:35:14', NULL, NULL, NULL, NULL, NULL, NULL),
(148, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 10:00:50', '2026-02-27 10:00:56', 13, '2026-02-27 10:00:50', NULL, NULL, NULL, NULL, NULL, NULL),
(149, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-27 10:02:06', '2026-02-27 10:02:21', 5, '2026-02-27 10:02:06', NULL, NULL, NULL, NULL, NULL, NULL),
(150, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-02-27 10:08:37', '2026-02-27 10:09:21', 7, '2026-02-27 10:08:37', NULL, NULL, NULL, NULL, NULL, NULL),
(151, 3, 'shoulder_press', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-02-27 10:10:02', '2026-02-27 10:10:56', 34, '2026-02-27 10:10:02', NULL, NULL, NULL, NULL, NULL, NULL),
(152, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-27 10:11:14', '2026-02-27 10:11:22', 11, '2026-02-27 10:11:14', NULL, NULL, NULL, NULL, NULL, NULL),
(153, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 7, 0, 0, 0, '2026-02-27 10:32:48', '2026-02-27 10:33:15', 7, '2026-02-27 10:32:48', NULL, NULL, NULL, NULL, NULL, NULL),
(154, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-27 10:34:54', '2026-02-27 10:35:00', 6, '2026-02-27 10:34:54', NULL, NULL, NULL, NULL, NULL, NULL),
(155, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-27 10:39:27', '2026-02-27 10:39:45', 4, '2026-02-27 10:39:27', NULL, NULL, NULL, NULL, NULL, NULL),
(156, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 10:45:10', '2026-02-27 10:45:16', 4, '2026-02-27 10:45:10', NULL, NULL, NULL, NULL, NULL, NULL),
(157, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 3, 1, 1, 0, '2026-02-27 10:46:29', '2026-02-27 10:46:47', 17, '2026-02-27 10:46:29', NULL, NULL, NULL, NULL, NULL, NULL),
(158, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-27 10:47:05', '2026-02-27 10:47:08', 9, '2026-02-27 10:47:05', NULL, NULL, NULL, NULL, NULL, NULL),
(159, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 10:47:31', '2026-02-27 10:47:35', 13, '2026-02-27 10:47:31', NULL, NULL, NULL, NULL, NULL, NULL),
(160, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-27 10:49:30', '2026-02-27 10:49:45', 5, '2026-02-27 10:49:30', NULL, NULL, NULL, NULL, NULL, NULL),
(161, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-02-27 11:44:32', '2026-02-27 11:44:57', 8, '2026-02-27 11:44:32', NULL, NULL, NULL, NULL, NULL, NULL),
(162, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-03-18 09:43:27', '2026-03-18 09:43:49', 17, '2026-03-18 09:43:27', NULL, NULL, NULL, NULL, NULL, NULL),
(163, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 8, 1, 1, 0, '2026-03-18 09:51:33', '2026-03-18 09:52:02', 6, '2026-03-18 09:51:33', NULL, NULL, NULL, NULL, NULL, NULL),
(164, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:55:35', NULL, NULL, '2026-04-01 05:55:35', NULL, NULL, NULL, NULL, NULL, NULL),
(165, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:55:53', NULL, NULL, '2026-04-01 05:55:53', NULL, NULL, NULL, NULL, NULL, NULL),
(166, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:56:10', NULL, NULL, '2026-04-01 05:56:10', NULL, NULL, NULL, NULL, NULL, NULL),
(167, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:59:01', NULL, NULL, '2026-04-01 05:59:01', NULL, NULL, NULL, NULL, NULL, NULL),
(168, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:59:55', NULL, NULL, '2026-04-01 05:59:55', NULL, NULL, NULL, NULL, NULL, NULL),
(169, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 06:01:34', NULL, NULL, '2026-04-01 06:01:34', NULL, NULL, NULL, NULL, NULL, NULL),
(170, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-01 06:04:50', '2026-04-01 06:05:06', 19, '2026-04-01 06:04:50', NULL, NULL, NULL, NULL, NULL, NULL),
(171, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 06:09:29', NULL, NULL, '2026-04-01 06:09:29', NULL, NULL, NULL, NULL, NULL, NULL),
(172, 3, 'lateral_raise', 'webcam', NULL, NULL, 6, 6, 0, 0, 0, '2026-04-01 06:10:52', '2026-04-01 06:11:23', 6, '2026-04-01 06:10:52', NULL, NULL, NULL, NULL, NULL, NULL),
(173, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-04-01 06:11:50', '2026-04-01 06:12:28', 8, '2026-04-01 06:11:50', NULL, NULL, NULL, NULL, NULL, NULL),
(174, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-04-01 06:27:42', '2026-04-01 06:28:12', 9, '2026-04-01 06:27:42', NULL, NULL, NULL, NULL, NULL, NULL),
(175, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-04-06 07:59:17', '2026-04-06 07:59:39', 4, '2026-04-06 07:59:17', NULL, NULL, NULL, NULL, NULL, NULL),
(176, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-04-06 08:02:27', '2026-04-06 08:02:55', 3, '2026-04-06 08:02:27', NULL, NULL, NULL, NULL, NULL, NULL),
(177, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-04-06 08:06:52', '2026-04-06 08:07:16', 3, '2026-04-06 08:06:52', NULL, NULL, NULL, NULL, NULL, NULL),
(178, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-06 08:07:37', '2026-04-06 08:09:17', 3, '2026-04-06 08:07:37', NULL, NULL, NULL, NULL, NULL, NULL),
(179, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-06 08:11:45', '2026-04-06 08:12:05', 2, '2026-04-06 08:11:45', NULL, NULL, NULL, NULL, NULL, NULL),
(180, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 11, 0, 0, 0, '2026-04-06 08:27:07', '2026-04-06 08:27:59', 4, '2026-04-06 08:27:07', NULL, NULL, NULL, NULL, NULL, NULL),
(181, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-08 03:31:31', '2026-04-08 03:32:01', 3, '2026-04-08 03:31:31', NULL, NULL, NULL, NULL, NULL, NULL),
(182, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 9, 0, 0, 0, '2026-04-08 09:35:39', '2026-04-08 09:36:33', 4, '2026-04-08 09:35:39', NULL, NULL, NULL, NULL, NULL, NULL),
(190, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-04-09 12:52:31', '2026-04-09 12:52:49', 4, '2026-04-09 12:52:31', 4.66841, 4.66841, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(191, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-04-09 13:09:01', '2026-04-09 13:10:00', 3, '2026-04-09 13:09:01', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(192, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-04-09 14:10:32', '2026-04-09 14:11:25', 6, '2026-04-09 14:10:32', 35.1912, 35.1912, 'low', 'sharply_rising', NULL, 'Early fatigue signs detected; maintain control and monitor form.'),
(193, 12, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-04-09 16:30:03', '2026-04-09 16:30:58', 4, '2026-04-09 16:30:03', 2.38476, 2.38476, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(194, 12, 'bicep_curl', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-04-09 16:33:21', '2026-04-09 16:34:20', 5, '2026-04-09 16:33:21', 1.97378, 0, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(195, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-04-11 01:50:14', '2026-04-11 01:50:32', 4, '2026-04-11 01:50:14', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(196, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 2, 3, 3, 0, '2026-04-13 02:17:08', '2026-04-13 02:18:20', 4, '2026-04-13 02:17:08', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(197, 3, 'shoulder_press', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-04-13 02:22:42', '2026-04-13 02:23:06', 3, '2026-04-13 02:22:42', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(198, 3, 'lateral_raise', 'webcam', NULL, NULL, 9, 5, 4, 4, 0, '2026-04-13 02:24:00', '2026-04-13 02:24:35', 5, '2026-04-13 02:24:00', 32.6616, 32.6616, 'low', 'sharply_rising', NULL, 'Early fatigue signs detected; maintain control and monitor form.'),
(199, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-13 02:24:49', '2026-04-13 02:25:01', 4, '2026-04-13 02:24:49', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(200, 12, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-15 13:40:32', '2026-04-15 13:40:47', 4, '2026-04-15 13:40:32', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(201, 12, 'shoulder_press', 'webcam', NULL, NULL, 5, 3, 2, 2, 0, '2026-04-15 13:43:18', '2026-04-15 13:43:59', 4, '2026-04-15 13:43:18', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(202, 13, 'bicep_curl', 'webcam', NULL, NULL, 7, 6, 1, 1, 0, '2026-04-16 09:08:24', '2026-04-16 09:09:09', 4, '2026-04-16 09:08:24', 2.66104, 0, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(203, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 5, 1, 1, 0, '2026-04-17 10:30:55', '2026-04-17 10:31:23', 4, '2026-04-17 10:30:55', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(204, 3, 'lateral_raise', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 10:35:24', '2026-04-17 10:35:31', 3, '2026-04-17 10:35:24', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(205, 3, 'lateral_raise', 'webcam', NULL, NULL, 7, 6, 1, 1, 0, '2026-04-17 10:35:47', '2026-04-17 10:36:21', 4, '2026-04-17 10:35:47', 30.2378, 30.2378, 'low', 'stable', NULL, 'Low fatigue signs detected, but form remains manageable.'),
(206, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 6, 1, 1, 0, '2026-04-17 10:53:39', '2026-04-17 10:54:07', 5, '2026-04-17 10:53:39', 40.9598, 40.9598, 'low', 'stable', NULL, 'Low fatigue signs detected, but form remains manageable.'),
(207, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-04-17 10:56:48', '2026-04-17 10:57:48', 6, '2026-04-17 10:56:48', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(208, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-04-17 11:01:20', '2026-04-17 11:01:31', 4, '2026-04-17 11:01:20', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(209, 12, 'bicep_curl', 'webcam', NULL, NULL, 17, 14, 3, 3, 0, '2026-04-17 11:04:20', '2026-04-17 11:07:30', 6, '2026-04-17 11:04:20', 66.0409, 66.0409, 'moderate', 'sharply_rising', 17, 'Fatigue has been building since around Rep 17; form may degrade if the set continues.'),
(210, 12, 'bicep_curl', 'webcam', NULL, NULL, 8, 6, 2, 2, 0, '2026-04-17 11:09:09', '2026-04-17 11:11:14', 4, '2026-04-17 11:09:09', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(211, 12, 'bicep_curl', 'webcam', NULL, NULL, 6, 6, 0, 0, 0, '2026-04-17 11:12:41', '2026-04-17 11:13:04', 3, '2026-04-17 11:12:41', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(212, 12, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 11:16:05', NULL, NULL, '2026-04-17 11:16:05', NULL, NULL, NULL, NULL, NULL, NULL),
(213, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 11:17:40', NULL, NULL, '2026-04-17 11:17:40', NULL, NULL, NULL, NULL, NULL, NULL),
(215, 12, 'bicep_curl', 'webcam', NULL, NULL, 4, 3, 1, 1, 0, '2026-04-17 11:19:10', '2026-04-17 11:20:39', 4, '2026-04-17 11:19:10', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(216, 12, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 11:22:46', '2026-04-17 11:22:48', 3, '2026-04-17 11:22:46', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(217, 12, 'bicep_curl', 'webcam', NULL, NULL, 11, 11, 0, 0, 0, '2026-04-17 11:23:09', '2026-04-17 11:24:03', 5, '2026-04-17 11:23:09', 4.29763, 4.29763, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(218, 12, 'lateral_raise', 'webcam', NULL, NULL, 25, 17, 8, 8, 0, '2026-04-17 11:29:59', '2026-04-17 11:31:59', 7, '2026-04-17 11:29:59', 6.28278, 3.57649, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(219, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 1, 1, 1, 0, '2026-04-17 11:36:21', '2026-04-17 11:36:37', 3, '2026-04-17 11:36:21', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(220, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-04-17 11:37:18', '2026-04-17 11:38:09', 8, '2026-04-17 11:37:18', 3.23984, 0.147521, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(221, 3, 'lateral_raise', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-04-17 11:40:29', '2026-04-17 11:41:03', 3, '2026-04-17 11:40:29', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(222, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 9, 0, 0, 0, '2026-04-17 11:49:45', '2026-04-17 11:50:40', 5, '2026-04-17 11:49:45', 2.04885, 0.120431, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(223, 12, 'bicep_curl', 'webcam', NULL, NULL, 25, 23, 2, 2, 0, '2026-04-17 11:54:05', '2026-04-17 11:55:22', 6, '2026-04-17 11:54:05', 33.4712, 0, 'none', 'stable', NULL, 'Minor fatigue-related changes were detected, but they did not reach warning level.'),
(224, 12, 'bicep_curl', 'webcam', NULL, NULL, 9, 7, 2, 2, 0, '2026-04-17 11:57:10', '2026-04-17 11:57:44', 5, '2026-04-17 11:57:10', 16.3832, 12.5567, 'none', 'stable', NULL, 'Minor fatigue-related changes were detected, but they did not reach warning level.'),
(225, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-17 12:11:39', '2026-04-17 12:12:13', 3, '2026-04-17 12:11:39', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(226, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 11, 0, 0, 0, '2026-04-17 12:33:32', '2026-04-17 12:34:29', 5, '2026-04-17 12:33:32', 1.08599, 1.08599, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(227, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-04-17 12:47:26', '2026-04-17 12:48:31', 4, '2026-04-17 12:47:26', 13.6272, 0.672813, 'none', 'recovering', NULL, 'No clear fatigue escalation was detected in this session.'),
(228, 12, 'bicep_curl', 'webcam', NULL, NULL, 15, 15, 0, 0, 0, '2026-04-17 12:59:30', '2026-04-17 13:00:54', 5, '2026-04-17 12:59:30', 6.68017, 2.15001, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(229, 12, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 13:01:07', '2026-04-17 13:01:09', 3, '2026-04-17 13:01:07', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(230, 12, 'bicep_curl', 'webcam', NULL, NULL, 15, 15, 0, 0, 0, '2026-04-17 13:02:41', '2026-04-17 13:04:44', 6, '2026-04-17 13:02:41', 23.6949, 23.6949, 'low', 'rising', NULL, 'Early fatigue signs detected; maintain control and monitor form.'),
(231, 12, 'shoulder_press', 'webcam', NULL, NULL, 15, 8, 7, 7, 0, '2026-04-17 13:05:02', '2026-04-17 13:06:51', 5, '2026-04-17 13:05:02', 6.74816, 0, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(232, 12, 'lateral_raise', 'webcam', NULL, NULL, 15, 14, 1, 1, 0, '2026-04-17 13:07:17', '2026-04-17 13:08:45', 5, '2026-04-17 13:07:17', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(233, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 13:46:15', NULL, NULL, '2026-04-17 13:46:15', NULL, NULL, NULL, NULL, NULL, NULL),
(234, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 11, 0, 0, 0, '2026-04-17 13:48:56', '2026-04-17 13:49:49', 4, '2026-04-17 13:48:56', 9.54394, 9.54394, 'none', 'stable', NULL, 'No clear fatigue escalation was detected in this session.'),
(235, 12, 'bicep_curl', 'webcam', NULL, NULL, 15, 15, 0, 0, 0, '2026-04-17 13:59:52', '2026-04-17 14:00:40', 5, '2026-04-17 13:59:52', 18.4274, 4.85095, 'none', 'recovering', NULL, 'Minor fatigue-related changes were detected, but they did not reach warning level.'),
(236, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 14:12:07', '2026-04-17 14:12:45', 3, '2026-04-17 14:12:07', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(237, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-04-17 14:13:36', '2026-04-17 14:13:58', 3, '2026-04-17 14:13:36', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(238, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-17 14:18:14', '2026-04-17 14:18:53', 5, '2026-04-17 14:18:14', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(239, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-04-17 14:22:12', '2026-04-17 14:22:41', 4, '2026-04-17 14:22:12', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(240, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-17 15:16:52', '2026-04-17 15:17:13', 3, '2026-04-17 15:16:52', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(241, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 12, 0, 0, 0, '2026-04-17 15:17:55', '2026-04-17 15:19:18', 4, '2026-04-17 15:17:55', 36.2058, 36.2058, 'low', 'sharply_rising', NULL, 'Early fatigue signs detected; maintain control and monitor form.'),
(242, 12, 'bicep_curl', 'webcam', NULL, NULL, 24, 17, 7, 7, 0, '2026-04-17 23:58:06', '2026-04-17 23:59:50', 7, '2026-04-17 23:58:06', 76.2038, 68, 'moderate', 'sharply_rising', 10, 'Fatigue has been building since around Rep 10; form may degrade if the set continues.'),
(243, 12, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-04-18 00:51:44', '2026-04-18 00:52:12', 3, '2026-04-18 00:51:44', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(244, 12, 'bicep_curl', 'webcam', NULL, NULL, 15, 11, 4, 4, 0, '2026-04-18 00:52:26', '2026-04-18 00:53:09', 5, '2026-04-18 00:52:26', 69.3334, 69.3334, 'moderate', 'sharply_rising', 13, 'Fatigue has been building since around Rep 13; form may degrade if the set continues.'),
(245, 12, 'bicep_curl', 'webcam', NULL, NULL, 2, 1, 1, 1, 0, '2026-04-18 01:03:17', '2026-04-18 01:03:27', 4, '2026-04-18 01:03:17', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(246, 12, 'bicep_curl', 'webcam', NULL, NULL, 15, 15, 0, 0, 0, '2026-04-18 02:02:12', '2026-04-18 02:03:15', 5, '2026-04-18 02:02:12', 28.1159, 0.611822, 'none', 'recovering', NULL, 'Minor fatigue-related changes were detected, but they did not reach warning level.'),
(247, 12, 'bicep_curl', 'webcam', NULL, NULL, 4, 2, 2, 2, 0, '2026-04-18 02:10:50', '2026-04-18 02:11:45', 3, '2026-04-18 02:10:50', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(248, 12, 'shoulder_press', 'webcam', NULL, NULL, 5, 1, 4, 4, 0, '2026-04-18 02:12:44', '2026-04-18 02:13:22', 3, '2026-04-18 02:12:44', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(249, 12, 'lateral_raise', 'webcam', NULL, NULL, 13, 3, 10, 10, 0, '2026-04-18 02:13:46', '2026-04-18 02:14:40', 4, '2026-04-18 02:13:46', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(250, 12, 'bicep_curl', 'webcam', NULL, NULL, 4, 1, 3, 3, 0, '2026-04-18 02:15:08', '2026-04-18 02:15:47', 3, '2026-04-18 02:15:08', 0, 0, 'none', 'stable', NULL, 'Fatigue data was limited for this session.'),
(251, 3, 'bicep_curl', 'webcam', NULL, NULL, 19, 11, 8, 8, 0, '2026-04-18 03:44:48', '2026-04-18 03:46:55', 5, '2026-04-18 03:44:48', 74.4537, 71.6743, 'moderate', 'stable', 12, 'Moderate fatigue detected; monitor form closely and consider resting.'),
(252, 3, 'bicep_curl', 'webcam', NULL, NULL, 31, 27, 4, 4, 0, '2026-04-18 17:54:25', '2026-04-18 17:56:55', 16, '2026-04-18 17:54:25', 48.0247, 45, 'moderate', 'stable', 18, 'Moderate fatigue detected; monitor form closely and consider resting.'),
(253, 3, 'bicep_curl', 'webcam', NULL, NULL, 15, 15, 0, 0, 1, '2026-04-18 18:01:41', '2026-04-18 18:02:38', 11, '2026-04-18 18:01:41', 45.9728, 45.9728, 'high', 'sharply_rising', 13, 'High fatigue detected from around Rep 13; stopping is recommended.'),
(254, 3, 'bicep_curl', 'webcam', NULL, NULL, 35, 33, 2, 2, 1, '2026-04-18 18:03:42', '2026-04-18 18:06:30', 17, '2026-04-18 18:03:42', 55.1179, 55.1179, 'high', 'rising', 9, 'High fatigue detected from around Rep 9; stopping is recommended.');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int NOT NULL,
  `full_name` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('user','trainer','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user',
  `age` int DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `gender` enum('male','female','other','prefer_not_to_say') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `profile_photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qualification` varchar(190) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `years_experience` tinyint UNSIGNED DEFAULT NULL,
  `specializations` json DEFAULT NULL,
  `accepting_trainees` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  `trainer_id` int DEFAULT NULL,
  `account_status` enum('pending','approved','rejected','suspended') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `twofa_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `failed_login_attempts` int NOT NULL DEFAULT '0',
  `lock_until` datetime DEFAULT NULL,
  `last_failed_login` timestamp NULL DEFAULT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `theme` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'default'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `full_name`, `email`, `password_hash`, `role`, `age`, `birthdate`, `gender`, `bio`, `profile_photo`, `qualification`, `years_experience`, `specializations`, `accepting_trainees`, `created_at`, `last_login`, `trainer_id`, `account_status`, `twofa_enabled`, `failed_login_attempts`, `lock_until`, `last_failed_login`, `email_verified_at`, `theme`) VALUES
(1, 'LiftRight Admin', 'admin@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'admin', 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2025-12-16 15:18:20', '2026-04-17 11:33:43', NULL, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'default'),
(2, 'LiftRight Trainer', 'trainer@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'trainer', 26, NULL, NULL, 'wasdasdadsas', 'uploads/profile_photos/user_2.png', '312das', 3, '[\"sdasdasdsada\"]', 1, '2025-12-16 15:18:20', '2026-04-18 03:48:05', NULL, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'light'),
(3, 'Test Trainee User1', 'user@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'user', 21, '2003-11-14', 'male', 'Test Traineeeeeeee', 'uploads/profile_photos/user_3.png', NULL, NULL, NULL, 1, '2025-12-16 15:18:20', '2026-05-08 03:02:53', 2, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'default'),
(10, 'Test', 'zacgames.tv@gmail.com', '$2y$10$Wwem4iJxiP2OKtyqbb7u.OUpGg7awdcz16QzH/Oe6tLQ/PCUeYG4m', 'user', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-03-31 09:27:19', '2026-04-06 08:19:37', NULL, 'approved', 0, 0, NULL, NULL, '2026-03-31 17:27:19', 'default'),
(11, 'Zyrus Crispino', 'crispino.zyrus@gmail.com', '$2y$10$6/DI8II51MVya41m9mnExONOSKpMk8gMfiZ4RqBPTz/Q4Lxyhr13u', 'user', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-04-06 08:31:27', NULL, NULL, 'approved', 0, 0, NULL, NULL, '2026-04-06 08:31:27', 'default'),
(12, 'Febrilo Par', 'diamondthekidrs44@gmail.com', '$2y$10$hQrIxA2Is.JOQFt2h6eFBOsUajtZvxhkLCTzC0J8uAeM4lDjqLtAK', 'user', NULL, '2004-02-17', 'male', 'Hi! I\'m one of the contributors to this thesis, and I\'m also the CEO of Hotdog.', 'uploads/profile_photos/user_12.jpg', NULL, NULL, NULL, 1, '2026-04-09 16:18:31', '2026-04-18 02:21:58', 2, 'approved', 0, 0, NULL, NULL, '2026-04-09 16:18:31', 'default'),
(13, 'nicolecfmartin21@gmail.com', 'nicolecfmartin21@gmail.com', '$2y$10$8/H9qznC/k/NRS1MRVbdCurW.SH3Rd7Vf1Yi6mNE.l9U.K630hXeu', 'user', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-04-16 08:59:09', '2026-04-16 13:38:46', 2, 'approved', 0, 0, NULL, NULL, '2026-04-16 08:59:09', 'default');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `auth_audit_logs`
--
ALTER TABLE `auth_audit_logs`
  ADD PRIMARY KEY (`event_id`),
  ADD KEY `idx_auth_logs_user` (`user_id`),
  ADD KEY `idx_auth_logs_type` (`event_type`),
  ADD KEY `idx_auth_logs_time` (`created_at`);

--
-- Indexes for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD PRIMARY KEY (`verif_id`),
  ADD KEY `idx_ev_user` (`user_id`),
  ADD KEY `idx_ev_exp` (`expires_at`),
  ADD KEY `idx_ev_consumed` (`consumed_at`),
  ADD KEY `idx_ev_pending` (`pending_id`);

--
-- Indexes for table `error_thresholds`
--
ALTER TABLE `error_thresholds`
  ADD PRIMARY KEY (`threshold_id`),
  ADD UNIQUE KEY `uq_threshold` (`exercise_type`,`metric_key`,`compare_op`),
  ADD KEY `idx_threshold_exercise` (`exercise_type`),
  ADD KEY `idx_threshold_enabled` (`enabled`);

--
-- Indexes for table `expert_reviews`
--
ALTER TABLE `expert_reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD UNIQUE KEY `uq_review_once` (`log_id`,`trainer_id`),
  ADD KEY `fk_review_trainer` (`trainer_id`),
  ADD KEY `idx_reviews_log` (`log_id`);

--
-- Indexes for table `feedback`
--
ALTER TABLE `feedback`
  ADD PRIMARY KEY (`feedback_id`),
  ADD KEY `idx_feedback_log` (`log_id`),
  ADD KEY `idx_feedback_type` (`feedback_type`);

--
-- Indexes for table `login_otps`
--
ALTER TABLE `login_otps`
  ADD PRIMARY KEY (`otp_id`),
  ADD KEY `idx_login_otps_user` (`user_id`),
  ADD KEY `idx_login_otps_exp` (`expires_at`),
  ADD KEY `idx_login_otps_consumed` (`consumed_at`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `idx_msg_recipient_read` (`recipient_id`,`is_read`),
  ADD KEY `idx_msg_created` (`created_at`),
  ADD KEY `fk_msg_sender` (`sender_id`),
  ADD KEY `fk_msg_log` (`log_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notif_id`),
  ADD KEY `idx_notif_user_read` (`user_id`,`is_read`),
  ADD KEY `idx_notif_created` (`created_at`),
  ADD KEY `idx_notif_log` (`log_id`),
  ADD KEY `fk_notif_from_user` (`from_user_id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`reset_id`),
  ADD KEY `idx_pwreset_user` (`user_id`),
  ADD KEY `idx_pwreset_exp` (`expires_at`),
  ADD KEY `idx_pwreset_consumed` (`consumed_at`);

--
-- Indexes for table `pending_registrations`
--
ALTER TABLE `pending_registrations`
  ADD PRIMARY KEY (`pending_id`),
  ADD UNIQUE KEY `uniq_pending_email` (`email`);

--
-- Indexes for table `profile_change_requests`
--
ALTER TABLE `profile_change_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `fk_pcr_user` (`user_id`),
  ADD KEY `fk_pcr_admin` (`reviewed_by`);

--
-- Indexes for table `rep_metrics`
--
ALTER TABLE `rep_metrics`
  ADD PRIMARY KEY (`rep_id`),
  ADD UNIQUE KEY `uq_rep` (`log_id`,`rep_index`),
  ADD KEY `idx_rep_log` (`log_id`);

--
-- Indexes for table `rep_snapshots`
--
ALTER TABLE `rep_snapshots`
  ADD PRIMARY KEY (`snapshot_id`),
  ADD UNIQUE KEY `uq_rep_snapshot` (`log_id`,`rep_index`),
  ADD KEY `idx_rep_snapshot_log` (`log_id`);

--
-- Indexes for table `sus_responses`
--
ALTER TABLE `sus_responses`
  ADD PRIMARY KEY (`sus_id`),
  ADD KEY `idx_sus_user_date` (`user_id`,`created_at`);

--
-- Indexes for table `trainer_applications`
--
ALTER TABLE `trainer_applications`
  ADD PRIMARY KEY (`app_id`),
  ADD KEY `idx_trainer_app_user` (`user_id`),
  ADD KEY `idx_trainer_app_status` (`status`),
  ADD KEY `idx_trainer_app_reviewed_by` (`reviewed_by`);

--
-- Indexes for table `trainer_invites`
--
ALTER TABLE `trainer_invites`
  ADD PRIMARY KEY (`invite_id`),
  ADD UNIQUE KEY `uniq_pending_pair` (`trainee_id`,`trainer_id`,`status`),
  ADD UNIQUE KEY `uniq_token` (`token`),
  ADD KEY `idx_trainer_status` (`trainer_id`,`status`),
  ADD KEY `idx_trainee_status` (`trainee_id`,`status`);

--
-- Indexes for table `trainer_rating_summary`
--
ALTER TABLE `trainer_rating_summary`
  ADD PRIMARY KEY (`trainer_id`);

--
-- Indexes for table `trainer_reviews`
--
ALTER TABLE `trainer_reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD UNIQUE KEY `uniq_trainer_trainee` (`trainer_id`,`trainee_id`),
  ADD KEY `idx_trainer` (`trainer_id`),
  ADD KEY `idx_trainee` (`trainee_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_trainer_status` (`trainer_id`,`status`);

--
-- Indexes for table `trainer_review_flags`
--
ALTER TABLE `trainer_review_flags`
  ADD PRIMARY KEY (`flag_id`),
  ADD KEY `idx_review` (`review_id`),
  ADD KEY `idx_trainer` (`trainer_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `training_logs`
--
ALTER TABLE `training_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_logs_user_date` (`user_id`,`created_at`),
  ADD KEY `idx_logs_exercise_date` (`exercise_type`,`created_at`),
  ADD KEY `idx_logs_fatigue` (`fatigue_flag`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_role` (`role`),
  ADD KEY `idx_users_trainer_id` (`trainer_id`),
  ADD KEY `idx_users_trainer_filters` (`role`,`account_status`,`years_experience`,`gender`),
  ADD KEY `idx_users_full_name` (`full_name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `auth_audit_logs`
--
ALTER TABLE `auth_audit_logs`
  MODIFY `event_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=137;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `verif_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `error_thresholds`
--
ALTER TABLE `error_thresholds`
  MODIFY `threshold_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `expert_reviews`
--
ALTER TABLE `expert_reviews`
  MODIFY `review_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `feedback_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=590;

--
-- AUTO_INCREMENT for table `login_otps`
--
ALTER TABLE `login_otps`
  MODIFY `otp_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `message_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notif_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `reset_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `pending_registrations`
--
ALTER TABLE `pending_registrations`
  MODIFY `pending_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `profile_change_requests`
--
ALTER TABLE `profile_change_requests`
  MODIFY `request_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `rep_metrics`
--
ALTER TABLE `rep_metrics`
  MODIFY `rep_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1115;

--
-- AUTO_INCREMENT for table `rep_snapshots`
--
ALTER TABLE `rep_snapshots`
  MODIFY `snapshot_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1928;

--
-- AUTO_INCREMENT for table `sus_responses`
--
ALTER TABLE `sus_responses`
  MODIFY `sus_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `trainer_applications`
--
ALTER TABLE `trainer_applications`
  MODIFY `app_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `trainer_invites`
--
ALTER TABLE `trainer_invites`
  MODIFY `invite_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `trainer_reviews`
--
ALTER TABLE `trainer_reviews`
  MODIFY `review_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `trainer_review_flags`
--
ALTER TABLE `trainer_review_flags`
  MODIFY `flag_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `training_logs`
--
ALTER TABLE `training_logs`
  MODIFY `log_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=255;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `auth_audit_logs`
--
ALTER TABLE `auth_audit_logs`
  ADD CONSTRAINT `fk_auth_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `email_verifications`
--
ALTER TABLE `email_verifications`
  ADD CONSTRAINT `fk_email_verif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `expert_reviews`
--
ALTER TABLE `expert_reviews`
  ADD CONSTRAINT `fk_review_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_review_trainer` FOREIGN KEY (`trainer_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `fk_feedback_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `login_otps`
--
ALTER TABLE `login_otps`
  ADD CONSTRAINT `fk_login_otps_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_msg_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_msg_recipient` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_msg_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_from_user` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_notif_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `fk_password_resets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `profile_change_requests`
--
ALTER TABLE `profile_change_requests`
  ADD CONSTRAINT `fk_pcr_admin` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_pcr_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `rep_metrics`
--
ALTER TABLE `rep_metrics`
  ADD CONSTRAINT `fk_rep_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `rep_snapshots`
--
ALTER TABLE `rep_snapshots`
  ADD CONSTRAINT `fk_rep_snapshot_log` FOREIGN KEY (`log_id`) REFERENCES `training_logs` (`log_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `sus_responses`
--
ALTER TABLE `sus_responses`
  ADD CONSTRAINT `fk_sus_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `trainer_applications`
--
ALTER TABLE `trainer_applications`
  ADD CONSTRAINT `fk_trainer_app_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_trainer_app_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `trainer_invites`
--
ALTER TABLE `trainer_invites`
  ADD CONSTRAINT `fk_inv_trainee` FOREIGN KEY (`trainee_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_inv_trainer` FOREIGN KEY (`trainer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `trainer_rating_summary`
--
ALTER TABLE `trainer_rating_summary`
  ADD CONSTRAINT `fk_trs_trainer` FOREIGN KEY (`trainer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `trainer_review_flags`
--
ALTER TABLE `trainer_review_flags`
  ADD CONSTRAINT `fk_flag_review` FOREIGN KEY (`review_id`) REFERENCES `trainer_reviews` (`review_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_flag_trainer` FOREIGN KEY (`trainer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `training_logs`
--
ALTER TABLE `training_logs`
  ADD CONSTRAINT `fk_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_trainer` FOREIGN KEY (`trainer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
