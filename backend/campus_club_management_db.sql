-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 22, 2025 at 12:09 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `campus_club_management_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `Club`
--

CREATE TABLE `Club` (
  `club_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `founded_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Club`
--

INSERT INTO `Club` (`club_id`, `name`, `description`, `founded_date`) VALUES
(1, 'Debate Club', 'A club for debate enthusiasts.', '2020-01-15'),
(3, 'Programming Club', 'A club for coding enthusiasts.', '2021-09-10'),
(4, 'Cultural Club', 'A club to celebrate diverse cultures.', '2018-11-05');

-- --------------------------------------------------------

--
-- Table structure for table `ClubRequest`
--

CREATE TABLE `ClubRequest` (
  `request_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `club_id` int(11) NOT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ClubRequest`
--

INSERT INTO `ClubRequest` (`request_id`, `user_id`, `club_id`, `status`, `requested_at`) VALUES
(2, 3, 4, 'Pending', '2025-11-22 08:27:31'),
(3, 3, 1, 'Approved', '2025-11-22 09:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `Event`
--

CREATE TABLE `Event` (
  `event_id` int(11) NOT NULL,
  `club_id` int(11) DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `date` date DEFAULT NULL,
  `venue` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Event`
--

INSERT INTO `Event` (`event_id`, `club_id`, `title`, `description`, `date`, `venue`) VALUES
(5, 3, 'IUPC 2025', 'Showcase your coding brilliance and teamwork in the Intra-University Programming Contest 2025!\r\nJoin the most exciting battle of logic, algorithms, and speed — and win amazing rewards while having fun with your teammates! 💻🔥\r\n🧠 Organized by: Programming Club, USTC\r\n⚙️ Powered by: Department of Computer Science and Engineering, USTC\r\n\r\n🏁 Contest Highlights\r\n👕 Exclusive T-Shirt for all registered participants\r\n💵 Attractive Crest & Cash Prizes for winning teams\r\n🏅 Certificates for all participants and winners\r\n🍱 Lunch & Refreshments will be provided during the contest\r\n\r\n🏁 Contest Requirements\r\n👥 Participation: Solo or Team\r\n🧩 Team Size: Minimum 1, Maximum 3 members\r\n💰 Registration Fee: Solo = 300 TK, Team = 900 TK\r\n🏫 Eligibility: Only for current students of USTC\r\n\r\n🗓️ Registration Deadline: 18 October 2025\r\n🗓️ Mock Contest Schedule: 7 November 2025\r\n🗓️ Main Contest Schedule: 10 November 2025\r\n\r\n🏁 Registration Link: https://forms.gle/5DVYPamMSWg5TZdEA', '2025-11-28', 'USTC D Block, Khulsi');

-- --------------------------------------------------------

--
-- Table structure for table `Finance`
--

CREATE TABLE `Finance` (
  `finance_id` int(11) NOT NULL,
  `club_id` int(11) DEFAULT NULL,
  `type` enum('Income','Expense') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `date` date DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Finance`
--

INSERT INTO `Finance` (`finance_id`, `club_id`, `type`, `amount`, `date`, `description`) VALUES
(1, 3, 'Income', 500.00, '2025-02-01', 'Membership Fees'),
(2, 3, 'Expense', 200.00, '2025-02-15', 'Event Supplies'),
(4, 3, 'Expense', 150.00, '2025-03-20', 'Venue Booking');

-- --------------------------------------------------------

--
-- Table structure for table `Membership`
--

CREATE TABLE `Membership` (
  `membership_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `club_id` int(11) DEFAULT NULL,
  `role` enum('President','Treasurer','Secretary','Member') NOT NULL,
  `join_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Membership`
--

INSERT INTO `Membership` (`membership_id`, `user_id`, `club_id`, `role`, `join_date`) VALUES
(1, 2, 3, 'President', '2020-02-01'),
(5, 3, 3, 'Member', '2025-11-22'),
(11, 3, 1, 'Member', '2025-11-22');

-- --------------------------------------------------------

--
-- Table structure for table `Notification`
--

CREATE TABLE `Notification` (
  `id` int(11) NOT NULL,
  `club_id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Notification`
--

INSERT INTO `Notification` (`id`, `club_id`, `title`, `description`) VALUES
(2, 3, 'Welcome!', 'Welcome to our app!');

-- --------------------------------------------------------

--
-- Table structure for table `Registration`
--

CREATE TABLE `Registration` (
  `reg_id` int(11) NOT NULL,
  `event_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `status` enum('Registered','Attended') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `Registration`
--

INSERT INTO `Registration` (`reg_id`, `event_id`, `user_id`, `status`) VALUES
(5, 5, 3, 'Registered');

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `user_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Admin','Executive','Member','Guest') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `User`
--

INSERT INTO `User` (`user_id`, `name`, `email`, `password`, `role`) VALUES
(1, 'Administration', 'admin@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Admin'),
(2, 'Executive User', 'executive@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Executive'),
(3, 'Member User', 'member@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Member');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Club`
--
ALTER TABLE `Club`
  ADD PRIMARY KEY (`club_id`);

--
-- Indexes for table `ClubRequest`
--
ALTER TABLE `ClubRequest`
  ADD PRIMARY KEY (`request_id`),
  ADD UNIQUE KEY `unique_pending_request` (`user_id`,`club_id`,`status`),
  ADD KEY `club_id` (`club_id`);

--
-- Indexes for table `Event`
--
ALTER TABLE `Event`
  ADD PRIMARY KEY (`event_id`),
  ADD KEY `club_id` (`club_id`);

--
-- Indexes for table `Finance`
--
ALTER TABLE `Finance`
  ADD PRIMARY KEY (`finance_id`),
  ADD KEY `club_id` (`club_id`);

--
-- Indexes for table `Membership`
--
ALTER TABLE `Membership`
  ADD PRIMARY KEY (`membership_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `club_id` (`club_id`);

--
-- Indexes for table `Notification`
--
ALTER TABLE `Notification`
  ADD PRIMARY KEY (`id`),
  ADD KEY `club_id` (`club_id`);

--
-- Indexes for table `Registration`
--
ALTER TABLE `Registration`
  ADD PRIMARY KEY (`reg_id`),
  ADD KEY `event_id` (`event_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Club`
--
ALTER TABLE `Club`
  MODIFY `club_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `ClubRequest`
--
ALTER TABLE `ClubRequest`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `Event`
--
ALTER TABLE `Event`
  MODIFY `event_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `Finance`
--
ALTER TABLE `Finance`
  MODIFY `finance_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `Membership`
--
ALTER TABLE `Membership`
  MODIFY `membership_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `Notification`
--
ALTER TABLE `Notification`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `Registration`
--
ALTER TABLE `Registration`
  MODIFY `reg_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `User`
--
ALTER TABLE `User`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ClubRequest`
--
ALTER TABLE `ClubRequest`
  ADD CONSTRAINT `clubrequest_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `clubrequest_ibfk_2` FOREIGN KEY (`club_id`) REFERENCES `Club` (`club_id`) ON DELETE CASCADE;

--
-- Constraints for table `Event`
--
ALTER TABLE `Event`
  ADD CONSTRAINT `event_ibfk_1` FOREIGN KEY (`club_id`) REFERENCES `Club` (`club_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Finance`
--
ALTER TABLE `Finance`
  ADD CONSTRAINT `finance_ibfk_1` FOREIGN KEY (`club_id`) REFERENCES `Club` (`club_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Membership`
--
ALTER TABLE `Membership`
  ADD CONSTRAINT `membership_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `membership_ibfk_2` FOREIGN KEY (`club_id`) REFERENCES `Club` (`club_id`) ON DELETE CASCADE;

--
-- Constraints for table `Notification`
--
ALTER TABLE `Notification`
  ADD CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`club_id`) REFERENCES `Club` (`club_id`) ON DELETE CASCADE;

--
-- Constraints for table `Registration`
--
ALTER TABLE `Registration`
  ADD CONSTRAINT `registration_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `Event` (`event_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `registration_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `User` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
