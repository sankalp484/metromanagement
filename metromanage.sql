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
                            platform INT NOT NULL,
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
                        fare INT DEFAULT 0 NOT NULL,
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

-- User Table
CREATE TABLE user (
                      user_id VARCHAR(20) PRIMARY KEY,
                      full_name VARCHAR(50) NOT NULL,
                      email VARCHAR(100) UNIQUE NOT NULL,
                      phone VARCHAR(15) UNIQUE NOT NULL
);

-- Passenger Table
CREATE TABLE passenger (
                           passenger_id INT PRIMARY KEY AUTO_INCREMENT,
                           user_id VARCHAR(20) NOT NULL,
                           pnr VARCHAR(10) NOT NULL,
                           FOREIGN KEY (user_id) REFERENCES user(user_id),
                           FOREIGN KEY (pnr) REFERENCES ticket(pnr)
);

-- Station Transfer Table
CREATE TABLE station_transfer (
                                  st_code VARCHAR(10),
                                  from_line ENUM('Blue', 'Pink', 'Red'),
                                  to_line ENUM('Blue', 'Pink', 'Red'),
                                  PRIMARY KEY (st_code, from_line, to_line),
                                  FOREIGN KEY (st_code) REFERENCES station(st_code)
);

-- Credentials Table
CREATE TABLE credentials (
                             user_id VARCHAR(20) PRIMARY KEY,
                             passcode VARCHAR(30) NOT NULL,
                             FOREIGN KEY (user_id) REFERENCES user(user_id),
                             CHECK (LENGTH(passcode) > 5)
);
