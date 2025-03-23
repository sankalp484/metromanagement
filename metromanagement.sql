-- Drop Database if it exists and create a fresh one
DROP DATABASE IF EXISTS metro_management;
CREATE DATABASE metro_management;
USE metro_management;

-- Metro Stations Table (Updated to support multiple lines)
CREATE TABLE station (
                         st_code VARCHAR(10),
                         st_name VARCHAR(50) NOT NULL,
                         line_color ENUM('Blue', 'Pink', 'Red') NOT NULL,

                         PRIMARY KEY (st_code, line_color) -- Allows a station to be on multiple lines
);

-- Metro Routes Table
CREATE TABLE metro_route (
                             route_id VARCHAR(10) PRIMARY KEY,
                             route_name VARCHAR(50) NOT NULL,
                             line_color VARCHAR(20) NOT NULL,
                             stations TEXT NOT NULL
);




-- Metro Trains Table
CREATE TABLE metro (
                       metro_id VARCHAR(6) PRIMARY KEY,
                       metro_name VARCHAR(120) NOT NULL,
                       line_color ENUM('Blue', 'Pink', 'Red') NOT NULL
);

-- Ticket Table with Auto-Calculated Fare
CREATE TABLE ticket (
                        pnr VARCHAR(10) PRIMARY KEY,
                        username VARCHAR(50) NOT NULL,
                        entry_station VARCHAR(10) NOT NULL,
                        exit_station VARCHAR(10) NOT NULL,
                        fare INT DEFAULT 0 NOT NULL,  -- Fare will be updated via trigger
                        booking_details VARCHAR(255),
                        booking_date DATE NOT NULL,  -- Added booking_date for ticket history queries
                        FOREIGN KEY (entry_station) REFERENCES station(st_code),
                        FOREIGN KEY (exit_station) REFERENCES station(st_code)
);

-- Metro Schedule Table
CREATE TABLE metro_schedule (
                                schedule_id INT PRIMARY KEY AUTO_INCREMENT,
                                metro_id VARCHAR(10) NOT NULL,  -- Now tracks specific metros instead of just routes
                                route_id VARCHAR(10) NOT NULL,
                                st_code VARCHAR(10) NOT NULL,
                                arrival_time TIME NOT NULL,
                                departure_time TIME NOT NULL,
                                platform INT NOT NULL,
                                direction ENUM('Forward', 'Reverse') NOT NULL,  -- Indicates metro direction
                                UNIQUE (metro_id, st_code, arrival_time),  -- Ensures a metro doesn't duplicate timing at the same station
                                FOREIGN KEY (route_id) REFERENCES metro_route(route_id),
                                FOREIGN KEY (st_code) REFERENCES station(st_code)
);


-- Time Table for Each Station
CREATE TABLE time_table (
                            metro_id VARCHAR(6) NOT NULL,
                            st_code VARCHAR(10) NOT NULL,
                            arrival TIME NOT NULL,
                            departure TIME NOT NULL,
                            PRIMARY KEY (metro_id, st_code),
                            FOREIGN KEY (metro_id) REFERENCES metro(metro_id),
                            FOREIGN KEY (st_code) REFERENCES station(st_code)
);

-- Admin Table
CREATE TABLE admin (
                       user_name VARCHAR(20) PRIMARY KEY,
                       passcode VARCHAR(30),
                       CHECK (LENGTH(passcode) > 5)
);

-- Create User Table
CREATE TABLE user (
                      user_id VARCHAR(20) PRIMARY KEY,
                      full_name VARCHAR(50) NOT NULL,
                      email VARCHAR(100) UNIQUE NOT NULL,
                      phone VARCHAR(15) UNIQUE NOT NULL
);
CREATE TABLE passenger (
                           passenger_id INT PRIMARY KEY AUTO_INCREMENT,  -- Unique ID for each passenger
                           user_id VARCHAR(20) NOT NULL,  -- Links to the user who bought the ticket
                           pnr VARCHAR(10) NOT NULL,  -- Links to the ticket purchased
                           FOREIGN KEY (user_id) REFERENCES user(user_id),
                           FOREIGN KEY (pnr) REFERENCES ticket(pnr)
);
CREATE TABLE station_transfer (
                                  st_code VARCHAR(10),
                                  from_line ENUM('Blue', 'Pink', 'Red'),
                                  to_line ENUM('Blue', 'Pink', 'Red'),
                                  PRIMARY KEY (st_code, from_line, to_line),
                                  FOREIGN KEY (st_code) REFERENCES station(st_code)
);


-- Create Credentials Table
CREATE TABLE credentials (
                             user_id VARCHAR(20) PRIMARY KEY,
                             passcode VARCHAR(30) NOT NULL,
                             FOREIGN KEY (user_id) REFERENCES user(user_id),
                             CHECK (LENGTH(passcode) > 5)
);
CREATE TABLE fare (
                      source VARCHAR(10),
                      destination VARCHAR(10),
                      distance INT,
                      base_fare INT,  -- Example: ₹10 per km
                      total_fare INT, -- Precomputed fare (distance * base_fare)
                      PRIMARY KEY (source, destination),
                      FOREIGN KEY (source) REFERENCES station(st_code),
                      FOREIGN KEY (destination) REFERENCES station(st_code)
);
CREATE TABLE metro_stop (
                            metro_id VARCHAR(6),
                            st_code VARCHAR(10),
                            line_color ENUM('Blue', 'Pink', 'Red') NOT NULL,
                            PRIMARY KEY (metro_id, st_code, line_color),
                            FOREIGN KEY (metro_id) REFERENCES metro(metro_id),
                            FOREIGN KEY (st_code, line_color) REFERENCES station(st_code, line_color)
);


-- Insert Users
INSERT INTO user (user_id, full_name, email, phone) VALUES
                                                        ('alice123', 'Alice Johnson', 'alice.johnson@example.com', '9876543210'),
                                                        ('bob456', 'Bob Williams', 'bob.williams@example.com', '9876543211'),
                                                        ('charlie789', 'Charlie Brown', 'charlie.brown@example.com', '9876543212'),
                                                        ('dave321', 'Dave Smith', 'dave.smith@example.com', '9876543213'),
                                                        ('emma654', 'Emma Davis', 'emma.davis@example.com', '9876543214'),
                                                        ('gore', 'gore', 'gore@example.com', '9875543214'),
                                                        ('hyyy', 'hyyy david', 'hy.david@example.com', '9876543234');

INSERT INTO credentials (user_id, passcode) VALUES
                                                ('alice123', 'securePass1'),
                                                ('bob456', 'mySecretPwd2'),
                                                ('charlie789', 'CharliePass3'),
                                                ('dave321', 'DaveStrongPwd4'),
                                                ('emma654', 'EmmaSafeKey5'),
                                                ('gore', 'goress1'),
                                                ('hyyy', 'hyyydavid1');



-- Insert Metro Stations (Now supporting multiple lines)
INSERT INTO station (st_code, st_name, line_color) VALUES

                                                       -- Blue Line
                                                       ('S1', 'Central Square', 'Blue'),
                                                       ('S2', 'Downtown', 'Blue'),
                                                       ('S3', 'City Center', 'Blue'),
                                                       ('S4', 'Tech Park', 'Blue'),


                                                       -- Pink Line
                                                       ('S2', 'Downtown', 'Pink'),
                                                       ('S5', 'Airport', 'Pink'),
                                                       ('S6', 'University', 'Pink'),
                                                       ('S7', 'Sunset Avenue', 'Pink'),

                                                       -- Red Line
                                                       ('S3', 'City Center', 'Red'),
                                                       ('S6', 'University', 'Red'),
                                                       ('S8', 'North Station', 'Red'),
                                                       ('S9', 'West End', 'Red');


INSERT INTO metro_route (route_id, route_name, line_color, stations) VALUES
                                                                         -- Normal Direction Routes
                                                                         ('R1', 'Blue Line Route', 'Blue', 'S1 S2 S3 S4'),
                                                                         ('R2', 'Pink Line Route', 'Pink', 'S5 S2 S6 S7'),
                                                                         ('R3', 'Red Line Route', 'Red', 'S8 S6 S9 S3'),

                                                                         -- Reverse Direction Routes
                                                                         ('R4', 'Blue Line Reverse', 'Blue', 'S4 S3 S2 S1'),
                                                                         ('R5', 'Pink Line Reverse', 'Pink', 'S7 S6 S2 S5'),
                                                                         ('R6', 'Red Line Reverse', 'Red', 'S3 S9 S6 S8');




-- Insert Metro Data
INSERT INTO metro (metro_id, metro_name, line_color) VALUES
                                                         -- Blue Line Metros
                                                         ('M11', 'Blue Metro 1', 'Blue'),
                                                         ('M12', 'Blue Metro 2', 'Blue'),
                                                         ('M13', 'Blue Metro 3', 'Blue'),
                                                         ('M14', 'Blue Metro 4', 'Blue'),

                                                         -- Red Line Metros
                                                         ('M15', 'Red Metro 1', 'Red'),
                                                         ('M16', 'Red Metro 2', 'Red'),
                                                         ('M17', 'Red Metro 3', 'Red'),
                                                         ('M18', 'Red Metro 4', 'Red'),

                                                         -- Pink Line Metros
                                                         ('M19', 'Pink Metro 1', 'Pink'),
                                                         ('M20', 'Pink Metro 2', 'Pink'),
                                                         ('M21', 'Pink Metro 3', 'Pink'),
                                                         ('M22', 'Pink Metro 4', 'Pink');

INSERT INTO metro_schedule (metro_id, route_id, st_code, arrival_time, departure_time, platform, direction) VALUES
                                                                                                                -- Initial Departure (All metros start at 08:00 AM from different stations)
                                                                                                                ('M14', 'R1', 'S1', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M13', 'R1', 'S2', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M12', 'R1', 'S3', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M11', 'R1', 'S4', '08:00:00', '08:02:00', 1, 'Forward'),

                                                                                                                -- Progressing through stations
                                                                                                                ('M14', 'R1', 'S2', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M13', 'R1', 'S3', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M12', 'R1', 'S4', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M11', 'R4', 'S3', '08:05:00', '08:07:00', 2, 'Reverse'),  -- M11 reaches last stop and reverses

                                                                                                                -- Continuing movement
                                                                                                                ('M14', 'R1', 'S3', '08:10:00', '08:12:00', 1, 'Forward'),
                                                                                                                ('M13', 'R1', 'S4', '08:10:00', '08:12:00', 1, 'Forward'),
                                                                                                                ('M12', 'R4', 'S3', '08:10:00', '08:12:00', 2, 'Reverse'),  -- M12 reverses after reaching last station
                                                                                                                ('M11', 'R4', 'S2', '08:10:00', '08:12:00', 2, 'Reverse'),

                                                                                                                -- More forward & reverse routes as metros reach last station
                                                                                                                ('M14', 'R1', 'S4', '08:15:00', '08:17:00', 1, 'Forward'),
                                                                                                                ('M13', 'R4', 'S3', '08:15:00', '08:17:00', 2, 'Reverse'),
                                                                                                                ('M12', 'R4', 'S2', '08:15:00', '08:17:00', 2, 'Reverse'),
                                                                                                                ('M11', 'R4', 'S1', '08:15:00', '08:17:00', 2, 'Reverse'),

                                                                                                                -- Now all metros have reversed
                                                                                                                ('M14', 'R4', 'S3', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M13', 'R4', 'S2', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M12', 'R4', 'S1', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M11', 'R4', 'S2', '08:20:00', '08:22:00', 1, 'Forward'),

                                                                                                                -- Initial Departure (Pink Line starts at 08:00 AM from different stations)
                                                                                                                ('M22', 'R2', 'S5', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M21', 'R2', 'S2', '08:00:00', '08:02:00', 3, 'Forward'),
                                                                                                                ('M20', 'R2', 'S6', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M19', 'R2', 'S7', '08:00:00', '08:02:00', 1, 'Forward'),

                                                                                                                -- Progressing through stations
                                                                                                                ('M22', 'R2', 'S2', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M21', 'R2', 'S6', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M20', 'R2', 'S7', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M19', 'R2', 'S6', '08:05:00', '08:07:00', 2, 'Reverse'),  -- M19 reverses after reaching last station

                                                                                                                -- Continuing movement
                                                                                                                ('M22', 'R2', 'S6', '08:10:00', '08:12:00', 1, 'Forward'),
                                                                                                                ('M21', 'R2', 'S7', '08:10:00', '08:12:00', 1, 'Forward'),
                                                                                                                ('M20', 'R2', 'S6', '08:10:00', '08:12:00', 2, 'Reverse'),  -- M20 reverses after reaching last station
                                                                                                                ('M19', 'R2', 'S2', '08:10:00', '08:12:00', 4, 'Reverse'),  -- Corrected from S6 to S2

                                                                                                                -- More forward & reverse routes as metros reach last station
                                                                                                                ('M22', 'R2', 'S7', '08:15:00', '08:17:00', 1, 'Forward'),
                                                                                                                ('M21', 'R2', 'S6', '08:15:00', '08:17:00', 2, 'Reverse'),
                                                                                                                ('M20', 'R2', 'S2', '08:15:00', '08:17:00', 4, 'Reverse'),
                                                                                                                ('M19', 'R2', 'S5', '08:15:00', '08:17:00', 2, 'Reverse'),

                                                                                                                -- Now all metros have reversed
                                                                                                                ('M22', 'R2', 'S6', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M21', 'R2', 'S2', '08:20:00', '08:22:00', 4, 'Reverse'),
                                                                                                                ('M20', 'R2', 'S5', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M19', 'R2', 'S2', '08:20:00', '08:22:00', 3, 'forward');




-- Insert Metro Stops for Red Line
INSERT INTO metro_schedule (metro_id, route_id, st_code, arrival_time, departure_time, platform, direction) VALUES
                                                                                                                -- Initial Departure (Red Line starts at 08:00 AM from different stations)
                                                                                                                ('M18', 'R3', 'S8', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M17', 'R3', 'S6', '08:00:00', '08:02:00', 3, 'Forward'),
                                                                                                                ('M16', 'R3', 'S9', '08:00:00', '08:02:00', 1, 'Forward'),
                                                                                                                ('M15', 'R3', 'S3', '08:00:00', '08:02:00', 3, 'Forward'),

                                                                                                                -- Progressing through stations
                                                                                                                ('M18', 'R3', 'S6', '08:05:00', '08:07:00', 3, 'Forward'),
                                                                                                                ('M17', 'R3', 'S9', '08:05:00', '08:07:00', 1, 'Forward'),
                                                                                                                ('M16', 'R3', 'S3', '08:05:00', '08:07:00', 3, 'Forward'),
                                                                                                                ('M15', 'R3', 'S9', '08:05:00', '08:07:00', 2, 'Reverse'),  -- M15 reaches last stop and reverses

                                                                                                                -- Continuing movement
                                                                                                                ('M18', 'R3', 'S9', '08:10:00', '08:12:00', 1, 'Forward'),
                                                                                                                ('M17', 'R3', 'S3', '08:10:00', '08:12:00', 3, 'Forward'),
                                                                                                                ('M16', 'R3', 'S9', '08:10:00', '08:12:00', 2, 'Reverse'),  -- M16 reverses after reaching last station
                                                                                                                ('M15', 'R3', 'S6', '08:10:00', '08:12:00', 4, 'Reverse'),

                                                                                                                -- More forward & reverse routes as metros reach last station
                                                                                                                ('M18', 'R3', 'S3', '08:15:00', '08:17:00', 3, 'Forward'),
                                                                                                                ('M17', 'R3', 'S9', '08:15:00', '08:17:00', 2, 'Reverse'),
                                                                                                                ('M16', 'R3', 'S6', '08:15:00', '08:17:00', 4, 'Reverse'),
                                                                                                                ('M15', 'R3', 'S8', '08:15:00', '08:17:00', 2, 'Reverse'),

                                                                                                                -- Now all metros have reversed
                                                                                                                ('M18', 'R3', 'S9', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M17', 'R3', 'S6', '08:20:00', '08:22:00', 4, 'Reverse'),
                                                                                                                ('M16', 'R3', 'S8', '08:20:00', '08:22:00', 2, 'Reverse'),
                                                                                                                ('M15', 'R3', 'S6', '08:20:00', '08:22:00', 3, 'Forward');






INSERT INTO ticket (pnr, username, entry_station, exit_station, fare ,booking_details, booking_date)
VALUES
    ('PNR001', 'alice123', 'S1', 'S8', 50, 'Online - UPI', '2024-03-20'),
    ('PNR002', 'bob456', 'S2', 'S3', 54, 'Counter - Cash', '2024-03-21'),
    ('PNR003', 'charlie789', 'S4', 'S6',56,  'Online - Credit Card', '2024-03-22'),
    ('PNR004', 'dave321', 'S2', 'S1', 10, 'Online - Net Banking', '2024-03-22'),
    ('PNR005', 'emma654', 'S3', 'S1', 32,'Counter - Debit Card', '2024-03-23');

INSERT INTO passenger (user_id, pnr)
VALUES
    ('alice123', 'PNR001'),
    ('bob456', 'PNR002'),
    ('charlie789', 'PNR003'),
    ('dave321', 'PNR004'),
    ('emma654', 'PNR005');





SELECT m.metro_id, m.metro_name, ms.route_id, ms.arrival_time, ms.departure_time, ms.platform, ms.direction
FROM metro_schedule ms
         JOIN metro m ON ms.metro_id = m.metro_id
WHERE ms.st_code = 'S3'  -- Replace with the desired station code
  AND '08:10:00' BETWEEN ms.arrival_time AND ms.departure_time;  -- Replace with the desired time


SELECT ms1.metro_id, m.metro_name, ms1.st_code AS start_station, ms1.arrival_time AS start_time,
       ms2.st_code AS end_station, ms2.arrival_time AS end_time
FROM metro_schedule ms1
         JOIN metro_schedule ms2 ON ms1.metro_id = ms2.metro_id
         JOIN metro m ON ms1.metro_id = m.metro_id
WHERE ms1.st_code = 'S6'  -- Starting station
  AND ms2.st_code = 'S2'  -- Destination station
  AND ms1.arrival_time < ms2.arrival_time  -- Ensuring that the metro reaches S4 after S6
ORDER BY ms1.arrival_time;


SELECT
    ms.metro_id,
    m.metro_name,
    ms.st_code,
    s.st_name,
    ms.platform,
    ms.arrival_time,
    ms.departure_time,
    ms.direction
FROM metro_schedule ms
         JOIN metro m ON ms.metro_id = m.metro_id
         JOIN station s ON ms.st_code = s.st_code
WHERE m.metro_id = 'M11'  -- Replace 'M12' with your input value
ORDER BY ms.arrival_time;


SELECT *
FROM ticket
WHERE booking_date = '2024-03-22';


SELECT m.line_color, COUNT(DISTINCT ms.metro_id) AS metro_count
FROM metro_schedule ms
         JOIN metro m ON ms.metro_id = m.metro_id
WHERE ms.st_code = 'S2'
GROUP BY m.line_color;



SELECT COUNT(*) AS passenger_count
FROM ticket
WHERE entry_station = 'S1'
  AND exit_station = 'S5'
  AND booking_date = '2024-03-20';

SELECT COUNT(DISTINCT p.passenger_id) AS total_passengers
FROM passenger p
         JOIN ticket t ON p.pnr = t.pnr
         JOIN station s1 ON t.entry_station = s1.st_code
         JOIN station s2 ON t.exit_station = s2.st_code
WHERE (s1.line_color = 'Blue' OR s2.line_color = 'Blue')
  AND t.booking_date = '2024-03-22'; -- Replace with the required date



-- most popular station , route between station
SELECT entry_station, COUNT(*) AS entry_count
FROM ticket
GROUP BY entry_station
ORDER BY entry_count DESC
    LIMIT 1;




SELECT
    COALESCE(AVG(passenger_count), 0) AS avg_passengers_per_metro
FROM (
         SELECT
             ms.metro_id,
             COUNT(p.passenger_id) AS passenger_count
         FROM metro_schedule ms
                  LEFT JOIN ticket t ON ms.st_code = t.entry_station  -- Linking tickets to metro stations
                  LEFT JOIN passenger p ON t.pnr = p.pnr  -- Counting passengers for each ticket
         GROUP BY ms.metro_id
     ) metro_passenger_counts;


SELECT u.user_id, u.full_name
FROM user u
         LEFT JOIN passenger p ON u.user_id = p.user_id
WHERE p.user_id IS NULL;

SELECT
    ms.metro_id,
    m.metro_name,
    ms.platform,
    ms.direction,
    mr.route_name AS destination_route,
    mr.stations AS destination_stations
FROM metro_schedule ms
         JOIN metro m ON ms.metro_id = m.metro_id
         JOIN metro_route mr ON ms.route_id = mr.route_id
WHERE ms.st_code = 'S3'  -- Replace 'S3' with the desired station code
  AND '08:05:00' BETWEEN ms.arrival_time AND ms.departure_time;  -- Replace '08:05:00' with the desired time

SELECT st_code
FROM station
WHERE line_color = 'Blue'
  AND st_code IN (
    SELECT st_code
    FROM station
    WHERE line_color = 'Red'
);


WITH station_traffic AS (
    -- Entry traffic: count tickets by entry station
    SELECT
        s.st_code,
        s.st_name,
        DAYOFWEEK(t.booking_date) AS day_of_week,
        COUNT(*) AS passenger_count
    FROM ticket t
             JOIN station s ON t.entry_station = s.st_code
    GROUP BY s.st_code, s.st_name, DAYOFWEEK(t.booking_date)

    UNION ALL

    -- Exit traffic: count tickets by exit station
    SELECT
        s.st_code,
        s.st_name,
        DAYOFWEEK(t.booking_date) AS day_of_week,
        COUNT(*) AS passenger_count
    FROM ticket t
             JOIN station s ON t.exit_station = s.st_code
    GROUP BY s.st_code, s.st_name, DAYOFWEEK(t.booking_date)
)
SELECT
    st_code,
    st_name,
    day_of_week,
    SUM(passenger_count) AS total_passengers
FROM station_traffic
GROUP BY st_code, st_name, day_of_week
ORDER BY total_passengers DESC;

-- 14
SELECT SUM(
               CASE
                   WHEN s1.line_color <> s2.line_color THEN 1
                   ELSE 0
                   END
       ) AS total_line_changes
FROM ticket t
         JOIN station s1 ON t.entry_station = s1.st_code
         JOIN station s2 ON t.exit_station = s2.st_code
WHERE t.booking_date = '2024-03-20';

