CREATE DATABASE IF NOT EXISTS campus_club_management_db;
USE campus_club_management_db;

CREATE TABLE IF NOT EXISTS User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'executive', 'member', 'guest') NOT NULL DEFAULT 'guest'
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
    role ENUM('President', 'Secretary', 'Member') NOT NULL,
    join_date DATE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE ON UPDATE CASCADE
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
    status ENUM('registered', 'attended') NOT NULL,
    FOREIGN KEY (event_id) REFERENCES Event(event_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Finance (
    finance_id INT AUTO_INCREMENT PRIMARY KEY,
    club_id INT,
    type ENUM('income', 'expense') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    date DATE,
    description TEXT,
    FOREIGN KEY (club_id) REFERENCES Club(club_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);


insert into User (name, email, password, role) values 
('admin', 'admin@gmail.com', '1234', 'admin'),
('John Doe', 'john@doe.com', '1234', 'guest'),
('Jane Smith', 'jane@smith.com', '1234', 'executive'),
('Alice Johnson', 'alice@jong.com', '1234', 'member'),
('asd dsa', 'asd@dsa.com', '1234', 'member');

insert into Club (name, description, founded_date) values 
('Photography Club', 'A club for photography enthusiasts.', '2020-01-15'),
('Robotics Club', 'Exploring the world of robotics and AI.', '2019-03-22'),
('Debate Club', 'Exploring the world of robotics and AI.', '2021-05-28');