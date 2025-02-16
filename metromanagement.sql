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


-- Metro Stops Table
CREATE TABLE metro_stop (
    route_id VARCHAR(10) NOT NULL,
    st_code VARCHAR(10) NOT NULL,
    stop_order INT NOT NULL,
    platform INT NOT NULL,  -- Added platform information
    PRIMARY KEY (route_id, st_code, platform), 
    FOREIGN KEY (route_id) REFERENCES metro_route(route_id),
    FOREIGN KEY (st_code) REFERENCES station(st_code)
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
    FOREIGN KEY (entry_station) REFERENCES station(st_code),
    FOREIGN KEY (exit_station) REFERENCES station(st_code)
);

-- Metro Schedule Table
CREATE TABLE metro_schedule (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    route_id VARCHAR(10) NOT NULL,
    st_code VARCHAR(10) NOT NULL,
    arrival_time TIME NOT NULL,
    departure_time TIME NOT NULL,
    platform INT NOT NULL,
    UNIQUE (st_code, platform, arrival_time), 
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

-- Insert Users
INSERT INTO user (user_id, full_name, email, phone) VALUES
    ('U001', 'Alice Johnson', 'alice@example.com', '1234567890'),
    ('U002', 'Bob Smith', 'bob@example.com', '0987654321'),
    ('U003', 'Charlie Brown', 'charlie@example.com', '1122334455');

-- Insert Credentials
INSERT INTO credentials (user_id, passcode) VALUES
    ('U001', 'securePass1'),
    ('U002', 'mySecretPwd2'),
    ('U003', 'CharliePass3');

-- Insert Metro Stations (Now supporting multiple lines)
INSERT INTO station (st_code, st_name, line_color) VALUES
    -- Shared Stations (Belong to Multiple Lines)
    ('S1', 'Central Square', 'Blue'),
    ('S1', 'Central Square', 'Red'),
    ('S2', 'Downtown', 'Blue'),
    ('S2', 'Downtown', 'Pink'),
    ('S3', 'City Center', 'Red'),
    ('S3', 'City Center', 'Pink'),
    ('S4', 'Tech Park', 'Blue'),
    ('S4', 'Tech Park', 'Red'),
    ('S5', 'Airport', 'Blue'),
    ('S5', 'Airport', 'Pink'),
    ('S6', 'University', 'Red'),
    ('S6', 'University', 'Pink'),

    -- Unique to One Line
    ('S7', 'Main Street', 'Blue'),
    ('S8', 'East Side', 'Blue'),
    ('S9', 'West End', 'Blue'),
    ('S10', 'Greenfield', 'Blue'),
    
    ('S11', 'North Station', 'Red'),
    ('S12', 'South End', 'Red'),
    ('S13', 'Metro Heights', 'Red'),
    ('S14', 'Riverbank', 'Red'),
    
    ('S15', 'Pink Plaza', 'Pink'),
    ('S16', 'Sunset Avenue', 'Pink'),
    ('S17', 'Hilltop', 'Pink'),
    ('S18', 'Valley View', 'Pink'),
    
    -- Additional Shared Stations
    ('S19', 'Old Town', 'Blue'),
    ('S19', 'Old Town', 'Pink'),
    ('S20', 'Westgate', 'Red'),
    ('S20', 'Westgate', 'Blue'),
    ('S21', 'Grand Junction', 'Pink'),
    ('S21', 'Grand Junction', 'Red');

INSERT INTO metro_route (route_id, route_name, line_color, stations) VALUES
    -- Normal Direction Routes
    ('R1', 'Blue Line Route', 'Blue', 'S1 S2 S4 S5 S7 S8 S9 S10 S19 S20'),
    ('R2', 'Red Line Route', 'Red', 'S1 S3 S4 S6 S11 S12 S13 S14 S20 S21'),
    ('R3', 'Pink Line Route', 'Pink', 'S2 S3 S5 S6 S15 S16 S17 S18 S19 S21'),

    -- Reverse Direction Routes
    ('R4', 'Blue Line Reverse', 'Blue', 'S20 S19 S10 S9 S8 S7 S5 S4 S2 S1'),
    ('R5', 'Red Line Reverse', 'Red', 'S21 S20 S14 S13 S12 S11 S6 S4 S3 S1'),
    ('R6', 'Pink Line Reverse', 'Pink', 'S21 S19 S18 S17 S16 S15 S6 S5 S3 S2');






-- Insert Metro Data
INSERT INTO metro (metro_id, metro_name, line_color) VALUES
    -- Blue Metros
    ('M1', 'Blue Metro 1', 'Blue'),
    ('M2', 'Blue Metro 2', 'Blue'),
    ('M3', 'Blue Metro 3', 'Blue'),
    ('M4', 'Blue Metro 4', 'Blue'),
    ('M5', 'Blue Metro 5', 'Blue'),
    ('M6', 'Blue Metro 6', 'Blue'),
    ('M7', 'Blue Metro 7', 'Blue'),
    ('M8', 'Blue Metro 8', 'Blue'),
    ('M9', 'Blue Metro 9', 'Blue'),
    ('M10', 'Blue Metro 10', 'Blue'),

    -- Red Metros
    ('M11', 'Red Metro 1', 'Red'),
    ('M12', 'Red Metro 2', 'Red'),
    ('M13', 'Red Metro 3', 'Red'),
    ('M14', 'Red Metro 4', 'Red'),
    ('M15', 'Red Metro 5', 'Red'),
    ('M16', 'Red Metro 6', 'Red'),
    ('M17', 'Red Metro 7', 'Red'),
    ('M18', 'Red Metro 8', 'Red'),
    ('M19', 'Red Metro 9', 'Red'),
    ('M20', 'Red Metro 10', 'Red'),

    -- Pink Metros
    ('M21', 'Pink Metro 1', 'Pink'),
    ('M22', 'Pink Metro 2', 'Pink'),
    ('M23', 'Pink Metro 3', 'Pink'),
    ('M24', 'Pink Metro 4', 'Pink'),
    ('M25', 'Pink Metro 5', 'Pink'),
    ('M26', 'Pink Metro 6', 'Pink'),
    ('M27', 'Pink Metro 7', 'Pink'),
    ('M28', 'Pink Metro 8', 'Pink'),
    ('M29', 'Pink Metro 9', 'Pink'),
    ('M30', 'Pink Metro 10', 'Pink');

-- Blue Line Route (R1)
INSERT INTO metro_schedule (route_id, st_code, arrival_time, departure_time, platform) VALUES
    ('R1', 'S1', '08:00:00', '08:02:00', 1),  
    ('R1', 'S2', '08:10:00', '08:12:00', 2),  
    ('R1', 'S4', '08:20:00', '08:22:00', 3),  
    ('R1', 'S5', '08:30:00', '08:32:00', 1),  
    ('R1', 'S7', '08:40:00', '08:42:00', 2),  
    ('R1', 'S8', '08:50:00', '08:52:00', 1),  
    ('R1', 'S9', '09:00:00', '09:02:00', 3),  
    ('R1', 'S10', '09:10:00', '09:12:00', 2),  
    ('R1', 'S19', '09:20:00', '09:22:00', 1),  
    ('R1', 'S20', '09:30:00', '09:32:00', 2);

-- Red Line Route (R2)
INSERT INTO metro_schedule (route_id, st_code, arrival_time, departure_time, platform) VALUES
    ('R2', 'S1', '08:05:00', '08:07:00', 1),  
    ('R2', 'S3', '08:15:00', '08:17:00', 2),  
    ('R2', 'S4', '08:25:00', '08:27:00', 3),  
    ('R2', 'S6', '08:35:00', '08:37:00', 1),  
    ('R2', 'S11', '08:45:00', '08:47:00', 2),  
    ('R2', 'S12', '08:55:00', '08:57:00', 1),  
    ('R2', 'S13', '09:05:00', '09:07:00', 3),  
    ('R2', 'S14', '09:15:00', '09:17:00', 2),  
    ('R2', 'S20', '09:25:00', '09:27:00', 1),  
    ('R2', 'S21', '09:35:00', '09:37:00', 2);

-- Pink Line Route (R3)
INSERT INTO metro_schedule (route_id, st_code, arrival_time, departure_time, platform) VALUES
    ('R3', 'S2', '08:10:00', '08:12:00', 1),  
    ('R3', 'S3', '08:20:00', '08:22:00', 2),  
    ('R3', 'S5', '08:30:00', '08:32:00', 3),  
    ('R3', 'S6', '08:40:00', '08:42:00', 1),  
    ('R3', 'S15', '08:50:00', '08:52:00', 2),  
    ('R3', 'S16', '09:00:00', '09:02:00', 1),  
    ('R3', 'S17', '09:10:00', '09:12:00', 3),  
    ('R3', 'S18', '09:20:00', '09:22:00', 2),  
    ('R3', 'S19', '09:30:00', '09:32:00', 1),  
    ('R3', 'S21', '09:40:00', '09:42:00', 2);

-- Similarly, add schedule data for R4 (Blue Reverse), R5 (Red Reverse), and R6 (Pink Reverse) following the same logic.

-- Insert Metro Stops for Blue Line
INSERT INTO metro_stop (route_id, st_code, stop_order, platform) VALUES
    ('R1', 'S1', 1, 1),
    ('R1', 'S2', 2, 2),
    ('R1', 'S4', 3, 3),
    ('R1', 'S5', 4, 2),
    ('R1', 'S7', 5, 1),
    ('R1', 'S8', 6, 2),
    ('R1', 'S9', 7, 3),
    ('R1', 'S10', 8, 1),
    ('R1', 'S19', 9, 2),
    ('R1', 'S20', 10, 3),

    ('R4', 'S20', 1, 3),
    ('R4', 'S19', 2, 2),
    ('R4', 'S10', 3, 1),
    ('R4', 'S9', 4, 3),
    ('R4', 'S8', 5, 2),
    ('R4', 'S7', 6, 1),
    ('R4', 'S5', 7, 2),
    ('R4', 'S4', 8, 3),
    ('R4', 'S2', 9, 2),
    ('R4', 'S1', 10, 1);

-- Insert Metro Stops for Red Line
INSERT INTO metro_stop (route_id, st_code, stop_order, platform) VALUES
    ('R2', 'S1', 1, 1),
    ('R2', 'S3', 2, 2),
    ('R2', 'S4', 3, 3),
    ('R2', 'S6', 4, 1),
    ('R2', 'S11', 5, 2),
    ('R2', 'S12', 6, 3),
    ('R2', 'S13', 7, 1),
    ('R2', 'S14', 8, 2),
    ('R2', 'S20', 9, 3),
    ('R2', 'S21', 10, 1),

    ('R5', 'S21', 1, 1),
    ('R5', 'S20', 2, 3),
    ('R5', 'S14', 3, 2),
    ('R5', 'S13', 4, 1),
    ('R5', 'S12', 5, 3),
    ('R5', 'S11', 6, 2),
    ('R5', 'S6', 7, 1),
    ('R5', 'S4', 8, 3),
    ('R5', 'S3', 9, 2),
    ('R5', 'S1', 10, 1);

-- Insert Metro Stops for Pink Line
INSERT INTO metro_stop (route_id, st_code, stop_order, platform) VALUES
    ('R3', 'S2', 1, 2),
    ('R3', 'S3', 2, 3),
    ('R3', 'S5', 3, 1),
    ('R3', 'S6', 4, 2),
    ('R3', 'S15', 5, 3),
    ('R3', 'S16', 6, 1),
    ('R3', 'S17', 7, 2),
    ('R3', 'S18', 8, 3),
    ('R3', 'S19', 9, 1),
    ('R3', 'S21', 10, 2),

    ('R6', 'S21', 1, 2),
    ('R6', 'S19', 2, 1),
    ('R6', 'S18', 3, 3),
    ('R6', 'S17', 4, 2),
    ('R6', 'S16', 5, 1),
    ('R6', 'S15', 6, 3),
    ('R6', 'S6', 7, 2),
    ('R6', 'S5', 8, 1),
    ('R6', 'S3', 9, 3),
    ('R6', 'S2', 10, 2);

-- Create Trigger to Calculate Fare
DELIMITER //
CREATE TRIGGER calculate_fare
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
DELIMITER //
CREATE TRIGGER calculate_fare
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
    DECLARE distance1 INT DEFAULT 0;
    DECLARE distance2 INT DEFAULT 0;
    DECLARE transfer_station VARCHAR(10);

    -- Check if entry and exit stations are on the same line
    SELECT COUNT(*) INTO @same_line
    FROM metro_stop m1
    JOIN metro_stop m2 ON m1.route_id = m2.route_id
    WHERE m1.st_code = NEW.entry_station AND m2.st_code = NEW.exit_station
    LIMIT 1;

    IF @same_line > 0 THEN
        -- Direct route, calculate distance normally
        SELECT ABS(m1.stop_order - m2.stop_order) INTO distance1
        FROM metro_stop m1
        JOIN metro_stop m2 ON m1.route_id = m2.route_id
        WHERE m1.st_code = NEW.entry_station AND m2.st_code = NEW.exit_station
        LIMIT 1;

        SET NEW.fare = 15 + (GREATEST(distance1 - 1, 0) * 5);
    ELSE
        -- Need to transfer, find the nearest transfer station
        SELECT st_code INTO transfer_station
        FROM station_transfer
        WHERE from_line = (SELECT line_color FROM station WHERE st_code = NEW.entry_station LIMIT 1)
          AND to_line = (SELECT line_color FROM station WHERE st_code = NEW.exit_station LIMIT 1)
        LIMIT 1;

        IF transfer_station IS NOT NULL THEN
            -- Calculate fare for first leg (entry_station to transfer_station)
            SELECT ABS(m1.stop_order - m2.stop_order) INTO distance1
            FROM metro_stop m1
            JOIN metro_stop m2 ON m1.route_id = m2.route_id
            WHERE m1.st_code = NEW.entry_station AND m2.st_code = transfer_station
            LIMIT 1;

            -- Calculate fare for second leg (transfer_station to exit_station)
            SELECT ABS(m1.stop_order - m2.stop_order) INTO distance2
            FROM metro_stop m1
            JOIN metro_stop m2 ON m1.route_id = m2.route_id
            WHERE m1.st_code = transfer_station AND m2.st_code = NEW.exit_station
            LIMIT 1;

            -- Total fare = sum of both legs
            SET NEW.fare = (15 + (GREATEST(distance1 - 1, 0) * 5)) + (15 + (GREATEST(distance2 - 1, 0) * 5));
        ELSE
            -- No valid route found, set fare to 0
            SET NEW.fare = 0;
        END IF;
    END IF;
END;
//
DELIMITER ;



-- Insert Tickets (Auto-calculate fare)
INSERT INTO ticket (pnr, username, entry_station, exit_station, booking_details)
VALUES ('T002', 'alice123', 'S9', 'S1', 'Distance-based fare');

-- Show Database and Tables
SHOW DATABASES;
USE metro_management;
SHOW TABLES;