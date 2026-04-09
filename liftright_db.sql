-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 06, 2026 at 05:22 AM
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
  `event_type` enum('login_success','login_fail','login_blocked','otp_sent','otp_verify_success','otp_verify_fail','email_verify_sent','email_verify_success','email_verify_fail','register_pending','trainer_application_approved','trainer_application_rejected','profile_change_approved','profile_change_rejected','admin_set_role','admin_set_status','admin_unlink_trainer','admin_delete_user','password_reset_requested','password_reset_success','password_reset_failed') COLLATE utf8mb4_unicode_ci NOT NULL,
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
(25, 3, 'login_success', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 OPR/128.0.0.0', '{\"role\": \"user\"}', '2026-04-04 03:44:23');

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
(5, NULL, '$2y$10$7D8RlS.l66JGEdTAhCOqQ.N/RtMZSsVOTuvZt5K9EwQhn7zrkyj1G', '2026-02-24 16:42:26', NULL, '2026-02-24 08:27:26', 2),
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
(21, 3, '$2y$10$UqrzALdbYEJAaUtHpFOBzuzKNisuH6lIZ/K9jUGOGe2Xt8UMit6ii', '2026-03-31 18:09:02', NULL, '2026-03-31 09:54:02', NULL);

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
(4, 162, 2, 4, 'Ayos yan pagpatuloy mo pa', NULL, NULL, '2026-03-18 09:46:04');

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
(271, 174, 'posture', 'danger', 'Elbow drifting a lot (both)', '2026-04-01 06:28:12', '{\"all\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"rep\": 10}');

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
(59, 3, 'assignment', 'Trainer accepted your request. You are now linked.', NULL, 2, 1, '2026-04-01 06:30:19');

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

--
-- Dumping data for table `pending_registrations`
--

INSERT INTO `pending_registrations` (`pending_id`, `full_name`, `email`, `password_hash`, `role`, `age`, `affiliation`, `credential_type`, `credential_ref`, `statement`, `proof_file`, `proof_mime`, `created_at`) VALUES
(2, 'Zyrus Crispino', 'crispino.zyrus@gmail.com', '$2y$10$t4T//ML/G5wE4IEkyAHJSuZzuyekzAHxevsV02N/0Gau/YU3dfPTO', 'user', 22, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-24 08:27:26');

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
  `requested_gender` enum('male','female','other','prefer_not_to_say') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_bio` text COLLATE utf8mb4_unicode_ci,
  `requested_profile_photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_qualification` varchar(190) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
(6, 2, 'LiftRight Trainer', 'trainer@liftright.local', NULL, NULL, NULL, 'wasdasdadsas', 'uploads/pending_profiles/p_2_8f5090a4d771.jpg', '312das', 3, '[\"sdasdasdsada\"]', 'approved', '2026-02-28 11:40:26', '2026-02-28 11:40:34', 1, '');

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
  `rep_meta` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rep_metrics`
--

INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`) VALUES
(1, 1, 1, 820, 0.82, 0.18, 0.93, 'good', -0.21, '2025-12-16 15:18:44', NULL),
(2, 1, 2, 870, 0.79, 0.2, 0.92, 'good', -0.18, '2025-12-16 15:18:44', NULL),
(3, 1, 3, 960, 0.61, 0.27, 0.9, 'bad', 0.14, '2025-12-16 15:18:44', NULL),
(4, 2, 1, 980, 0.71, 0.24, 0.91, 'good', -0.1, '2025-12-16 15:18:44', NULL),
(5, 2, 2, 1120, 0.57, 0.33, 0.88, 'bad', 0.28, '2025-12-16 15:18:44', NULL),
(6, 2, 3, 1180, 0.52, 0.36, 0.86, 'bad', 0.35, '2025-12-16 15:18:44', NULL),
(7, 3, 1, 900, 0.76, 0.22, 0.92, 'good', -0.12, '2025-12-16 15:18:44', NULL),
(8, 3, 2, 1040, 0.58, 0.31, 0.89, 'bad', 0.22, '2025-12-16 15:18:44', NULL),
(9, 3, 3, 1100, 0.54, 0.34, 0.87, 'bad', 0.3, '2025-12-16 15:18:44', NULL),
(10, 6, 1, 7858, 173.096, 0.080673, 0.63766, 'bad', -0.735833, '2025-12-16 15:42:00', NULL),
(11, 6, 2, 2201, 165.037, 0.0225981, 0.78353, 'good', 0.0259225, '2025-12-16 15:42:01', NULL),
(12, 6, 3, 2183, 162.348, 0.0595842, 0.871811, 'good', 0.0294182, '2025-12-16 15:42:01', NULL),
(13, 6, 4, 2196, 163.977, 0.0490298, 0.89875, 'good', 0.0284478, '2025-12-16 15:42:01', NULL),
(14, 6, 5, 2002, 161.99, 0.0560793, 0.905292, 'bad', -0.0053243, '2025-12-16 15:42:01', NULL),
(15, 6, 6, 2200, 149.176, 0.0634695, 0.903285, 'bad', -0.0773745, '2025-12-16 15:42:01', NULL),
(16, 6, 7, 2194, 167.388, 0.0510686, 0.902458, 'good', 0.0837952, '2025-12-16 15:42:01', NULL),
(17, 6, 8, 2366, 129.572, 0.0312399, 0.900192, 'bad', -0.725101, '2025-12-16 15:42:01', NULL),
(18, 6, 9, 2001, 173.77, 0.0457862, 0.905305, 'bad', -0.0540958, '2025-12-16 15:42:01', NULL),
(19, 6, 10, 2147, 167.833, 0.0457972, 0.896895, 'good', 0.0761759, '2025-12-16 15:42:01', NULL),
(20, 6, 11, 2783, 171.255, 0.0472899, 0.896884, 'good', 0.117082, '2025-12-16 15:42:01', NULL),
(21, 7, 1, 3388, 165.505, 0.166974, 0.666523, 'bad', -0.0402354, '2025-12-16 15:44:27', NULL),
(22, 7, 2, 1605, 170.088, 0.0544593, 0.788342, 'bad', -0.102785, '2025-12-16 15:44:27', NULL),
(23, 7, 3, 3167, 146.917, 0.0814012, 0.840871, 'bad', -0.376511, '2025-12-16 15:44:27', NULL),
(24, 9, 1, 9019, 164.647, 0.379041, 0.649708, 'bad', -0.735837, '2025-12-16 16:05:50', NULL),
(25, 9, 2, 7649, 172.065, 0.0443829, 0.884427, 'bad', -0.735817, '2025-12-16 16:05:50', NULL),
(26, 9, 3, 2437, 173.978, 0.0509671, 0.903304, 'good', 0.0767213, '2025-12-16 16:05:50', NULL),
(27, 9, 4, 1805, 169.727, 0.0713813, 0.88077, 'bad', -0.00839751, '2025-12-16 16:05:50', NULL),
(28, 9, 5, 2043, 168.734, 0.0562414, 0.881708, 'good', 0.0679527, '2025-12-16 16:05:50', NULL),
(29, 9, 6, 2993, 174.499, 0.0587825, 0.886609, 'good', 0.116987, '2025-12-16 16:05:50', NULL),
(30, 9, 7, 2768, 168.762, 0.060294, 0.877282, 'good', 0.0621909, '2025-12-16 16:05:50', NULL),
(31, 9, 8, 3734, 97.023, 0.0600447, 0.924754, 'bad', -0.735837, '2025-12-16 16:05:50', NULL),
(32, 9, 9, 13420, 140.225, 0.0639284, 0.975708, 'bad', -0.735837, '2025-12-16 16:05:50', NULL),
(33, 11, 1, 3403, 1.46185, 0.134891, 0.766881, 'bad', -0.235058, '2025-12-16 16:26:05', NULL),
(34, 11, 2, 3060, 1.39852, 0.124065, 0.770497, 'bad', -0.17256, '2025-12-16 16:26:05', NULL),
(35, 11, 3, 2595, 1.40223, 0.126726, 0.771451, 'bad', -0.167435, '2025-12-16 16:26:05', NULL),
(36, 11, 4, 2834, 1.33283, 0.130465, 0.769565, 'bad', -0.203341, '2025-12-16 16:26:05', NULL),
(37, 11, 5, 2861, 1.29935, 0.120452, 0.76543, 'bad', -0.164476, '2025-12-16 16:26:05', NULL),
(38, 11, 6, 3026, 1.39877, 0.12297, 0.772472, 'bad', -0.165668, '2025-12-16 16:26:05', NULL),
(39, 11, 7, 2820, 1.26023, 0.10841, 0.724801, 'bad', -0.111303, '2025-12-16 16:26:05', NULL),
(40, 12, 1, 2412, 0.998028, 0.0451839, 0.944008, 'bad', -0.329878, '2025-12-16 16:27:11', NULL),
(41, 12, 2, 3398, 1.86042, 0.0713655, 0.952826, 'bad', -0.100267, '2025-12-16 16:27:11', NULL),
(42, 12, 3, 1395, 0.52981, 0.0348635, 0.917523, 'bad', -0.264802, '2025-12-16 16:27:11', NULL),
(43, 12, 4, 3431, 1.80887, 0.0546985, 0.936435, 'good', 0.0123083, '2025-12-16 16:27:11', NULL),
(44, 12, 5, 3645, 1.77558, 0.0514144, 0.945668, 'bad', -0.0384855, '2025-12-16 16:27:11', NULL),
(45, 12, 6, 3981, 1.77016, 0.0391085, 0.950093, 'bad', -0.192144, '2025-12-16 16:27:11', NULL),
(46, 13, 1, 5234, 159.768, 0.099645, 0.984575, 'bad', -0.670517, '2025-12-18 03:11:08', NULL),
(47, 13, 2, 2975, 156.562, 0.114205, 0.975709, 'bad', -0.160471, '2025-12-18 03:11:08', NULL),
(48, 13, 3, 2658, 158.569, 0.110856, 0.975714, 'bad', -0.0955522, '2025-12-18 03:11:08', NULL),
(49, 13, 4, 3215, 165.599, 0.131132, 0.969543, 'bad', -0.00521502, '2025-12-18 03:11:08', NULL),
(50, 13, 5, 3823, 171.126, 0.0674258, 0.958964, 'bad', -0.0286935, '2025-12-18 03:11:08', NULL),
(51, 13, 6, 2815, 167.076, 0.0741964, 0.963494, 'good', 0.109648, '2025-12-18 03:11:08', NULL),
(52, 13, 7, 2217, 161.766, 0.0676832, 0.967913, 'good', 0.0377659, '2025-12-18 03:11:08', NULL),
(53, 13, 8, 2206, 157.314, 0.0653031, 0.967073, 'bad', -0.0729687, '2025-12-18 03:11:08', NULL),
(54, 13, 9, 2283, 167.913, 0.0686071, 0.971694, 'good', 0.093386, '2025-12-18 03:11:08', NULL),
(55, 13, 10, 1974, 158.646, 0.0507018, 0.975945, 'bad', -0.0977481, '2025-12-18 03:11:08', NULL),
(56, 15, 1, 3804, 161.809, 0.0510914, 0.986487, 'bad', -0.375102, '2025-12-18 03:34:58', NULL),
(57, 15, 2, 3564, 159.409, 0.0830197, 0.975112, 'bad', -0.103472, '2025-12-18 03:34:58', NULL),
(58, 15, 3, 2926, 159.641, 0.118871, 0.970548, 'bad', -0.225054, '2025-12-18 03:34:58', NULL),
(59, 15, 4, 2666, 166.873, 0.114009, 0.97137, 'good', 0.0763706, '2025-12-18 03:34:58', NULL),
(60, 15, 5, 2608, 167.788, 0.0739779, 0.969813, 'good', 0.12292, '2025-12-18 03:34:58', NULL),
(61, 15, 6, 5323, 177.13, 0.100217, 0.978771, 'bad', -0.674112, '2025-12-18 03:34:58', NULL),
(62, 16, 1, 5449, 0.81788, 0.0625306, 0.702331, 'bad', -0.326209, '2025-12-18 03:35:50', NULL),
(63, 16, 2, 2369, 1.9807, 0.162693, 0.600566, 'bad', -0.333992, '2025-12-18 03:35:50', NULL),
(64, 17, 1, 5295, 4.11571, 2.23144, 0.787671, 'bad', -0.593459, '2025-12-18 03:36:27', NULL),
(65, 18, 1, 1831, 174.062, 0.0164443, 0.958606, 'bad', -0.185295, '2025-12-18 03:55:07', NULL),
(66, 18, 2, 4135, 171.733, 0.0333796, 0.966726, 'bad', -0.106151, '2025-12-18 03:55:07', NULL),
(67, 18, 3, 3585, 170.579, 0.0566112, 0.976331, 'good', 0.0840965, '2025-12-18 03:55:07', NULL),
(68, 20, 1, 6304, 159.791, 0.09846, 0.617875, 'bad', -0.630997, '2026-01-21 05:13:41', NULL),
(69, 20, 2, 2442, 156.826, 0.131624, 0.842804, 'bad', -0.057186, '2026-01-21 05:13:41', NULL),
(70, 20, 3, 2419, 162.682, 0.122457, 0.860763, 'bad', -0.0656358, '2026-01-21 05:13:41', NULL),
(71, 20, 4, 2429, 149.992, 0.0982155, 0.954084, 'bad', -0.0300327, '2026-01-21 05:13:41', NULL),
(72, 20, 5, 3633, 173.578, 0.0901147, 0.982326, 'bad', -0.306283, '2026-01-21 05:13:41', NULL),
(73, 20, 6, 2790, 167.975, 0.0860855, 0.98846, 'bad', -0.110965, '2026-01-21 05:13:41', NULL),
(74, 20, 7, 3202, 106.344, 0.0961589, 0.991349, 'bad', -0.49507, '2026-01-21 05:13:41', NULL),
(75, 20, 8, 1597, 156.292, 0.0931575, 0.992714, 'good', 0.0654208, '2026-01-21 05:13:41', NULL),
(76, 20, 9, 2194, 164.842, 0.0900667, 0.991728, 'bad', -0.00843886, '2026-01-21 05:13:41', NULL),
(77, 20, 10, 2410, 160.773, 0.0847282, 0.99101, 'bad', -0.00782555, '2026-01-21 05:13:41', NULL),
(78, 21, 1, 2841, 121.094, 0.0870322, 0.952085, 'bad', -0.309314, '2026-01-21 05:19:28', NULL),
(79, 21, 2, 2943, 154.924, 0.0727494, 0.970546, 'bad', -0.0785307, '2026-01-21 05:19:28', NULL),
(80, 22, 1, 2392, 149.466, 0.122431, 0.941616, 'bad', -0.0479871, '2026-01-21 05:22:59', NULL),
(81, 23, 1, 3669, 164.601, 0.406494, 0.766064, 'bad', -0.367241, '2026-01-21 05:26:18', NULL),
(82, 23, 2, 1987, 104.844, 0.0902702, 0.918063, 'bad', -0.442346, '2026-01-21 05:26:18', NULL),
(83, 24, 1, 4758, 131.622, 0.156482, 0.651115, 'bad', -0.548639, '2026-01-21 05:29:19', NULL),
(84, 24, 2, 6784, 154.478, 0.244475, 0.831264, 'bad', -0.667993, '2026-01-21 05:29:19', NULL),
(85, 24, 3, 2193, 111.954, 0.0822804, 0.940718, 'bad', -0.360985, '2026-01-21 05:29:19', NULL),
(86, 24, 4, 2011, 133.173, 0.0675652, 0.95148, 'bad', -0.0677044, '2026-01-21 05:29:19', NULL),
(87, 25, 1, 5878, 154.921, 0.187347, 0.639149, 'bad', -0.62714, '2026-01-21 05:33:02', NULL),
(88, 25, 2, 5909, 167.981, 0.154504, 0.83076, 'bad', -0.627308, '2026-01-21 05:33:02', NULL),
(89, 25, 3, 4430, 166.742, 0.0881009, 0.970252, 'bad', -0.419843, '2026-01-21 05:33:02', NULL),
(90, 38, 1, 9922, 166.078, 0, 0.962314, 'good', -0.683359, '2026-01-21 06:56:09', NULL),
(91, 38, 2, 3041, 169.095, 0, 0.9777, 'good', -0.201621, '2026-01-21 06:56:09', NULL),
(92, 39, 1, 14033, 173.652, 0, 0.977514, 'good', -0.683567, '2026-01-21 07:01:21', NULL),
(93, 39, 2, 2338, 163.357, 0, 0.98705, 'good', -0.0714775, '2026-01-21 07:01:21', NULL),
(94, 40, 1, 4167, 170.012, 0, 0.974324, 'good', -0.397436, '2026-01-21 07:01:44', NULL),
(95, 40, 2, 2630, 159.745, 0, 0.979772, 'good', -0.0897234, '2026-01-21 07:01:44', NULL),
(96, 41, 1, 3394, 169.076, 0, 0.984216, 'good', -0.259547, '2026-01-21 07:02:09', NULL),
(97, 41, 2, 2840, 157.857, 0, 0.988724, 'good', -0.114262, '2026-01-21 07:02:09', NULL),
(98, 43, 1, 8697, 166.742, NULL, 0.909111, 'bad', -0.68183, '2026-01-21 07:47:03', NULL),
(99, 43, 2, 2809, 161.759, NULL, 0.956604, 'bad', -0.122961, '2026-01-21 07:47:03', NULL),
(100, 43, 3, 2986, 168.37, NULL, 0.972244, 'bad', -0.188171, '2026-01-21 07:47:03', NULL),
(101, 43, 4, 5343, 154.476, NULL, 0.984287, 'bad', -0.54606, '2026-01-21 07:47:03', NULL),
(102, 43, 5, 3957, 163.637, NULL, 0.977664, 'bad', -0.335378, '2026-01-21 07:47:03', NULL),
(103, 43, 6, 2352, 165.339, NULL, 0.975896, 'bad', -0.0849855, '2026-01-21 07:47:03', NULL),
(104, 43, 7, 4593, 153.482, NULL, 0.971128, 'bad', -0.43305, '2026-01-21 07:47:03', NULL),
(105, 43, 8, 2377, 142.338, NULL, 0.977181, 'bad', -0.0703426, '2026-01-21 07:47:03', NULL),
(106, 43, 9, 4134, 154.45, NULL, 0.979838, 'bad', -0.350471, '2026-01-21 07:47:03', NULL),
(107, 43, 10, 1974, 158.032, NULL, 0.981299, 'bad', -0.0188986, '2026-01-21 07:47:03', NULL),
(108, 43, 11, 1994, 147.786, NULL, 0.983396, 'bad', -0.0172296, '2026-01-21 07:47:03', NULL),
(109, 43, 12, 1973, 157.996, NULL, 0.981491, 'bad', -0.0185767, '2026-01-21 07:47:03', NULL),
(110, 43, 13, 4889, 118.138, NULL, 0.98603, 'bad', -0.568255, '2026-01-21 07:47:03', NULL),
(111, 43, 14, 4169, 133.317, NULL, 0.983305, 'bad', -0.414869, '2026-01-21 07:47:03', NULL),
(112, 43, 15, 2802, 160.919, NULL, 0.989636, 'bad', -0.17019, '2026-01-21 07:47:03', NULL),
(113, 43, 16, 1762, 143.923, NULL, 0.990115, 'bad', -0.0974028, '2026-01-21 07:47:03', NULL),
(114, 43, 17, 1950, 112.813, NULL, 0.983953, 'bad', -0.351139, '2026-01-21 07:47:03', NULL),
(115, 43, 18, 4710, 98.7302, NULL, 0.985617, 'bad', -0.625529, '2026-01-21 07:47:03', NULL),
(116, 43, 19, 1771, 135.174, NULL, 0.986647, 'bad', -0.139676, '2026-01-21 07:47:03', NULL),
(117, 43, 20, 9209, 149.011, NULL, 0.987217, 'bad', -0.682755, '2026-01-21 07:47:03', NULL),
(118, 44, 1, 3457, 163.712, NULL, 0.972972, 'bad', -0.242591, '2026-01-21 07:47:35', NULL),
(119, 44, 2, 1984, 166.054, NULL, 0.976692, 'bad', -0.0623639, '2026-01-21 07:47:35', NULL),
(120, 44, 3, 2220, 141.121, NULL, 0.95132, 'bad', -0.0756699, '2026-01-21 07:47:35', NULL),
(121, 44, 4, 2196, 155.54, NULL, 0.968871, 'bad', -0.0280505, '2026-01-21 07:47:35', NULL),
(122, 44, 5, 2172, 156.427, NULL, 0.976709, 'bad', -0.0276759, '2026-01-21 07:47:35', NULL),
(123, 44, 6, 2171, 155.869, NULL, 0.979511, 'bad', -0.0264026, '2026-01-21 07:47:35', NULL),
(124, 45, 1, 11258, 148.409, NULL, 0.880664, 'bad', -0.683552, '2026-01-21 08:01:40', NULL),
(125, 45, 2, 2182, 170.707, NULL, 0.93265, 'bad', -0.113044, '2026-01-21 08:01:40', NULL),
(126, 45, 3, 2199, 153.091, NULL, 0.96365, 'bad', -0.0260954, '2026-01-21 08:01:40', NULL),
(127, 45, 4, 14263, 139.831, NULL, 0.992391, 'bad', -0.683567, '2026-01-21 08:01:40', NULL),
(128, 45, 5, 1987, 164.893, NULL, 0.98869, 'bad', -0.0537193, '2026-01-21 08:01:40', NULL),
(129, 45, 6, 2233, 116.537, NULL, 0.990526, 'bad', -0.318226, '2026-01-21 08:01:40', NULL),
(130, 45, 7, 2411, 110.373, NULL, 0.992208, 'bad', -0.400179, '2026-01-21 08:01:40', NULL),
(131, 45, 8, 2397, 122.423, NULL, 0.993393, 'bad', -0.270641, '2026-01-21 08:01:40', NULL),
(132, 47, 1, 6784, 161.899, 0.227323, 0.876238, 'bad', -0.667147, '2026-01-21 08:17:58', NULL),
(133, 47, 2, 2354, 163.105, 0.0464487, 0.95541, 'bad', -0.00132196, '2026-01-21 08:17:58', NULL),
(134, 47, 3, 2224, 148.11, 0.0663432, 0.972186, 'good', 0.0287156, '2026-01-21 08:17:58', NULL),
(135, 47, 4, 2387, 162.412, 0.0670506, 0.982414, 'bad', -0.00121378, '2026-01-21 08:17:58', NULL),
(136, 47, 5, 2406, 146.817, 0.0506017, 0.974497, 'good', 0.00743634, '2026-01-21 08:17:58', NULL),
(137, 47, 6, 2391, 154.063, 0.0417256, 0.976774, 'good', 0.0216089, '2026-01-21 08:17:58', NULL),
(138, 47, 7, 2418, 151.761, 0.0312564, 0.973609, 'good', 0.00728359, '2026-01-21 08:17:58', NULL),
(139, 47, 8, 4790, 102.271, 0.0534963, 0.987464, 'bad', -0.615356, '2026-01-21 08:17:58', NULL),
(140, 47, 9, 4000, 167.174, 0.0489667, 0.9882, 'bad', -0.344841, '2026-01-21 08:17:58', NULL),
(141, 47, 10, 3614, 155.714, 0.0849443, 0.987675, 'bad', -0.268948, '2026-01-21 08:17:58', NULL),
(142, 47, 11, 2796, 134.615, 0.0868121, 0.988147, 'bad', -0.186133, '2026-01-21 08:17:58', NULL),
(143, 47, 12, 1652, 137.941, 0.046969, 0.990059, 'good', 0.00145176, '2026-01-21 08:17:58', NULL),
(144, 47, 13, 6033, 121.761, 0.0572939, 0.990797, 'bad', -0.641439, '2026-01-21 08:17:58', NULL),
(145, 47, 14, 3428, 169.568, 0.0694103, 0.989136, 'bad', -0.226502, '2026-01-21 08:17:58', NULL),
(146, 52, 1, 6734, 170.419, 0, 0.867907, 'bad', -0.658722, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 179.28982543945312, \"min_angle\": 8.870448112487793, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}'),
(147, 52, 2, 2706, 163.576, 0, 0.901046, 'bad', -0.117395, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 173.64199829101562, \"min_angle\": 10.066011428833008, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.23255273699760437}'),
(148, 52, 3, 2394, 157.766, 0, 0.945328, 'bad', -0.0528621, '2026-01-21 08:39:43', '{\"reasons\": [\"Consistency drifting (ML)\"], \"max_angle\": 175.8173370361328, \"min_angle\": 18.051538467407227, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2221380919218063}'),
(149, 52, 4, 2810, 161.978, 0, 0.940984, 'bad', -0.12506, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 175.84732055664062, \"min_angle\": 13.869434356689451, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": false, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": [], \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2492063194513321}'),
(150, 52, 5, 2402, 152.876, 0, 0.952015, 'bad', -0.0466503, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 175.84732055664062, \"min_angle\": 22.970823287963867, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.8877519318307844, \"rom_ratio\": 0.97399584510217, \"drift_delta\": 0}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.24586953222751615}'),
(151, 52, 6, 2439, 148.521, 0, 0.951591, 'bad', -0.0542014, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 171.4605255126953, \"min_angle\": 22.93995475769043, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9012692376905476, \"rom_ratio\": 0.9438108769270416, \"drift_delta\": 0}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2207394391298294}'),
(152, 52, 7, 2582, 150.703, 0, 0.967358, 'bad', -0.0688575, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 171.4605255126953, \"min_angle\": 20.7578067779541, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9012692376905476, \"rom_ratio\": 0.9303906358372486, \"drift_delta\": -0.025130093097686768}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.21016760170459747}'),
(153, 52, 8, 16564, 141.342, 0, 0.969546, 'bad', -0.683567, '2026-01-21 08:39:43', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"max_angle\": 177.13262939453125, \"min_angle\": 35.79106140136719, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9541169345161712, \"rom_ratio\": 0.9169187715515128, \"drift_delta\": -0.025130093097686768}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}'),
(154, 52, 9, 17234, 131.818, 0, 0.987323, 'bad', -0.683567, '2026-01-21 08:39:43', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Fatigue trend - consider rest or lighter weight\"], \"max_angle\": 179.09915161132812, \"min_angle\": 47.28144073486328, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 55.00000000000001, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 1, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 6.120051465924412, \"rom_ratio\": 0.872597902761815, \"drift_delta\": 0.4541304677724838}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.7}'),
(155, 52, 10, 2381, 147.717, 0, 0.989718, 'bad', -0.0692615, '2026-01-21 08:39:43', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Fatigue trend - consider rest or lighter weight\"], \"max_angle\": 179.09915161132812, \"min_angle\": 31.3817138671875, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 55.00000000000001, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 1, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 6.120051465924412, \"rom_ratio\": 0.872597902761815, \"drift_delta\": 0.4541304677724838}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.4060981571674347}'),
(156, 52, 11, 2390, 148.4, 0, 0.989412, 'bad', -0.0487976, '2026-01-21 08:39:43', '{\"reasons\": [], \"max_angle\": 177.63243103027344, \"min_angle\": 29.23249626159668, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"stop_message\": \"\", \"fatigue_index\": 19.227434992790226, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0.6409144997596741, \"dur_ratio\": 0.8832566751343173, \"rom_ratio\": 0.9119604954652843, \"drift_delta\": 0.16022862493991852}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.2074006050825119}'),
(157, 52, 12, 2583, 146.861, 0, 0.989616, 'bad', -0.0763524, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"max_angle\": 177.51304626464844, \"min_angle\": 30.65174865722656, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (left)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.8832566751343173, \"rom_ratio\": 0.9119604954652843, \"drift_delta\": -0.03846892714500427}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.20084881782531736}'),
(158, 52, 13, 6750, 124.983, 0, 0.990348, 'bad', -0.661235, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"max_angle\": 177.5733184814453, \"min_angle\": 52.59041213989258, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 0, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbow steadier (right)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 0, \"dur_ratio\": 0.9546594730906364, \"rom_ratio\": 0.9066749584617108, \"drift_delta\": -0.03846892714500427}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.5365550518035889}'),
(159, 52, 14, 2622, 118.966, 0, 0.991268, 'bad', -0.334012, '2026-01-21 08:39:44', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"max_angle\": 175.34707641601562, \"min_angle\": 56.38128662109375, \"threshold\": 0.00011101242820883428, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"stop_message\": \"\", \"fatigue_index\": 30, \"baseline_ready\": true, \"rep_bad_reason\": \"\", \"rep_tip_reason\": \"Keep elbows steadier (both)\", \"fatigue_details\": {\"c_dur\": 0, \"c_rom\": 0, \"c_drift\": 1, \"dur_ratio\": 0.9688617570239574, \"rom_ratio\": 0.7716047503356319, \"drift_delta\": 0.26334773004055023}, \"stop_recommended\": false, \"elbow_drift_absmax\": 0.5092172622680664}'),
(160, 59, 1, 5918, 169.605, 0, 0.852071, 'good', -0.610375, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.32528603076934814}'),
(161, 59, 2, 2253, 171.418, 0, 0.975255, 'good', -0.128691, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3044107258319855}'),
(162, 59, 3, 2630, 167.937, 0, 0.981844, 'good', -0.136326, '2026-01-21 09:10:04', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2622838020324707}'),
(163, 59, 4, 2268, 172.683, 0, 0.983508, 'good', -0.137406, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1859431564807892}'),
(164, 59, 5, 5096, 176.287, 0, 0.988985, 'good', -0.557563, '2026-01-21 09:10:04', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4959814846515655}'),
(165, 59, 6, 3754, 173.332, 0, 0.992142, 'good', -0.408132, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 26.53618745971174, \"elbow_drift_absmax\": 0.7}'),
(166, 59, 7, 5375, 174.784, 0, 0.989793, 'good', -0.592709, '2026-01-21 09:10:04', '{\"reasons\": [\"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 43.757704989137046, \"elbow_drift_absmax\": 0.6936243772506714}'),
(167, 59, 8, 2631, 161.551, 0, 0.990731, 'good', -0.109397, '2026-01-21 09:10:04', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 33.54769640136213, \"elbow_drift_absmax\": 0.3713323473930359}'),
(168, 59, 9, 4867, 175.323, 0, 0.99289, 'bad', -0.54963, '2026-01-21 09:10:04', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 42.01306212597752, \"elbow_drift_absmax\": 0.7}'),
(169, 59, 10, 1749, 172.864, 0, 0.99004, 'good', -0.113716, '2026-01-21 09:10:04', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 8.03059458732605, \"elbow_drift_absmax\": 0.25232434272766113}'),
(170, 59, 11, 2130, 173.217, 0, 0.990724, 'good', -0.133999, '2026-01-21 09:10:04', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2666179835796356}'),
(171, 62, 1, 12149, 174.745, 0, 0.887926, 'good', -0.683565, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.46460798382759094}'),
(172, 62, 2, 2623, 166.52, 0, 0.988528, 'good', -0.124095, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22641436755657196}'),
(173, 62, 3, 2247, 166.03, 0, 0.992123, 'good', -0.0797447, '2026-01-21 09:21:47', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20102261006832123}'),
(174, 62, 4, 2373, 171.462, 0, 0.989915, 'good', -0.135225, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20140595734119415}'),
(175, 62, 5, 2376, 163.288, 0, 0.989284, 'good', -0.07459, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20319874584674835}'),
(176, 62, 6, 3266, 163.924, 0, 0.99164, 'good', -0.208927, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19082623720169067}'),
(177, 62, 7, 2230, 165.209, 0, 0.989737, 'good', -0.0727207, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19399471580982208}'),
(178, 62, 8, 4379, 176.145, 0, 0.992272, 'good', -0.457839, '2026-01-21 09:21:47', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.493680751881344, \"elbow_drift_absmax\": 0.23149646818637848}'),
(179, 62, 9, 2245, 125.076, 0, 0.992483, 'bad', -0.284637, '2026-01-21 09:21:47', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 3.3957266807556152, \"elbow_drift_absmax\": 0.6722539067268372}'),
(180, 62, 10, 2747, 161.119, 0, 0.989746, 'bad', -0.134736, '2026-01-21 09:21:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 27.706090807914737, \"elbow_drift_absmax\": 0.43408283591270447}'),
(181, 62, 11, 7140, 135.161, 0, 0.991856, 'good', -0.665085, '2026-01-21 09:21:47', '{\"reasons\": [\"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 27.706090807914737, \"elbow_drift_absmax\": 0.3292917013168335}'),
(182, 62, 12, 2623, 155.881, 0, 0.992572, 'good', -0.0779313, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 15.131154656410216, \"elbow_drift_absmax\": 0.25298792123794556}'),
(183, 62, 13, 2997, 104.562, 0, 0.993562, 'good', -0.484705, '2026-01-21 09:21:47', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 15.366686762676496, \"elbow_drift_absmax\": 0.3703940510749817}'),
(184, 62, 14, 4869, 141.436, 0, 0.993305, 'good', -0.49655, '2026-01-21 09:21:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 20.29896873365428, \"elbow_drift_absmax\": 0.43488672375679016}'),
(185, 62, 15, 8007, 168.558, 0, 0.995205, 'good', -0.677918, '2026-01-21 09:21:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 43.792721599129656, \"elbow_drift_absmax\": 0.4769136607646942}'),
(186, 63, 1, 9793, 169.995, 0, 0.827457, 'good', -0.683261, '2026-01-21 09:23:23', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.375911682844162}'),
(187, 63, 2, 2248, 163.163, 0, 0.965979, 'good', -0.06228, '2026-01-21 09:23:23', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2464689463376999}'),
(188, 63, 3, 2386, 133.009, 0, 0.984285, 'bad', -0.21754, '2026-01-21 09:23:23', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6477876305580139}'),
(189, 64, 1, 4030, 172.682, 0, 0.967955, 'good', -0.389258, '2026-01-21 09:24:35', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28266090154647827}'),
(190, 64, 2, 2117, 170.906, 0, 0.986923, 'good', -0.112787, '2026-01-21 09:24:35', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2895864248275757}'),
(191, 65, 1, 9185, 102.103, 0, 0.857504, 'bad', -0.6833, '2026-01-21 09:31:14', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6563076376914978}'),
(192, 65, 2, 4002, 134.783, 0, 0.990721, 'warning', -0.386703, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4653170108795166}'),
(193, 65, 3, 2002, 141.154, 0, 0.992149, 'warning', -0.0699449, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4243333339691162}'),
(194, 65, 4, 3988, 164.477, 0, 0.995505, 'warning', -0.362963, '2026-01-21 09:31:14', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.46540993452072144}'),
(195, 65, 5, 1995, 151.638, 0, 0.993096, 'good', -0.0145493, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2920394241809845}'),
(196, 65, 6, 2128, 148.837, 0, 0.989682, 'good', -0.0334229, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.34767061471939087}'),
(197, 65, 7, 2127, 171.262, 0, 0.991222, 'good', -0.11347, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20696058869361875}'),
(198, 65, 8, 2264, 151.587, 0, 0.992003, 'good', -0.0332493, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26511189341545105}'),
(199, 65, 9, 2117, 169.001, 0, 0.990955, 'good', -0.0947048, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26917046308517456}'),
(200, 65, 10, 2127, 161.991, 0, 0.992559, 'good', -0.04726, '2026-01-21 09:31:14', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2713639438152313}'),
(201, 65, 11, 2111, 112.111, 0, 0.993702, 'bad', -0.407349, '2026-01-21 09:31:14', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.675918459892273}'),
(202, 66, 1, 4336, 166.642, 0, 0.971944, 'good', -0.412583, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2318998426198959}'),
(203, 66, 2, 1998, 163.121, 0, 0.982444, 'good', -0.0430639, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19817207753658295}'),
(204, 66, 3, 2245, 164.138, 0, 0.988058, 'warning', -0.0670865, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2131891697645187}'),
(205, 66, 4, 2006, 164.568, 0, 0.989633, 'good', -0.0526123, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22231295704841617}'),
(206, 66, 5, 2117, 154.989, 0, 0.989566, 'good', -0.0209307, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2335340529680252}'),
(207, 66, 6, 2250, 156.017, 0, 0.98772, 'good', -0.033825, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.6654757261276245, \"elbow_drift_absmax\": 0.22785858809947968}'),
(208, 66, 7, 3509, 165.568, 0, 0.991148, 'warning', -0.269709, '2026-01-21 09:37:11', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 1.3465315103530884, \"elbow_drift_absmax\": 0.3645757734775543}'),
(209, 66, 8, 2750, 169.132, 0, 0.988952, 'good', -0.159893, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.7189168648312334, \"elbow_drift_absmax\": 0.2367648184299469}'),
(210, 66, 9, 2997, 163.957, 0, 0.990817, 'warning', -0.163695, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 5.122157091436281, \"elbow_drift_absmax\": 0.2373572736978531}'),
(211, 66, 10, 2744, 170.083, 0, 0.989625, 'warning', -0.16627, '2026-01-21 09:37:11', '{\"reasons\": [\"Consistency drifting (ML)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.7189168648312334, \"elbow_drift_absmax\": 0.22888554632663727}'),
(212, 66, 11, 2262, 167.028, 0, 0.989011, 'good', -0.0887133, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.0446657345690156, \"elbow_drift_absmax\": 0.23160088062286377}'),
(213, 66, 12, 2366, 165.39, 0, 0.989687, 'good', -0.0868989, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.0613250732421875, \"elbow_drift_absmax\": 0.2311573326587677}'),
(214, 66, 13, 2391, 160.252, 0, 0.990668, 'good', -0.061625, '2026-01-21 09:37:11', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.1145508289337158, \"elbow_drift_absmax\": 0.2347409576177597}'),
(215, 69, 1, 9774, 153.473, 0, 0.818485, 'good', -0.683237, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5271849632263184}'),
(216, 69, 2, 2102, 174.15, 0, 0.945224, 'good', -0.139894, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20203272998332977}'),
(217, 69, 3, 1704, 125.056, 0, 0.978747, 'bad', -0.257012, '2026-01-21 09:48:16', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6398125886917114}'),
(218, 69, 4, 2245, 129.544, 0, 0.988464, 'warning', -0.193445, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4893537163734436}'),
(219, 69, 5, 1720, 117.13, 0, 0.992937, 'warning', -0.326845, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5807831287384033}'),
(220, 69, 6, 2050, 159.041, 0, 0.991658, 'good', -0.0287383, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27310922741889954}'),
(221, 69, 7, 1976, 153.131, 0, 0.993116, 'good', -0.0124984, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2805273234844208}'),
(222, 69, 8, 1645, 120.088, 0, 0.992969, 'warning', -0.287272, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5508155822753906}'),
(223, 69, 9, 3641, 143.722, 0, 0.991829, 'warning', -0.299714, '2026-01-21 09:48:16', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 3.714201450347901, \"elbow_drift_absmax\": 0.5203053951263428}'),
(224, 69, 10, 2037, 170.21, 0, 0.991844, 'good', -0.0985763, '2026-01-21 09:48:16', '{\"reasons\": [], \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 3.714201450347901, \"elbow_drift_absmax\": 0.22950762510299683}'),
(225, 72, 1, 4377, 0.804141, 0.0726823, 0.986813, 'bad', -0.507287, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0}'),
(226, 72, 2, 2599, 1.4352, 0.0864629, 0.991234, 'bad', -0.459475, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Don\'t curl (elbow too bent)\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 0}'),
(227, 72, 3, 616, 0.84936, 0.0982458, 0.989533, 'good', -0.498027, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 167.2865447998047, \"is_warning\": true, \"fatigue_index\": 0}'),
(228, 72, 4, 751, 0.911635, 0.087797, 0.988378, 'good', -0.463161, '2026-01-22 06:44:36', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 166.0986785888672, \"is_warning\": false, \"fatigue_index\": 0}'),
(229, 73, 1, 865, 1.34837, 0.0946827, 0.98621, 'good', -0.486382, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 167.3314208984375, \"is_warning\": false, \"fatigue_index\": 0}'),
(230, 73, 2, 626, 0.597754, 0.07609, 0.988099, 'good', -0.411617, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 171.2187042236328, \"is_warning\": false, \"fatigue_index\": 0}'),
(231, 73, 3, 733, 0.661733, 0.0760713, 0.989625, 'good', -0.385406, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 165.86241149902344, \"is_warning\": true, \"fatigue_index\": 0}'),
(232, 73, 4, 733, 0.75664, 0.094338, 0.99076, 'good', -0.489544, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 168.25662231445312, \"is_warning\": true, \"fatigue_index\": 0}'),
(233, 73, 5, 615, 0.362155, 0.108971, 0.988792, 'good', -0.506079, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [\"Range dropping - lighten weight or rest\"], \"label_ui\": \"warning\", \"elbow_min\": 167.52662658691406, \"is_warning\": true, \"fatigue_index\": 0}'),
(234, 73, 6, 620, 0.539877, 0.0932376, 0.990903, 'good', -0.490615, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 166.6708526611328, \"is_warning\": false, \"fatigue_index\": 0}'),
(235, 73, 7, 627, 0.401175, 0.0848932, 0.990646, 'good', -0.466573, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 168.265869140625, \"is_warning\": false, \"fatigue_index\": 6.026932117857816}'),
(236, 73, 8, 748, 0.825451, 0.0940555, 0.99168, 'good', -0.489047, '2026-01-22 06:45:29', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 171.5061798095703, \"is_warning\": false, \"fatigue_index\": 0}'),
(237, 73, 9, 2602, 0.880765, 0.0680944, 0.985994, 'good', -0.280133, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [\"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"elbow_min\": 164.79238891601562, \"is_warning\": true, \"fatigue_index\": 0}'),
(238, 73, 10, 872, 0.552158, 0.0307542, 0.988402, 'good', -0.211309, '2026-01-22 06:45:29', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 170.39279174804688, \"is_warning\": false, \"fatigue_index\": 0}'),
(239, 74, 1, 5634, 1.65146, 0.149515, 0.79211, 'good', -0.447623, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.25637415051460266}'),
(240, 74, 2, 1999, 1.63775, 0.144145, 0.831809, 'good', -0.324346, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Brace core; reduce lean\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2938270568847656}'),
(241, 74, 3, 3371, 1.52815, 0.108535, 0.819807, 'good', -0.142362, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22597643733024597}'),
(242, 74, 4, 2231, 1.46313, 0.102493, 0.817317, 'good', -0.0342568, '2026-01-22 06:46:31', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2955237925052643}'),
(243, 74, 5, 3617, 1.48158, 0.105824, 0.817427, 'good', -0.0925957, '2026-01-22 06:46:31', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22300106287002563}'),
(244, 74, 6, 6251, 1.53447, 0.102671, 0.807987, 'good', -0.398739, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 5.872446298599243, \"wrist_stack_absmax\": 0.31776919960975647}'),
(245, 74, 7, 2627, 1.57177, 0.0981488, 0.808911, 'good', -0.183053, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.19817015528678897}'),
(246, 74, 8, 3154, 1.50054, 0.0964747, 0.827423, 'good', -0.0766547, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2189619243144989}'),
(247, 74, 9, 2221, 1.51565, 0.115839, 0.827404, 'good', -0.131045, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.17899364233016968}'),
(248, 74, 10, 2374, 1.54701, 0.104067, 0.826675, 'good', -0.150324, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2143746912479401}'),
(249, 74, 11, 4494, 1.44058, 0.0858399, 0.881044, 'bad', -0.255284, '2026-01-22 06:46:31', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (right)\", \"Stack wrist over elbow (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.4356368482112885}'),
(250, 82, 1, 7330, 176.826, 0, 0.849309, 'good', -0.670284, '2026-02-23 01:25:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.219472274184227}'),
(251, 82, 2, 4739, 173.581, 0, 0.978586, 'good', -0.496949, '2026-02-23 01:25:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24083785712718964}'),
(252, 83, 1, 5673, 167.815, 0, 0.901062, 'good', -0.588556, '2026-02-23 01:25:26', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30558180809020996}'),
(253, 83, 2, 7648, 171.063, 0, 0.9874, 'bad', -0.674983, '2026-02-23 01:25:26', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5635055303573608}'),
(254, 83, 3, 1616, 169.686, 0, 0.981151, 'good', -0.081795, '2026-02-23 01:25:26', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2378017157316208}'),
(255, 88, 1, 12696, 173.592, 0, 0.801111, 'good', -0.683567, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4151446521282196}'),
(256, 88, 2, 3267, 170.789, 0, 0.975226, 'good', -0.249408, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19525563716888428}'),
(257, 88, 3, 9726, 165.376, 0, 0.983436, 'good', -0.683189, '2026-02-23 01:50:44', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18687815964221952}'),
(258, 88, 4, 2250, 161.533, 0, 0.98633, 'good', -0.0532135, '2026-02-23 01:50:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1819896250963211}'),
(259, 89, 1, 7447, 177.223, 0, 0.958498, 'good', -0.672268, '2026-02-23 02:08:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22735695540905}'),
(260, 89, 2, 3507, 173.811, 0, 0.983907, 'good', -0.309186, '2026-02-23 02:08:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19196100533008575}'),
(261, 89, 3, 6747, 170.955, 0, 0.991585, 'good', -0.653478, '2026-02-23 02:08:06', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23993971943855288}'),
(262, 91, 1, 15243, 178.818, 0, 0.85374, 'good', -0.683567, '2026-02-23 02:12:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.36857014894485474}'),
(263, 93, 1, 4757, 176.39, 0, 0.81706, 'good', -0.50931, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2568829655647278}'),
(264, 93, 2, 4376, 173.253, 0, 0.973301, 'good', -0.44459, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24614661931991577}'),
(265, 93, 3, 4499, 169.67, 0, 0.981354, 'good', -0.448686, '2026-02-23 02:19:12', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19567608833312988}'),
(266, 93, 4, 4004, 169.077, 0, 0.98191, 'good', -0.36541, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17789286375045776}'),
(267, 93, 5, 3866, 172.205, 0, 0.983754, 'good', -0.358217, '2026-02-23 02:19:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22129936516284943}'),
(268, 94, 1, 9282, 176.546, 0, 0.957582, 'good', -0.682866, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2642352283000946}');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`) VALUES
(269, 94, 2, 6002, 178.983, 0, 0.990167, 'good', -0.626156, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1966916173696518}'),
(270, 94, 3, 3271, 174.52, 0, 0.988285, 'good', -0.27761, '2026-02-23 02:54:41', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21627609431743625}'),
(271, 94, 4, 3605, 170.497, 0, 0.983015, 'good', -0.304036, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2060348093509674}'),
(272, 94, 5, 7263, 146.002, 0, 0.990683, 'bad', -0.668946, '2026-02-23 02:54:41', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(273, 94, 6, 1995, 166.001, 0, 0.983758, 'good', -0.0627858, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16211724281311035}'),
(274, 94, 7, 2111, 161.739, 0, 0.982591, 'good', -0.0457419, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 9.402015209197998, \"elbow_drift_absmax\": 0.28438493609428406}'),
(275, 94, 8, 4381, 114.806, 0, 0.988956, 'good', -0.538773, '2026-02-23 02:54:41', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 9.402015209197998, \"elbow_drift_absmax\": 0.49692168831825256}'),
(276, 94, 9, 1255, 158.844, 0, 0.991311, 'good', -0.0306981, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.34431517124176025}'),
(277, 94, 10, 1746, 160.506, 0, 0.989776, 'good', -0.0244893, '2026-02-23 02:54:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.3035406172275543}'),
(278, 94, 11, 5636, 151.531, 0, 0.99375, 'bad', -0.592245, '2026-02-23 02:54:41', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 16.59364342689514, \"elbow_drift_absmax\": 0.6685231328010559}'),
(279, 94, 12, 2610, 162.917, 0, 0.990315, 'good', -0.138788, '2026-02-23 02:54:42', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.4959278106689453}'),
(280, 95, 1, 6613, 173.878, 0, 0.957253, 'good', -0.650247, '2026-02-23 02:55:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2525123357772827}'),
(281, 95, 2, 4879, 169.732, 0, 0.973491, 'good', -0.50373, '2026-02-23 02:55:44', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24321186542510984}'),
(282, 96, 1, 3013, 115.224, 0, 0.890726, 'bad', -0.420286, '2026-02-23 02:56:41', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6166037917137146}'),
(283, 96, 2, 4752, 174.054, 0, 0.898426, 'good', -0.499979, '2026-02-23 02:56:41', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22062930464744568}'),
(284, 96, 3, 2772, 161.021, 0, 0.978324, 'good', -0.115193, '2026-02-23 02:56:41', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2515883147716522}'),
(285, 97, 1, 9083, 178.215, 0, 0.992128, 'good', -0.682624, '2026-02-23 03:23:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30567362904548645}'),
(286, 97, 2, 4242, 165.837, 0, 0.990883, 'good', -0.39367, '2026-02-23 03:23:16', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16841627657413483}'),
(287, 97, 3, 3746, 165.619, 0, 0.991535, 'good', -0.304307, '2026-02-23 03:23:16', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23105518519878387}'),
(288, 100, 1, 36097, 162.454, 0, 0.915521, 'good', -0.683567, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.37239834666252136}'),
(289, 100, 2, 1618, 157.76, 0, 0.970247, 'good', -0.00926311, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.259771466255188}'),
(290, 100, 3, 2000, 163.62, 0, 0.977642, 'good', -0.0486103, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2766464948654175}'),
(291, 100, 4, 2643, 167.447, 0, 0.975089, 'good', -0.133979, '2026-02-24 04:11:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2535858750343323}'),
(292, 100, 5, 5108, 130.288, 0, 0.975198, 'bad', -0.570328, '2026-02-24 04:11:02', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(293, 101, 1, 12369, 132.62, 0, 0.951293, 'bad', -0.683566, '2026-02-25 06:30:51', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5963998436927795}'),
(294, 102, 1, 5191, 105.395, 0, 0.881037, 'bad', -0.631098, '2026-02-25 06:31:39', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6277127861976624}'),
(295, 105, 1, 9942, 163.821, 0, 0.956337, 'bad', -0.683357, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6650781035423279}'),
(296, 105, 2, 2128, 139.776, 0, 0.985956, 'bad', -0.12229, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5611814260482788}'),
(297, 105, 3, 1612, 145.764, 0, 0.983111, 'good', -0.03875, '2026-02-25 06:59:08', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4325236678123474}'),
(298, 105, 4, 2508, 140.494, 0, 0.983282, 'bad', -0.171293, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.622738778591156}'),
(299, 105, 5, 2120, 114.235, 0, 0.985428, 'bad', -0.360895, '2026-02-25 06:59:08', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.545386552810669}'),
(300, 105, 6, 3249, 161.957, 0, 0.970568, 'good', -0.199925, '2026-02-25 06:59:08', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2835617661476135}'),
(301, 105, 7, 2129, 162.004, 0, 0.977302, 'good', -0.0512551, '2026-02-25 06:59:08', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.31445568799972534}'),
(302, 106, 1, 8623, 172.905, 0, 0.887392, 'good', -0.681373, '2026-02-25 06:59:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3407405614852905}'),
(303, 106, 2, 8256, 162.033, 0, 0.820584, 'good', -0.679256, '2026-02-25 06:59:40', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.411639541387558}'),
(304, 107, 1, 4186, 169.308, 0, 0.914353, 'good', -0.398454, '2026-02-25 07:00:13', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26871246099472046}'),
(305, 107, 2, 2509, 149.423, 0, 0.963573, 'good', -0.0664153, '2026-02-25 07:00:13', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3118056058883667}'),
(306, 107, 3, 2149, 120.979, 0, 0.972141, 'good', -0.256174, '2026-02-25 07:00:13', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3222694993019104}'),
(307, 107, 4, 3468, 111.601, 0, 0.978036, 'good', -0.463597, '2026-02-25 07:00:13', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3696337640285492}'),
(308, 108, 1, 3900, 145.863, 0, 0.942544, 'good', -0.311991, '2026-02-25 07:00:50', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2385709136724472}'),
(309, 108, 2, 3854, 170.926, 0, 0.973042, 'good', -0.368816, '2026-02-25 07:00:50', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4717813730239868}'),
(310, 109, 1, 6243, 171.292, 0, 0.897105, 'good', -0.631867, '2026-02-25 07:01:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29736045002937317}'),
(311, 109, 2, 1991, 163.686, 0, 0.967163, 'good', -0.047124, '2026-02-25 07:01:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25296565890312195}'),
(312, 109, 3, 2003, 161.234, 0, 0.971421, 'good', -0.036519, '2026-02-25 07:01:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28804489970207214}'),
(313, 109, 4, 2001, 161.26, 0, 0.974504, 'good', -0.0461581, '2026-02-25 07:01:30', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3661065101623535}'),
(314, 110, 1, 8599, 131.298, 0, 0.659786, 'good', -0.681467, '2026-02-25 07:04:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4232212007045746}'),
(315, 110, 2, 1620, 157.269, 0, 0.855635, 'good', -0.00848277, '2026-02-25 07:04:22', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2706197500228882}'),
(316, 110, 3, 4376, 120.442, 0, 0.966276, 'good', -0.504341, '2026-02-25 07:04:22', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3990409672260285}'),
(317, 111, 1, 3102, 95.7068, 0, 0.937906, 'good', -0.553933, '2026-02-25 07:04:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28688332438468933}'),
(318, 122, 1, 7559, 163.503, 0, 0.628403, 'bad', -0.673938, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(319, 122, 2, 4027, 175.96, 0, 0.940132, 'good', -0.406413, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27928590774536133}'),
(320, 122, 3, 1838, 171.528, 0, 0.974495, 'good', -0.103128, '2026-02-25 08:17:07', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2581453323364258}'),
(321, 122, 4, 1784, 169.031, 0, 0.97488, 'good', -0.0780274, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2332076132297516}'),
(322, 122, 5, 3824, 105.777, 0, 0.973407, 'good', -0.55831, '2026-02-25 08:17:07', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(323, 122, 6, 1567, 170.872, 0, 0.97218, 'good', -0.0959246, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.994919776916504, \"elbow_drift_absmax\": 0.2959102392196655}'),
(324, 122, 7, 1729, 161.229, 0, 0.98711, 'good', -0.0315923, '2026-02-25 08:17:07', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 6.999331712722778, \"elbow_drift_absmax\": 0.33761367201805115}'),
(325, 122, 8, 1662, 166.296, 0, 0.979493, 'good', -0.0561972, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.994919776916504, \"elbow_drift_absmax\": 0.2781488299369812}'),
(326, 122, 9, 1719, 167.423, 0, 0.982289, 'good', -0.0692867, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.865630865097046, \"elbow_drift_absmax\": 0.31983283162117004}'),
(327, 122, 10, 2316, 133.074, 0, 0.97059, 'bad', -0.229525, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 4.865630865097046, \"elbow_drift_absmax\": 0.7}'),
(328, 122, 11, 1126, 160.246, 0, 0.973909, 'bad', -0.147506, '2026-02-25 08:17:07', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}'),
(329, 122, 12, 1356, 149.496, 0, 0.978374, 'good', -0.014682, '2026-02-25 08:17:07', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.32520750164985657}'),
(330, 123, 1, 3852, 171.752, 0, 0.84085, 'good', -0.36855, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4398638010025024}'),
(331, 123, 2, 5516, 165.247, 0, 0.903716, 'bad', -0.59112, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(332, 123, 3, 773, 110.867, 0, 0.869299, 'good', -0.400867, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.45704907178878784}'),
(333, 123, 4, 2344, 146.647, 0, 0.84564, 'good', -0.0540795, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.312942773103714}'),
(334, 123, 5, 1539, 117.257, 0, 0.949915, 'bad', -0.353445, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(335, 123, 6, 1134, 169.784, 0, 0.966385, 'good', -0.153897, '2026-02-25 08:17:56', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5672565698623657}'),
(336, 123, 7, 6261, 159.085, 0, 0.959131, 'bad', -0.636269, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(337, 123, 8, 1417, 162.136, 0, 0.948582, 'bad', -0.14357, '2026-02-25 08:17:56', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(338, 123, 9, 977, 116.82, 0, 0.934542, 'good', -0.316203, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.37925946712493896}'),
(339, 123, 10, 1426, 158.596, 0, 0.893019, 'good', -0.0156989, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.27605122327804565}'),
(340, 123, 11, 1563, 164.027, 0, 0.912379, 'good', -0.0400967, '2026-02-25 08:17:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.1508020056691084, \"elbow_drift_absmax\": 0.2731146514415741}'),
(341, 124, 1, 531, 0.605555, 0.0801145, 0.97064, 'bad', -0.437635, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\"], \"label_ui\": \"bad\", \"elbow_min\": 157.0267333984375, \"is_warning\": false, \"fatigue_index\": 0}'),
(342, 124, 2, 470, 0.535107, 0.0964553, 0.977018, 'good', -0.498248, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.1000518798828, \"is_warning\": false, \"fatigue_index\": 0}'),
(343, 124, 3, 598, 0.687046, 0.0575895, 0.978269, 'good', -0.223343, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 153.0726776123047, \"is_warning\": true, \"fatigue_index\": 0}'),
(344, 124, 4, 667, 0.914453, 0.0724339, 0.980223, 'good', -0.338594, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.4596405029297, \"is_warning\": false, \"fatigue_index\": 0}'),
(345, 124, 5, 532, 0.393098, 0.0563612, 0.981178, 'good', -0.280875, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 148.66311645507812, \"is_warning\": false, \"fatigue_index\": 0}'),
(346, 124, 6, 503, 0.653854, 0.0699501, 0.981275, 'good', -0.364894, '2026-02-25 08:19:10', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 149.05780029296875, \"is_warning\": false, \"fatigue_index\": 4.817852783203125}'),
(347, 124, 7, 601, 0.46058, 0.0706138, 0.985129, 'good', -0.362787, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 153.48733520507812, \"is_warning\": false, \"fatigue_index\": 4.817852783203125}'),
(348, 124, 8, 1290, 0.378682, 0.0250283, 0.985218, 'bad', -0.106103, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"bad\", \"elbow_min\": 157.12188720703125, \"is_warning\": false, \"fatigue_index\": 0}'),
(349, 124, 9, 802, 0.565185, 0.0509835, 0.976889, 'good', -0.125016, '2026-02-25 08:19:10', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 148.2534637451172, \"is_warning\": false, \"fatigue_index\": 5.1414591780350305}'),
(350, 124, 10, 684, 0.584688, 0.0395696, 0.992154, 'bad', -0.504985, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 10.92451581866003}'),
(351, 124, 11, 664, 0.403937, 0.0426516, 0.992403, 'good', -0.181346, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 147.90794372558594, \"is_warning\": false, \"fatigue_index\": 6.893558849568526}'),
(352, 124, 12, 531, 0.36717, 0.0566007, 0.979205, 'bad', -0.497319, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Don\'t curl (elbow too bent)\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 35.28574311880371}'),
(353, 124, 13, 582, 0.706987, 0.047908, 0.979868, 'good', -0.213336, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 135.661865234375, \"is_warning\": false, \"fatigue_index\": 26.178717972319333}'),
(354, 124, 14, 734, 0.542538, 0.0968015, 0.959278, 'bad', -0.175433, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [\"Raise both arms evenly\", \"Arms bending more - avoid upright-row motion\"], \"label_ui\": \"bad\", \"elbow_min\": 60, \"is_warning\": false, \"fatigue_index\": 30}'),
(355, 124, 15, 546, 0.775278, 0.0775918, 0.986678, 'good', -0.429401, '2026-02-25 08:19:10', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 138.6455841064453, \"is_warning\": false, \"fatigue_index\": 20.892974853515625}'),
(356, 125, 1, 26496, 177.758, 0, 0.856292, 'bad', -0.683567, '2026-02-25 08:21:25', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(357, 125, 2, 5816, 175.051, 0, 0.88128, 'good', -0.61013, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.33025094866752625}'),
(358, 125, 3, 1595, 175.793, 0, 0.954043, 'good', -0.147226, '2026-02-25 08:21:25', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3165428042411804}'),
(359, 125, 4, 1757, 175.477, 0, 0.974328, 'good', -0.151381, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.36876311898231506}'),
(360, 125, 5, 1769, 172.663, 0, 0.967399, 'good', -0.126363, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.39054152369499207}'),
(361, 125, 6, 1755, 175.451, 0, 0.976323, 'good', -0.141948, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.621460437774658, \"elbow_drift_absmax\": 0.27738726139068604}'),
(362, 125, 7, 3221, 178.682, 0, 0.979298, 'good', -0.305804, '2026-02-25 08:21:25', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2650342881679535}'),
(363, 125, 8, 2027, 172.88, 0, 0.961186, 'good', -0.122944, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20584411919116977}'),
(364, 125, 9, 1956, 173.009, 0, 0.960689, 'good', -0.120763, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21045389771461487}'),
(365, 125, 10, 1904, 170.751, 0, 0.961794, 'good', -0.102621, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3173067271709442}'),
(366, 125, 11, 1809, 167.032, 0, 0.979277, 'good', -0.0650939, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2870665192604065}'),
(367, 125, 12, 2249, 161.005, 0, 0.966052, 'good', -0.0533568, '2026-02-25 08:21:25', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2838613986968994}'),
(368, 137, 1, 3469, 165.473, 0, 0.955987, 'good', -0.331172, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(369, 137, 2, 2721, 172.835, 0, 0.987192, 'good', -0.18604, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21801359951496124}'),
(370, 137, 3, 6410, 175.146, 0, 0.993078, 'bad', -0.650663, '2026-02-27 08:09:52', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(371, 137, 4, 2316, 176.991, 0, 0.977335, 'good', -0.200194, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.40271785855293274}'),
(372, 137, 5, 4186, 163.052, 0, 0.978069, 'good', -0.431952, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(373, 137, 6, 2116, 178.925, 0, 0.984417, 'good', -0.19335, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2621115744113922}'),
(374, 137, 7, 2254, 174.288, 0, 0.979434, 'good', -0.153357, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26306602358818054}'),
(375, 137, 8, 2382, 174.925, 0, 0.981504, 'good', -0.170054, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25356608629226685}'),
(376, 137, 9, 1245, 162.749, 0, 0.978191, 'bad', -0.102078, '2026-02-27 08:09:52', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5672575235366821}'),
(377, 137, 10, 1817, 166.902, 0, 0.989401, 'good', -0.0821925, '2026-02-27 08:09:52', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 1.4437758922576904, \"elbow_drift_absmax\": 0.4147493243217468}'),
(378, 137, 11, 1848, 176.151, 0, 0.97541, 'good', -0.149573, '2026-02-27 08:09:52', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 1.4437758922576904, \"elbow_drift_absmax\": 0.20772908627986908}'),
(379, 138, 1, 2733, 172.856, 0, 0.92761, 'good', -0.188271, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2397655099630356}'),
(380, 138, 2, 1543, 175.43, 0, 0.9464, 'good', -0.142581, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30588048696517944}'),
(381, 138, 3, 1558, 175.722, 0, 0.958642, 'good', -0.143051, '2026-02-27 08:13:56', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.26834017038345337}'),
(382, 138, 4, 1669, 174.568, 0, 0.971134, 'good', -0.131786, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2828606963157654}'),
(383, 138, 5, 1551, 151.973, 0, 0.970555, 'good', -0.00485176, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.30289432406425476}'),
(384, 138, 6, 4499, 150.101, 0, 0.975853, 'good', -0.441386, '2026-02-27 08:13:56', '{\"reasons\": [\"Keep elbows steadier (both)\", \"Tempo slowing - stay controlled\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 2.4040353298187256, \"elbow_drift_absmax\": 0.541191816329956}'),
(385, 138, 7, 1432, 161.781, 0, 0.95357, 'good', -0.029171, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 2.4040353298187256, \"elbow_drift_absmax\": 0.27182894945144653}'),
(386, 138, 8, 1468, 157.205, 0, 0.955458, 'good', -0.0152804, '2026-02-27 08:13:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 5.2790772914886475, \"elbow_drift_absmax\": 0.3268530070781708}'),
(387, 140, 1, 3556, 108.113, 0, 0.624337, 'good', -0.500554, '2026-02-27 08:34:18', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4212509095668793}'),
(388, 143, 1, 3887, 157.787, 0, 0.883782, 'good', -0.308524, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2754361033439636}'),
(389, 143, 2, 2035, 172.969, 0, 0.939194, 'good', -0.125798, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2651256024837494}'),
(390, 143, 3, 3813, 175.606, 0, 0.963294, 'good', -0.370327, '2026-02-27 08:57:33', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2430647611618042}'),
(391, 143, 4, 2719, 175.368, 0, 0.920403, 'good', -0.208738, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1987724006175995}'),
(392, 143, 5, 3716, 148.575, 0, 0.980085, 'bad', -0.312946, '2026-02-27 08:57:33', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5664390921592712}'),
(393, 143, 6, 5452, 171.442, 0, 0.98338, 'bad', -0.590542, '2026-02-27 08:57:33', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6545327305793762}'),
(394, 143, 7, 1406, 168.036, 0, 0.977766, 'good', -0.075618, '2026-02-27 08:57:33', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 32.33842659932539, \"elbow_drift_absmax\": 0.315511018037796}'),
(395, 143, 8, 2543, 123.263, 0, 0.965636, 'good', -0.329295, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}'),
(396, 143, 9, 1549, 174.466, 0, 0.948437, 'good', -0.128394, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 6.046249866485595, \"elbow_drift_absmax\": 0.23244167864322665}'),
(397, 143, 10, 1749, 170.401, 0, 0.919912, 'good', -0.0895557, '2026-02-27 08:57:33', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23675964772701263}'),
(398, 144, 1, 3067, 1.51034, 0.0754794, 0.795856, 'good', -0.0787911, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2531309127807617}'),
(399, 144, 2, 1295, 1.34698, 0.0449209, 0.938679, 'bad', -0.068641, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.4130139648914337}'),
(400, 144, 3, 1419, 1.47817, 0.0642373, 0.942321, 'bad', -0.0725218, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2646343410015106}'),
(401, 144, 4, 1309, 1.27232, 0.0797182, 0.937216, 'bad', 0.0703985, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Wrist not stacked (left)\", \"Stack wrist over elbow (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.3219814896583557}'),
(402, 144, 5, 6194, 1.56832, 0.0883398, 0.844236, 'good', -0.386302, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [\"Press more evenly\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.23147200047969815}'),
(403, 144, 6, 1578, 1.31483, 0.0776672, 0.861547, 'good', 0.0831608, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2960854172706604}'),
(404, 144, 7, 2294, 1.25563, 0.0793165, 0.861125, 'good', -0.0136809, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.12794499099254608}'),
(405, 144, 8, 4868, 1.27273, 0.0806028, 0.884689, 'good', -0.199552, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 6.443175673484802, \"wrist_stack_absmax\": 0.2996082305908203}'),
(406, 144, 9, 2075, 1.2174, 0.0701597, 0.868927, 'good', 0.0108835, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.1683754920959473}'),
(407, 144, 10, 1771, 1.20948, 0.0626253, 0.859332, 'good', 0.000704383, '2026-02-27 08:58:37', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.16230255365371704}'),
(408, 144, 11, 1963, 1.23435, 0.0682903, 0.862675, 'good', 0.0395291, '2026-02-27 08:58:37', '{\"arm\": \"R\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.18241989612579343}'),
(409, 147, 1, 4001, 168.366, 0, 0.974706, 'bad', -0.399349, '2026-02-27 09:35:30', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5903091430664062}'),
(410, 147, 2, 2371, 169.436, 0, 0.989525, 'good', -0.123, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.31472674012184143}'),
(411, 147, 3, 2113, 175.016, 0, 0.995636, 'good', -0.149739, '2026-02-27 09:35:30', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22872349619865415}'),
(412, 147, 4, 1952, 174.616, 0, 0.961211, 'good', -0.137664, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2462081164121628}'),
(413, 147, 5, 3860, 172.237, 0, 0.882452, 'good', -0.357543, '2026-02-27 09:35:30', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2313503921031952}'),
(414, 148, 1, 4588, 172.695, 0, 0.997224, 'good', -0.473265, '2026-02-27 10:00:56', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.24979478120803833}'),
(415, 149, 1, 5594, 170.025, 0, 0.996676, 'good', -0.583572, '2026-02-27 10:02:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21367192268371585}'),
(416, 149, 2, 3668, 172.502, 0, 0.998562, 'good', -0.327783, '2026-02-27 10:02:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25157630443573}'),
(417, 149, 3, 4194, 173.696, 0, 0.99753, 'bad', -0.46767, '2026-02-27 10:02:21', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(418, 150, 1, 4132, 173.496, 0, 0.983432, 'good', -0.408151, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23481398820877075}'),
(419, 150, 2, 3135, 172.301, 0, 0.997584, 'good', -0.24283, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29549112915992737}'),
(420, 150, 3, 3417, 169.345, 0, 0.998387, 'bad', -0.311342, '2026-02-27 10:09:21', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\", \"Consistency drifting (ML)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5814729332923889}'),
(421, 150, 4, 6137, 132.12, 0, 0.997637, 'good', -0.629451, '2026-02-27 10:09:21', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.40507909655570984}'),
(422, 150, 5, 2364, 135.459, 0, 0.996612, 'good', -0.116431, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2281184196472168}'),
(423, 150, 6, 2900, 142.959, 0, 0.997857, 'good', -0.161475, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 13.150556087493896, \"elbow_drift_absmax\": 0.4430599510669708}'),
(424, 150, 7, 2316, 157.27, 0, 0.997781, 'good', -0.051322, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.654340744018555, \"elbow_drift_absmax\": 0.33427730202674866}'),
(425, 150, 8, 3333, 164.97, 0, 0.997909, 'good', -0.229465, '2026-02-27 10:09:21', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 4.654340744018555, \"elbow_drift_absmax\": 0.29899200797080994}'),
(426, 150, 9, 2500, 155.874, 0, 0.997261, 'good', -0.0612829, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0.4201054573059082, \"elbow_drift_absmax\": 0.1701507568359375}'),
(427, 150, 10, 2845, 165.926, 0, 0.997238, 'good', -0.150883, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18283167481422424}'),
(428, 150, 11, 2888, 159.993, 0, 0.996431, 'good', -0.128805, '2026-02-27 10:09:21', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.15904006361961365}'),
(429, 151, 1, 2067, 0.619269, 0.0964207, 0.94856, 'good', -0.527571, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2178017944097519}'),
(430, 151, 2, 2180, 1.16148, 0.0814624, 0.95085, 'good', -0.0292886, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2041058987379074}'),
(431, 151, 3, 1885, 1.3959, 0.0957202, 0.983171, 'good', 0.0264603, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.32852986454963684}'),
(432, 151, 4, 7018, 1.38858, 0.0987147, 0.881958, 'good', -0.418627, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.2862248122692108}'),
(433, 151, 5, 2633, 1.29155, 0.0799699, 0.891148, 'good', 0.0787985, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [\"Stack wrist over elbow (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"fatigue_index\": 5.027639865875244, \"wrist_stack_absmax\": 0.25270721316337585}'),
(434, 151, 6, 2485, 1.35579, 0.10208, 0.884622, 'good', 0.0372782, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.1893621981143951}'),
(435, 151, 7, 2479, 1.36504, 0.0920455, 0.878867, 'good', 0.067686, '2026-02-27 10:10:56', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.22989383339881897}'),
(436, 151, 8, 2445, 1.35235, 0.0829638, 0.87142, 'good', 0.056809, '2026-02-27 10:10:56', '{\"arm\": \"R\", \"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"fatigue_index\": 0, \"wrist_stack_absmax\": 0.16922394931316376}'),
(437, 152, 1, 6784, 109.495, 0, 0.852966, 'bad', -0.671742, '2026-02-27 10:11:22', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(438, 153, 1, 4453, 163.77, 0, 0.978346, 'good', -0.424968, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.28117799758911133}'),
(439, 153, 2, 4168, 166.385, 0, 0.995961, 'good', -0.38277, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.21965207159519196}'),
(440, 153, 3, 3882, 164.445, 0, 0.9957, 'good', -0.324715, '2026-02-27 10:33:15', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.23548826575279236}'),
(441, 153, 4, 3216, 155.235, 0, 0.994549, 'good', -0.173818, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2360885590314865}'),
(442, 153, 5, 3002, 161.573, 0, 0.994802, 'good', -0.152895, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2166147381067276}');
INSERT INTO `rep_metrics` (`rep_id`, `log_id`, `rep_index`, `duration_ms`, `rom_score`, `trunk_sway`, `confidence_avg`, `form_label`, `anomaly_score`, `created_at`, `rep_meta`) VALUES
(443, 153, 6, 2825, 166.423, 0, 0.994188, 'good', -0.151558, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16433416306972504}'),
(444, 153, 7, 2390, 174.084, 0, 0.99311, 'good', -0.161453, '2026-02-27 10:33:15', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1988685429096222}'),
(445, 154, 1, 3427, 175.43, 0, 0.942915, 'good', -0.309307, '2026-02-27 10:35:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.25658974051475525}'),
(446, 154, 2, 2206, 177.399, 0, 0.945861, 'good', -0.185479, '2026-02-27 10:35:00', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3118451237678528}'),
(447, 155, 1, 3176, 169.66, 0, 0.965604, 'good', -0.233828, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.33852216601371765}'),
(448, 155, 2, 2882, 169.958, 0, 0.97772, 'good', -0.185315, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2571307420730591}'),
(449, 155, 3, 2598, 174.588, 0, 0.971883, 'good', -0.18779, '2026-02-27 10:39:45', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22988787293434143}'),
(450, 155, 4, 2736, 171.82, 0, 0.974383, 'good', -0.179114, '2026-02-27 10:39:45', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20887725055217743}'),
(451, 155, 5, 3957, 173.532, 0, 0.977416, 'bad', -0.42291, '2026-02-27 10:39:45', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6303626894950867}'),
(452, 157, 1, 4250, 154.563, 0, 0.985876, 'good', -0.417941, '2026-02-27 10:46:47', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.642208993434906}'),
(453, 157, 2, 3773, 154.847, 0, 0.995681, 'bad', -0.319834, '2026-02-27 10:46:47', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5570183396339417}'),
(454, 157, 3, 3317, 152.393, 0, 0.991382, 'good', -0.225675, '2026-02-27 10:46:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5057030320167542}'),
(455, 157, 4, 4231, 151.039, 0, 0.992747, 'good', -0.372439, '2026-02-27 10:46:47', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3248208463191986}'),
(456, 158, 1, 1658, 107.241, 0, 0.981385, 'bad', -0.432024, '2026-02-27 10:47:08', '{\"reasons\": [\"Elbow drifting a lot (left)\", \"Keep elbow steadier (left)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5837083458900452}'),
(457, 159, 1, 3858, 140.899, 0, 0.977119, 'good', -0.332907, '2026-02-27 10:47:35', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4302944242954254}'),
(458, 160, 1, 1702, 109.258, 0, 0.938803, 'good', -0.384629, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3510110378265381}'),
(459, 160, 2, 4432, 158.899, 0, 0.956258, 'good', -0.414751, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.34606680274009705}'),
(460, 160, 3, 2918, 152.011, 0, 0.95906, 'good', -0.161511, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.5168856382369995}'),
(461, 160, 4, 2283, 144.101, 0, 0.957758, 'good', -0.0919314, '2026-02-27 10:49:45', '{\"reasons\": [\"Keep elbow steadier (left)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4931391775608063}'),
(462, 161, 1, 2461, 173.922, 0, 0.99754, 'good', -0.166707, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19187913835048676}'),
(463, 161, 2, 2284, 173.885, 0, 0.99759, 'good', -0.150313, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2155902236700058}'),
(464, 161, 3, 2332, 172.401, 0, 0.998114, 'good', -0.14015, '2026-02-27 11:44:57', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2184824645519257}'),
(465, 161, 4, 2215, 147.314, 0, 0.998022, 'bad', -0.148489, '2026-02-27 11:44:57', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.7}'),
(466, 161, 5, 2350, 169.107, 0, 0.998044, 'good', -0.134386, '2026-02-27 11:44:57', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.4241201877593994}'),
(467, 161, 6, 2201, 170.787, 0, 0.997117, 'good', -0.120642, '2026-02-27 11:44:57', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 24.67652678489685, \"elbow_drift_absmax\": 0.3224336504936218}'),
(468, 161, 7, 2317, 139.536, 0, 0.998064, 'bad', -0.141395, '2026-02-27 11:44:57', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbow steadier (right)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 24.67652678489685, \"elbow_drift_absmax\": 0.5712682604789734}'),
(469, 161, 8, 2303, 175.078, 0, 0.997947, 'good', -0.164844, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 12.474142313003538, \"elbow_drift_absmax\": 0.25567862391471863}'),
(470, 161, 9, 1946, 174.642, 0, 0.997809, 'good', -0.137219, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.463539123535156, \"elbow_drift_absmax\": 0.229164257645607}'),
(471, 161, 10, 2083, 174.822, 0, 0.997479, 'good', -0.148068, '2026-02-27 11:44:57', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.463539123535156, \"elbow_drift_absmax\": 0.27898499369621277}'),
(472, 162, 1, 4398, 168.789, 0, 0.909749, 'good', -0.431437, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2817760705947876}'),
(473, 162, 2, 3003, 164.296, 0, 0.911796, 'good', -0.169269, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29155203700065613}'),
(474, 162, 3, 2434, 155.424, 0, 0.924883, 'good', -0.0677116, '2026-03-18 09:43:49', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3836756050586701}'),
(475, 162, 4, 7148, 168.009, 0, 0.959807, 'good', -0.665317, '2026-03-18 09:43:49', '{\"reasons\": [\"Keep elbow steadier (right)\", \"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.45750582218170166}'),
(476, 162, 5, 2450, 165.765, 0, 0.91636, 'good', -0.0989048, '2026-03-18 09:43:49', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 11.05482816696167, \"elbow_drift_absmax\": 0.2463913261890411}'),
(477, 163, 1, 5934, 174.016, 0, 0.895424, 'good', -0.616653, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.32780972123146057}'),
(478, 163, 2, 2955, 161.959, 0, 0.966549, 'good', -0.159188, '2026-03-18 09:52:02', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.37287232279777527}'),
(479, 163, 3, 2895, 164.294, 0, 0.956196, 'good', -0.152178, '2026-03-18 09:52:02', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.29056286811828613}'),
(480, 163, 4, 2602, 169.531, 0, 0.959093, 'good', -0.147929, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3039013743400574}'),
(481, 163, 5, 2543, 162.966, 0, 0.959537, 'good', -0.092381, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.22876808047294617}'),
(482, 163, 6, 3302, 171.314, 0, 0.950283, 'bad', -0.332982, '2026-03-18 09:52:02', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.6893754601478577}'),
(483, 163, 7, 2265, 162.481, 0, 0.946408, 'good', -0.0687581, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.855434894561768, \"elbow_drift_absmax\": 0.34436333179473877}'),
(484, 163, 8, 1684, 165.21, 0, 0.94937, 'good', -0.059223, '2026-03-18 09:52:02', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 7.895636558532715, \"elbow_drift_absmax\": 0.3696983456611634}'),
(485, 163, 9, 2432, 172.955, 0, 0.955967, 'good', -0.154855, '2026-03-18 09:52:02', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 4.855434894561768, \"elbow_drift_absmax\": 0.2263495028018951}'),
(486, 170, 1, 3434, 170.192, 0, 0.99443, 'good', -0.273153, '2026-04-01 06:05:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19102582335472107}'),
(487, 170, 2, 2638, 163.009, 0, 0.991371, 'good', -0.105087, '2026-04-01 06:05:06', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16805943846702576}'),
(488, 170, 3, 2669, 168.451, 0, 0.986141, 'good', -0.143927, '2026-04-01 06:05:06', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17469161748886108}'),
(489, 172, 1, 1030, 0.524995, 0.130173, 0.923894, 'good', -0.507262, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 158.16671752929688, \"is_warning\": false, \"fatigue_index\": 0}'),
(490, 172, 2, 798, 0.544412, 0.115883, 0.931526, 'good', -0.506815, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 160.5016632080078, \"is_warning\": false, \"fatigue_index\": 0}'),
(491, 172, 3, 1118, 0.755417, 0.136882, 0.93025, 'good', -0.507284, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"elbow_min\": 155.9709930419922, \"is_warning\": true, \"fatigue_index\": 0}'),
(492, 172, 4, 981, 0.751395, 0.133373, 0.943585, 'good', -0.507289, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 162.0985107421875, \"is_warning\": false, \"fatigue_index\": 0}'),
(493, 172, 5, 986, 0.639396, 0.119892, 0.947815, 'good', -0.507007, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 157.4168701171875, \"is_warning\": false, \"fatigue_index\": 0.8998168945312499}'),
(494, 172, 6, 961, 0.862584, 0.121655, 0.938403, 'good', -0.507088, '2026-04-01 06:11:23', '{\"arm\": \"L\", \"reasons\": [], \"label_ui\": \"good\", \"elbow_min\": 158.78216552734375, \"is_warning\": false, \"fatigue_index\": 0}'),
(495, 173, 1, 3747, 175.193, 0, 0.970189, 'good', -0.378966, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.49242761731147766}'),
(496, 173, 2, 3478, 165.466, 0, 0.966335, 'good', -0.254505, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.2174871414899826}'),
(497, 173, 3, 3251, 163.353, 0, 0.974803, 'good', -0.203621, '2026-04-01 06:12:28', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.19083000719547272}'),
(498, 173, 4, 2936, 165.032, 0, 0.973761, 'good', -0.159964, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16156578063964844}'),
(499, 173, 5, 3077, 162.012, 0, 0.971843, 'good', -0.168022, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1587398499250412}'),
(500, 173, 6, 3655, 164.5, 0, 0.979367, 'good', -0.282569, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.17707963287830353}'),
(501, 173, 7, 3902, 165.839, 0, 0.978732, 'good', -0.333331, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.18880023062229156}'),
(502, 173, 8, 3481, 162.108, 0, 0.973304, 'good', -0.241044, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1616682410240173}'),
(503, 173, 9, 2828, 165.78, 0, 0.969085, 'good', -0.148695, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.14528551697731018}'),
(504, 173, 10, 3371, 170.779, 0, 0.979955, 'good', -0.266403, '2026-04-01 06:12:28', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1875794231891632}'),
(505, 174, 1, 3190, 171.251, 0, 0.994299, 'good', -0.240323, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.20234476029872897}'),
(506, 174, 2, 2785, 172.172, 0, 0.995181, 'good', -0.188763, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1719403862953186}'),
(507, 174, 3, 2866, 170.813, 0, 0.994559, 'good', -0.188896, '2026-04-01 06:28:12', '{\"reasons\": [\"Consistency drifting (ML)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.16317218542099}'),
(508, 174, 4, 2745, 171.873, 0, 0.99409, 'good', -0.182619, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.1321955919265747}'),
(509, 174, 5, 2935, 167.251, 0, 0.991924, 'good', -0.174549, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.13630768656730652}'),
(510, 174, 6, 2785, 170.051, 0, 0.98998, 'good', -0.173245, '2026-04-01 06:28:12', '{\"reasons\": [], \"label_ui\": \"good\", \"is_warning\": false, \"rep_bad_seen\": false, \"rep_tip_seen\": false, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.13161221146583557}'),
(511, 174, 7, 3066, 162.759, 0, 0.993996, 'good', -0.181167, '2026-04-01 06:28:12', '{\"reasons\": [\"Keep elbow steadier (right)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 0, \"elbow_drift_absmax\": 0.3761248290538788}'),
(512, 174, 8, 2258, 150.247, 0, 0.991273, 'good', -0.0617287, '2026-04-01 06:28:12', '{\"reasons\": [\"Keep elbows steadier (both)\"], \"label_ui\": \"warning\", \"is_warning\": true, \"rep_bad_seen\": false, \"rep_tip_seen\": true, \"fatigue_index\": 25.554317235946655, \"elbow_drift_absmax\": 0.4489337205886841}'),
(513, 174, 9, 2701, 154.688, 0, 0.991958, 'bad', -0.192621, '2026-04-01 06:28:12', '{\"reasons\": [\"Elbow drifting a lot (right)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.7}'),
(514, 174, 10, 2385, 145.393, 0, 0.990409, 'bad', -0.162061, '2026-04-01 06:28:12', '{\"reasons\": [\"Elbow drifting a lot (both)\", \"Keep elbows steadier (both)\"], \"label_ui\": \"bad\", \"is_warning\": false, \"rep_bad_seen\": true, \"rep_tip_seen\": true, \"fatigue_index\": 30, \"elbow_drift_absmax\": 0.6858193278312683}');

-- --------------------------------------------------------

--
-- Table structure for table `rep_snapshots`
--

CREATE TABLE `rep_snapshots` (
  `snapshot_id` bigint NOT NULL,
  `log_id` bigint NOT NULL,
  `rep_index` int NOT NULL,
  `image_path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
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
(34, 174, 11, 'uploads/rep_snapshots/log_174/rep_11.jpg', '2026-04-01 06:28:11');

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
  `status` enum('pending','accepted','declined','cancelled','expired','unlink_requested') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
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
(10, 3, 2, 'accepted', '8706c4857a38d6c14e2d788d55b7e029b80f1abe17e2d7c31ee6db6c6bf71c86', '2026-04-08 06:30:11', '2026-04-01 06:30:11', '2026-04-01 06:30:19');

-- --------------------------------------------------------

--
-- Table structure for table `trainer_rating_summary`
--

CREATE TABLE `trainer_rating_summary` (
  `trainer_id` int NOT NULL,
  `avg_rating` decimal(6,2) DEFAULT NULL,
  `review_count` bigint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ;

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
    CALL recompute_trainer_summary(NEW.trainer_id);
  ELSE
    CALL recompute_trainer_summary(NEW.trainer_id);
  END IF;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `training_logs`
--

INSERT INTO `training_logs` (`log_id`, `user_id`, `exercise_type`, `source_type`, `video_path`, `result_json_path`, `reps_total`, `reps_good`, `reps_bad`, `form_error_count`, `fatigue_flag`, `started_at`, `finished_at`, `processing_ms`, `created_at`) VALUES
(1, 3, 'bicep_curl', 'upload', 'assets/data/uploads/bc_001.mp4', 'assets/data/tmp/bc_001.json', 12, 10, 2, 3, 0, '2025-12-14 15:18:44', '2025-12-14 15:18:53', 9100, '2025-12-14 15:18:44'),
(2, 3, 'shoulder_press', 'upload', 'assets/data/uploads/sp_001.mp4', 'assets/data/tmp/sp_001.json', 10, 7, 3, 6, 1, '2025-12-15 15:18:44', '2025-12-15 15:18:55', 11200, '2025-12-15 15:18:44'),
(3, 3, 'lateral_raise', 'upload', 'assets/data/uploads/lr_001.mp4', 'assets/data/tmp/lr_001.json', 14, 11, 3, 5, 1, '2025-12-16 12:18:44', '2025-12-16 12:18:54', 10300, '2025-12-16 12:18:44'),
(4, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:39:44', '2025-12-16 15:40:40', 5, '2025-12-16 15:39:44'),
(5, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:41:12', NULL, NULL, '2025-12-16 15:41:12'),
(6, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 6, 5, 62, 0, '2025-12-16 15:41:27', '2025-12-16 15:42:00', 3, '2025-12-16 15:41:27'),
(7, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 0, 3, 40, 0, '2025-12-16 15:43:56', '2025-12-16 15:44:27', 4, '2025-12-16 15:43:56'),
(8, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2025-12-16 15:49:52', '2025-12-16 15:49:54', 3, '2025-12-16 15:49:52'),
(9, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 4, 5, 66, 1, '2025-12-16 16:04:57', '2025-12-16 16:05:50', 4, '2025-12-16 16:04:57'),
(10, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 35, 0, '2025-12-16 16:06:21', '2025-12-16 16:06:30', 2, '2025-12-16 16:06:21'),
(11, 3, 'shoulder_press', 'webcam', NULL, NULL, 7, 0, 7, 18, 0, '2025-12-16 16:25:38', '2025-12-16 16:26:05', 6, '2025-12-16 16:25:38'),
(12, 3, 'lateral_raise', 'webcam', NULL, NULL, 6, 1, 5, 1, 0, '2025-12-16 16:26:19', '2025-12-16 16:27:11', 3, '2025-12-16 16:26:19'),
(13, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 3, 7, 39, 0, '2025-12-18 03:10:18', '2025-12-18 03:11:08', 5, '2025-12-18 03:10:18'),
(14, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 2, 0, '2025-12-18 03:33:37', '2025-12-18 03:33:42', 4, '2025-12-18 03:33:37'),
(15, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 2, 4, 96, 0, '2025-12-18 03:34:11', '2025-12-18 03:34:58', 8, '2025-12-18 03:34:11'),
(16, 3, 'shoulder_press', 'webcam', NULL, NULL, 2, 0, 2, 60, 0, '2025-12-18 03:35:05', '2025-12-18 03:35:50', 9, '2025-12-18 03:35:05'),
(17, 3, 'lateral_raise', 'webcam', NULL, NULL, 1, 0, 1, 104, 1, '2025-12-18 03:35:55', '2025-12-18 03:36:27', 4, '2025-12-18 03:35:55'),
(18, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 1, 2, 60, 0, '2025-12-18 03:54:30', '2025-12-18 03:55:07', 9, '2025-12-18 03:54:30'),
(19, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 03:31:14', '2026-01-21 03:31:17', 6, '2026-01-21 03:31:14'),
(20, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 1, 9, 22, 0, '2026-01-21 05:13:02', '2026-01-21 05:13:41', 3, '2026-01-21 05:13:02'),
(21, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 2, 16, 0, '2026-01-21 05:19:09', '2026-01-21 05:19:28', 4, '2026-01-21 05:19:09'),
(22, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 24, 0, '2026-01-21 05:22:47', '2026-01-21 05:22:59', 2, '2026-01-21 05:22:47'),
(23, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 2, 22, 1, '2026-01-21 05:26:01', '2026-01-21 05:26:18', 6, '2026-01-21 05:26:01'),
(24, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 0, 4, 33, 0, '2026-01-21 05:28:51', '2026-01-21 05:29:19', 3, '2026-01-21 05:28:51'),
(25, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 0, 3, 14, 0, '2026-01-21 05:32:38', '2026-01-21 05:33:02', 3, '2026-01-21 05:32:38'),
(26, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 05:35:10', '2026-01-21 05:35:11', 2, '2026-01-21 05:35:10'),
(27, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 05:44:50', '2026-01-21 05:44:52', 4, '2026-01-21 05:44:50'),
(29, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 0, 0, 0, '2026-01-21 05:48:38', '2026-01-21 05:48:54', 6, '2026-01-21 05:48:38'),
(30, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 0, 0, 0, '2026-01-21 05:52:35', '2026-01-21 05:52:51', 4, '2026-01-21 05:52:35'),
(31, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 0, 0, 0, 0, '2026-01-21 06:05:38', '2026-01-21 06:05:56', 5, '2026-01-21 06:05:38'),
(32, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:06:59', '2026-01-21 06:07:03', 4, '2026-01-21 06:06:59'),
(33, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:07:28', '2026-01-21 06:08:03', 3, '2026-01-21 06:07:28'),
(34, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:13:32', '2026-01-21 06:15:07', 6, '2026-01-21 06:13:32'),
(35, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 0, 0, 0, '2026-01-21 06:19:17', '2026-01-21 06:19:59', 3, '2026-01-21 06:19:17'),
(36, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 0, 0, 0, '2026-01-21 06:20:03', '2026-01-21 06:20:25', 3, '2026-01-21 06:20:03'),
(37, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 06:35:29', '2026-01-21 06:35:40', 5, '2026-01-21 06:35:29'),
(38, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 6, 0, 0, 0, '2026-01-21 06:55:37', '2026-01-21 06:56:09', 9, '2026-01-21 06:55:37'),
(39, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-01-21 07:00:48', '2026-01-21 07:01:21', 4, '2026-01-21 07:00:48'),
(40, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-01-21 07:01:26', '2026-01-21 07:01:44', 3, '2026-01-21 07:01:26'),
(41, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-01-21 07:01:45', '2026-01-21 07:02:09', 3, '2026-01-21 07:01:45'),
(43, 3, 'bicep_curl', 'webcam', NULL, NULL, 20, 0, 20, 29, 0, '2026-01-21 07:45:47', '2026-01-21 07:47:03', 5, '2026-01-21 07:45:47'),
(44, 3, 'bicep_curl', 'webcam', NULL, NULL, 6, 0, 6, 0, 0, '2026-01-21 07:47:19', '2026-01-21 07:47:35', 3, '2026-01-21 07:47:19'),
(45, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 0, 8, 14, 0, '2026-01-21 08:00:59', '2026-01-21 08:01:40', 5, '2026-01-21 08:00:59'),
(47, 3, 'bicep_curl', 'webcam', NULL, NULL, 14, 5, 9, 53, 0, '2026-01-21 08:17:09', '2026-01-21 08:17:58', 7, '2026-01-21 08:17:09'),
(50, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 0, 7, 7, 0, '2026-01-21 08:34:50', '2026-01-21 08:35:18', 8, '2026-01-21 08:34:50'),
(51, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 08:36:20', '2026-01-21 08:36:21', 4, '2026-01-21 08:36:20'),
(52, 3, 'bicep_curl', 'webcam', NULL, NULL, 14, 0, 14, 48, 1, '2026-01-21 08:38:28', '2026-01-21 08:39:43', 7, '2026-01-21 08:38:28'),
(53, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:09', '2026-01-21 09:03:21', 10, '2026-01-21 09:03:09'),
(54, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:37', '2026-01-21 09:03:44', 13, '2026-01-21 09:03:37'),
(55, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:03:57', '2026-01-21 09:04:00', 4, '2026-01-21 09:03:57'),
(56, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:04:22', '2026-01-21 09:04:36', 14, '2026-01-21 09:04:22'),
(57, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:08:58', '2026-01-21 09:09:01', 8, '2026-01-21 09:08:58'),
(58, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:09:07', '2026-01-21 09:09:14', 7, '2026-01-21 09:09:07'),
(59, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-01-21 09:09:23', '2026-01-21 09:10:04', 10, '2026-01-21 09:09:23'),
(60, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:11:13', '2026-01-21 09:11:19', 4, '2026-01-21 09:11:13'),
(61, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:17:48', '2026-01-21 09:18:01', 4, '2026-01-21 09:17:48'),
(62, 3, 'bicep_curl', 'webcam', NULL, NULL, 15, 13, 2, 2, 0, '2026-01-21 09:20:42', '2026-01-21 09:21:47', 8, '2026-01-21 09:20:42'),
(63, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 6, 2, 2, 0, '2026-01-21 09:22:52', '2026-01-21 09:23:23', 8, '2026-01-21 09:22:52'),
(64, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 7, 3, 3, 0, '2026-01-21 09:23:57', '2026-01-21 09:24:35', 5, '2026-01-21 09:23:57'),
(65, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 9, 2, 2, 0, '2026-01-21 09:30:38', '2026-01-21 09:31:14', 16, '2026-01-21 09:30:38'),
(66, 3, 'bicep_curl', 'webcam', NULL, NULL, 13, 13, 0, 0, 0, '2026-01-21 09:36:36', '2026-01-21 09:37:11', 7, '2026-01-21 09:36:36'),
(67, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:41:48', '2026-01-21 09:41:57', 4, '2026-01-21 09:41:48'),
(68, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 09:42:49', '2026-01-21 09:43:05', 5, '2026-01-21 09:42:49'),
(69, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 9, 1, 1, 0, '2026-01-21 09:47:45', '2026-01-21 09:48:16', 5, '2026-01-21 09:47:45'),
(71, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-01-21 10:03:34', '2026-01-21 10:03:37', 4, '2026-01-21 10:03:34'),
(72, 3, 'lateral_raise', 'webcam', NULL, NULL, 4, 2, 2, 2, 0, '2026-01-22 06:44:01', '2026-01-22 06:44:36', 13, '2026-01-22 06:44:01'),
(73, 3, 'lateral_raise', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-01-22 06:44:39', '2026-01-22 06:45:29', 10, '2026-01-22 06:44:39'),
(74, 3, 'shoulder_press', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-01-22 06:45:32', '2026-01-22 06:46:31', 8, '2026-01-22 06:45:32'),
(81, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:24:33', '2026-02-23 01:24:38', 9, '2026-02-23 01:24:33'),
(82, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-23 01:24:43', '2026-02-23 01:25:00', 7, '2026-02-23 01:24:43'),
(83, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-23 01:25:09', '2026-02-23 01:25:26', 12, '2026-02-23 01:25:09'),
(84, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:33:36', '2026-02-23 01:33:53', 6, '2026-02-23 01:33:36'),
(85, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:34:45', '2026-02-23 01:34:48', 5, '2026-02-23 01:34:45'),
(86, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:41:04', '2026-02-23 01:41:05', 7, '2026-02-23 01:41:04'),
(87, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 01:41:20', '2026-02-23 01:41:22', 6, '2026-02-23 01:41:20'),
(88, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-23 01:50:13', '2026-02-23 01:50:44', 6, '2026-02-23 01:50:13'),
(89, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-23 02:07:46', '2026-02-23 02:08:06', 4, '2026-02-23 02:07:46'),
(90, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 02:09:58', '2026-02-23 02:10:02', 5, '2026-02-23 02:09:58'),
(91, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-23 02:12:34', '2026-02-23 02:12:52', 5, '2026-02-23 02:12:34'),
(92, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 02:18:21', '2026-02-23 02:18:30', 6, '2026-02-23 02:18:21'),
(93, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-02-23 02:18:47', '2026-02-23 02:19:12', 6, '2026-02-23 02:18:47'),
(94, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 10, 2, 2, 0, '2026-02-23 02:53:50', '2026-02-23 02:54:41', 8, '2026-02-23 02:53:50'),
(95, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-23 02:55:22', '2026-02-23 02:55:44', 7, '2026-02-23 02:55:22'),
(96, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-23 02:56:22', '2026-02-23 02:56:41', 4, '2026-02-23 02:56:22'),
(97, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-23 03:22:55', '2026-02-23 03:23:16', 9, '2026-02-23 03:22:55'),
(99, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-23 12:14:52', '2026-02-23 12:14:56', 11, '2026-02-23 12:14:52'),
(100, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-24 04:10:12', '2026-02-24 04:11:02', 12, '2026-02-24 04:10:12'),
(101, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-25 06:30:34', '2026-02-25 06:30:51', 20, '2026-02-25 06:30:34'),
(102, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-25 06:31:27', '2026-02-25 06:31:39', 12, '2026-02-25 06:31:27'),
(103, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 06:33:41', '2026-02-25 06:34:49', 15, '2026-02-25 06:33:41'),
(104, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 06:36:16', '2026-02-25 06:37:52', 8, '2026-02-25 06:36:16'),
(105, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 3, 4, 4, 0, '2026-02-25 06:58:43', '2026-02-25 06:59:08', 20, '2026-02-25 06:58:43'),
(106, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-25 06:59:22', '2026-02-25 06:59:40', 9, '2026-02-25 06:59:22'),
(107, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-25 06:59:57', '2026-02-25 07:00:13', 12, '2026-02-25 06:59:57'),
(108, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-25 07:00:40', '2026-02-25 07:00:50', 7, '2026-02-25 07:00:40'),
(109, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-25 07:01:17', '2026-02-25 07:01:30', 11, '2026-02-25 07:01:17'),
(110, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-02-25 07:04:06', '2026-02-25 07:04:22', 13, '2026-02-25 07:04:06'),
(111, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-25 07:04:41', '2026-02-25 07:04:45', 15, '2026-02-25 07:04:41'),
(112, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:23:11', '2026-02-25 07:23:51', 10, '2026-02-25 07:23:11'),
(113, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:27:05', '2026-02-25 07:27:14', 8, '2026-02-25 07:27:05'),
(114, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:40:01', '2026-02-25 07:40:54', 17, '2026-02-25 07:40:01'),
(115, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:45:52', '2026-02-25 07:46:10', 33, '2026-02-25 07:45:52'),
(116, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:47:35', '2026-02-25 07:47:42', 58, '2026-02-25 07:47:35'),
(117, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:48:42', '2026-02-25 07:48:54', 8, '2026-02-25 07:48:42'),
(118, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:53:26', '2026-02-25 07:53:31', 6, '2026-02-25 07:53:26'),
(119, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:54:33', '2026-02-25 07:54:37', 11, '2026-02-25 07:54:33'),
(120, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 07:58:12', '2026-02-25 07:58:35', 10, '2026-02-25 07:58:12'),
(121, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 08:12:04', '2026-02-25 08:12:12', 26, '2026-02-25 08:12:04'),
(122, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 9, 3, 3, 0, '2026-02-25 08:16:35', '2026-02-25 08:17:07', 7, '2026-02-25 08:16:35'),
(123, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 7, 4, 4, 0, '2026-02-25 08:17:27', '2026-02-25 08:17:56', 24, '2026-02-25 08:17:27'),
(124, 3, 'lateral_raise', 'webcam', NULL, NULL, 15, 10, 5, 5, 0, '2026-02-25 08:18:09', '2026-02-25 08:19:10', 24, '2026-02-25 08:18:09'),
(125, 3, 'bicep_curl', 'webcam', NULL, NULL, 12, 11, 1, 1, 0, '2026-02-25 08:20:30', '2026-02-25 08:21:25', 6, '2026-02-25 08:20:30'),
(126, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 08:21:49', '2026-02-25 08:22:37', 5, '2026-02-25 08:21:49'),
(127, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:09:41', '2026-02-25 09:09:46', 15, '2026-02-25 09:09:41'),
(128, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:10:10', '2026-02-25 09:10:52', 5, '2026-02-25 09:10:10'),
(129, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:20:55', '2026-02-25 09:21:05', 10, '2026-02-25 09:20:55'),
(130, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:21:20', '2026-02-25 09:21:26', 5, '2026-02-25 09:21:20'),
(131, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:34:26', NULL, NULL, '2026-02-25 09:34:26'),
(132, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:35:12', NULL, NULL, '2026-02-25 09:35:12'),
(133, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:38:48', '2026-02-25 09:38:55', 9, '2026-02-25 09:38:48'),
(134, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:42:27', NULL, NULL, '2026-02-25 09:42:27'),
(135, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-25 09:47:26', '2026-02-25 09:47:37', 11, '2026-02-25 09:47:26'),
(136, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 07:52:20', '2026-02-27 07:52:31', 14, '2026-02-27 07:52:20'),
(137, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 9, 2, 2, 0, '2026-02-27 08:09:19', '2026-02-27 08:09:52', 6, '2026-02-27 08:09:19'),
(138, 3, 'bicep_curl', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-02-27 08:13:38', '2026-02-27 08:13:56', 7, '2026-02-27 08:13:38'),
(139, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:33:41', '2026-02-27 08:33:50', 19, '2026-02-27 08:33:41'),
(140, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 08:33:57', '2026-02-27 08:34:18', 15, '2026-02-27 08:33:57'),
(141, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:35:25', '2026-02-27 08:35:46', 10, '2026-02-27 08:35:25'),
(142, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 08:37:57', '2026-02-27 08:38:27', 11, '2026-02-27 08:37:57'),
(143, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-02-27 08:57:02', '2026-02-27 08:57:33', 13, '2026-02-27 08:57:02'),
(144, 3, 'shoulder_press', 'webcam', NULL, NULL, 11, 8, 3, 3, 0, '2026-02-27 08:57:45', '2026-02-27 08:58:37', 7, '2026-02-27 08:57:45'),
(145, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 09:08:38', '2026-02-27 09:08:41', 5, '2026-02-27 09:08:38'),
(146, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 09:12:05', '2026-02-27 09:13:02', 44, '2026-02-27 09:12:05'),
(147, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-27 09:35:14', '2026-02-27 09:35:30', 7, '2026-02-27 09:35:14'),
(148, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 10:00:50', '2026-02-27 10:00:56', 13, '2026-02-27 10:00:50'),
(149, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 2, 1, 1, 0, '2026-02-27 10:02:06', '2026-02-27 10:02:21', 5, '2026-02-27 10:02:06'),
(150, 3, 'bicep_curl', 'webcam', NULL, NULL, 11, 10, 1, 1, 0, '2026-02-27 10:08:37', '2026-02-27 10:09:21', 7, '2026-02-27 10:08:37'),
(151, 3, 'shoulder_press', 'webcam', NULL, NULL, 8, 8, 0, 0, 0, '2026-02-27 10:10:02', '2026-02-27 10:10:56', 34, '2026-02-27 10:10:02'),
(152, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-27 10:11:14', '2026-02-27 10:11:22', 11, '2026-02-27 10:11:14'),
(153, 3, 'bicep_curl', 'webcam', NULL, NULL, 7, 7, 0, 0, 0, '2026-02-27 10:32:48', '2026-02-27 10:33:15', 7, '2026-02-27 10:32:48'),
(154, 3, 'bicep_curl', 'webcam', NULL, NULL, 2, 2, 0, 0, 0, '2026-02-27 10:34:54', '2026-02-27 10:35:00', 6, '2026-02-27 10:34:54'),
(155, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 4, 1, 1, 0, '2026-02-27 10:39:27', '2026-02-27 10:39:45', 4, '2026-02-27 10:39:27'),
(156, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-02-27 10:45:10', '2026-02-27 10:45:16', 4, '2026-02-27 10:45:10'),
(157, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 3, 1, 1, 0, '2026-02-27 10:46:29', '2026-02-27 10:46:47', 17, '2026-02-27 10:46:29'),
(158, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 0, 1, 1, 0, '2026-02-27 10:47:05', '2026-02-27 10:47:08', 9, '2026-02-27 10:47:05'),
(159, 3, 'bicep_curl', 'webcam', NULL, NULL, 1, 1, 0, 0, 0, '2026-02-27 10:47:31', '2026-02-27 10:47:35', 13, '2026-02-27 10:47:31'),
(160, 3, 'bicep_curl', 'webcam', NULL, NULL, 4, 4, 0, 0, 0, '2026-02-27 10:49:30', '2026-02-27 10:49:45', 5, '2026-02-27 10:49:30'),
(161, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-02-27 11:44:32', '2026-02-27 11:44:57', 8, '2026-02-27 11:44:32'),
(162, 3, 'bicep_curl', 'webcam', NULL, NULL, 5, 5, 0, 0, 0, '2026-03-18 09:43:27', '2026-03-18 09:43:49', 17, '2026-03-18 09:43:27'),
(163, 3, 'bicep_curl', 'webcam', NULL, NULL, 9, 8, 1, 1, 0, '2026-03-18 09:51:33', '2026-03-18 09:52:02', 6, '2026-03-18 09:51:33'),
(164, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:55:35', NULL, NULL, '2026-04-01 05:55:35'),
(165, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:55:53', NULL, NULL, '2026-04-01 05:55:53'),
(166, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:56:10', NULL, NULL, '2026-04-01 05:56:10'),
(167, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:59:01', NULL, NULL, '2026-04-01 05:59:01'),
(168, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 05:59:55', NULL, NULL, '2026-04-01 05:59:55'),
(169, 3, 'shoulder_press', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 06:01:34', NULL, NULL, '2026-04-01 06:01:34'),
(170, 3, 'bicep_curl', 'webcam', NULL, NULL, 3, 3, 0, 0, 0, '2026-04-01 06:04:50', '2026-04-01 06:05:06', 19, '2026-04-01 06:04:50'),
(171, 3, 'bicep_curl', 'webcam', NULL, NULL, 0, 0, 0, 0, 0, '2026-04-01 06:09:29', NULL, NULL, '2026-04-01 06:09:29'),
(172, 3, 'lateral_raise', 'webcam', NULL, NULL, 6, 6, 0, 0, 0, '2026-04-01 06:10:52', '2026-04-01 06:11:23', 6, '2026-04-01 06:10:52'),
(173, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 10, 0, 0, 0, '2026-04-01 06:11:50', '2026-04-01 06:12:28', 8, '2026-04-01 06:11:50'),
(174, 3, 'bicep_curl', 'webcam', NULL, NULL, 10, 8, 2, 2, 0, '2026-04-01 06:27:42', '2026-04-01 06:28:12', 9, '2026-04-01 06:27:42');

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
  `gender` enum('male','female','other','prefer_not_to_say') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `profile_photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qualification` varchar(190) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
(1, 'LiftRight Admin', 'admin@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'admin', 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2025-12-16 15:18:20', '2026-03-31 09:36:05', NULL, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'default'),
(2, 'LiftRight Trainer', 'trainer@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'trainer', 26, NULL, NULL, 'wasdasdadsas', 'uploads/profile_photos/user_2.jpg', '312das', 3, '[\"sdasdasdsada\"]', 1, '2025-12-16 15:18:20', '2026-04-01 06:30:17', NULL, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'default'),
(3, 'Test Trainee User1', 'user@liftright.local', '$2y$10$lFD.vTC26SMwnPRhRyWsnuf.zQwDEiGkIJcNTrZN4EQb2y.VJoUJe', 'user', 21, '2003-11-14', 'male', 'Test Traineeeeeeee', 'uploads/profile_photos/user_3.png', NULL, NULL, NULL, 1, '2025-12-16 15:18:20', '2026-04-04 03:44:23', 2, 'approved', 0, 0, NULL, NULL, '2026-02-24 16:40:02', 'default'),
(10, 'Test', 'zacgames.tv@gmail.com', '$2y$10$Wwem4iJxiP2OKtyqbb7u.OUpGg7awdcz16QzH/Oe6tLQ/PCUeYG4m', 'user', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-03-31 09:27:19', NULL, NULL, 'approved', 0, 0, NULL, NULL, '2026-03-31 17:27:19', 'default');

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
  MODIFY `event_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `email_verifications`
--
ALTER TABLE `email_verifications`
  MODIFY `verif_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `error_thresholds`
--
ALTER TABLE `error_thresholds`
  MODIFY `threshold_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `expert_reviews`
--
ALTER TABLE `expert_reviews`
  MODIFY `review_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `feedback_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=272;

--
-- AUTO_INCREMENT for table `login_otps`
--
ALTER TABLE `login_otps`
  MODIFY `otp_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `message_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notif_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `reset_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pending_registrations`
--
ALTER TABLE `pending_registrations`
  MODIFY `pending_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `profile_change_requests`
--
ALTER TABLE `profile_change_requests`
  MODIFY `request_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `rep_metrics`
--
ALTER TABLE `rep_metrics`
  MODIFY `rep_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=515;

--
-- AUTO_INCREMENT for table `rep_snapshots`
--
ALTER TABLE `rep_snapshots`
  MODIFY `snapshot_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

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
  MODIFY `invite_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `trainer_reviews`
--
ALTER TABLE `trainer_reviews`
  MODIFY `review_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `trainer_review_flags`
--
ALTER TABLE `trainer_review_flags`
  MODIFY `flag_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `training_logs`
--
ALTER TABLE `training_logs`
  MODIFY `log_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=175;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

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
