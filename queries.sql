USE metro_management;


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

