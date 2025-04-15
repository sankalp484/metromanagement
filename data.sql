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

INSERT INTO admin (user_name, passcode) VALUES ('admin1', 'secure123');

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
