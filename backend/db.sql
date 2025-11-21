-- CREATE DATABASE IF NOT EXISTS campus_club_management_db;
-- USE sql12808718;
USE campus_club_management_db;

CREATE TABLE IF NOT EXISTS User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'Executive', 'Member') NOT NULL DEFAULT 'Member'
);

CREATE TABLE IF NOT EXISTS Club (
    club_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    founded_date DATE
);

CREATE TABLE IF NOT EXISTS Membership (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    club_id INT,
    role ENUM('President', 'Treasurer', 'Secretary', 'Member') NOT NULL,
    join_date DATE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    club_id INT,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    date DATE,
    venue VARCHAR(150),
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Registration (
    reg_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    user_id INT,
    status ENUM('Registered', 'Attended') NOT NULL,
    FOREIGN KEY (event_id) REFERENCES Event(event_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Finance (
    finance_id INT AUTO_INCREMENT PRIMARY KEY,
    club_id INT,
    type ENUM('Income', 'Expense') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    date DATE,
    description TEXT,
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Notifications (simplified)
CREATE TABLE IF NOT EXISTS Notification (
    id INT AUTO_INCREMENT PRIMARY KEY,
    club_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE
);



insert ignore into User (name, email, password, role) values ('Administration', 'admin@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Admin'),('Executive User', 'executive@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Executive'),('Member User', 'member@gmail.com', '$2a$12$Aj0bUAOQJ3Jesk6/GyAjZ.mMxWroMXC5bXHpT.hRQXNH/lYlzWWU6', 'Member');

insert ignore into Club (name, description, founded_date) values ('Science Club', 'A club for science enthusiasts.', '2020-01-15'), ('Art Club', 'A club for art lovers.', '2019-05-20'), ('Programming Club', 'A club for coding enthusiasts.', '2021-09-10'), ('Cultural Club', 'A club to celebrate diverse cultures.', '2018-11-05');

insert ignore into Membership (user_id, club_id, role, join_date) values (2, 1, 'President', '2020-02-01'), (3, 1, 'Member', '2020-03-15'), (4, 2, 'Secretary', '2019-06-10'), (5, 3, 'Member', '2021-10-05');

insert ignore into Event (club_id, title, description, date, venue) values (1, 'Science Fair', 'An event to showcase scientific projects.', '2022-03-15', 'Auditorium'), (2, 'Art Exhibition', 'Display of artworks by club members.', '2022-04-20', 'Art Gallery'), (3, 'Coding Marathon', 'A 24-hour coding competition.', '2022-05-10', 'Computer Lab');

insert ignore into Registration (event_id, user_id, status) values (1, 3, 'Registered'), (2, 4, 'Attended'), (3, 5, 'Registered');

insert ignore into Finance (club_id, type, amount, date, description) values (1, 'Income', 500.00, '2022-02-01', 'Membership Fees'), (1, 'Expense', 200.00, '2022-02-15', 'Event Supplies'), (2, 'Income', 300.00, '2022-03-01', 'Sponsorship'), (3, 'Expense', 150.00, '2022-03-20', 'Venue Booking');
