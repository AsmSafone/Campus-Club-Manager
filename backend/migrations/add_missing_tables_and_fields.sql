-- Migration script to add all missing tables and fields
-- Run this to make the database fully dynamic

-- Add missing fields to User table
ALTER TABLE `User` 
ADD COLUMN `phone` varchar(20) DEFAULT NULL AFTER `email`,
ADD COLUMN `major` varchar(100) DEFAULT NULL AFTER `phone`,
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `role`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to Club table
ALTER TABLE `Club`
ADD COLUMN `logo_url` varchar(500) DEFAULT NULL AFTER `description`,
ADD COLUMN `category` varchar(50) DEFAULT 'General' AFTER `logo_url`,
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `founded_date`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to Event table
ALTER TABLE `Event`
ADD COLUMN `image_url` varchar(500) DEFAULT NULL AFTER `venue`,
ADD COLUMN `status` enum('Pending','Confirmed','Cancelled','Completed') DEFAULT 'Pending' AFTER `image_url`,
ADD COLUMN `time` time DEFAULT NULL AFTER `date`,
ADD COLUMN `capacity` int(11) DEFAULT NULL AFTER `status`,
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `capacity`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to Notification table
ALTER TABLE `Notification`
ADD COLUMN `timestamp` timestamp NOT NULL DEFAULT current_timestamp() AFTER `description`,
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `timestamp`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`,
CHANGE COLUMN `description` `description` text DEFAULT NULL;

-- Create NotificationSettings table
CREATE TABLE IF NOT EXISTS `NotificationSettings` (
  `settings_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `email_notifications` tinyint(1) NOT NULL DEFAULT 0,
  `push_notifications` tinyint(1) NOT NULL DEFAULT 1,
  `club_announcements` tinyint(1) NOT NULL DEFAULT 1,
  `new_event_announcements` tinyint(1) NOT NULL DEFAULT 1,
  `rsvp_event_reminders` tinyint(1) NOT NULL DEFAULT 1,
  `reminder_time` varchar(50) DEFAULT '2 hours before',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`settings_id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `notificationsettings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Add missing fields to Membership table
ALTER TABLE `Membership`
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `join_date`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to Finance table
ALTER TABLE `Finance`
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `description`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to Registration table
ALTER TABLE `Registration`
ADD COLUMN `registered_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `status`,
ADD COLUMN `created_at` timestamp NOT NULL DEFAULT current_timestamp() AFTER `registered_at`,
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`;

-- Add missing fields to ClubRequest table
ALTER TABLE `ClubRequest`
ADD COLUMN `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `requested_at`;

-- Add indexes for better performance
CREATE INDEX `idx_user_email` ON `User` (`email`);
CREATE INDEX `idx_event_club_date` ON `Event` (`club_id`, `date`);
CREATE INDEX `idx_notification_club_timestamp` ON `Notification` (`club_id`, `timestamp`);
CREATE INDEX `idx_membership_user_club` ON `Membership` (`user_id`, `club_id`);
CREATE INDEX `idx_registration_event_user` ON `Registration` (`event_id`, `user_id`);

