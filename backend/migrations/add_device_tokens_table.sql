-- Migration script to add device tokens table for push notifications
-- This table stores FCM device tokens for each user

CREATE TABLE IF NOT EXISTS `DeviceToken` (
  `token_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `device_token` varchar(255) NOT NULL,
  `platform` enum('android','ios','web') DEFAULT 'android',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `unique_user_device` (`user_id`, `device_token`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `devicetoken_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

