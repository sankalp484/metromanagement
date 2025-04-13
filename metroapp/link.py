from flask import Flask, render_template, request, redirect, url_for, flash , session
import mysql.connector
import qrcode
import base64
import random
import string
from io import BytesIO
from datetime import date
import mysql.connector
from collections import deque
import json

app = Flask(__name__)
app.secret_key = 'your_secret_key'  # Needed for flashing messages

# Database connection
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        port=3306,
        user="root",
        password="sankalp2306",
        database="metro_management"
    )
def get_username(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT full_name FROM user WHERE user_id = %s", (user_id,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result[0] if result else None

# Generate a unique 10-char PNR
def generate_pnr():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
def get_station_name_code_map():
    # Simulating DB content with a dict
    stations = [
        ('S1', 'Central Square'),
        ('S2', 'Downtown'),
        ('S3', 'City Center'),
        ('S4', 'Tech Park'),
        ('S5', 'Airport'),
        ('S6', 'University'),
        ('S7', 'Sunset Avenue'),
        ('S8', 'North Station'),
        ('S9', 'West End')
    ]

    name_to_code = {name.lower(): code for code, name in stations}
    code_to_name = {code: name for code, name in stations}
    return name_to_code, code_to_name
def build_station_graph():
    routes = [
        ('R1', 'Blue', 'S1 S2 S3 S4'),
        ('R2', 'Pink', 'S5 S2 S6 S7'),
        ('R3', 'Red',  'S8 S6 S9 S3'),
        ('R4', 'Blue', 'S4 S3 S2 S1'),
        ('R5', 'Pink', 'S7 S6 S2 S5'),
        ('R6', 'Red',  'S3 S9 S6 S8')
    ]

    graph = {}
    for _, _, stations_str in routes:
        stations = stations_str.split()
        for i in range(len(stations) - 1):
            a, b = stations[i], stations[i+1]
            graph.setdefault(a, []).append(b)
            graph.setdefault(b, []).append(a)
    return graph
# Dummy fare calculator
def calculate_fare(entry_code, exit_code):
    if entry_code == exit_code:
        return 10  # Minimum fare

    graph = build_station_graph()
    visited = set()
    queue = deque([(entry_code, 0)])  # (station_code, hops)

    while queue:
        station, hops = queue.popleft()
        if station == exit_code:
            return max(10, hops * 10)  # ₹10 per hop

        visited.add(station)
        for neighbor in graph.get(station, []):
            if neighbor not in visited:
                queue.append((neighbor, hops + 1))

    return None  # Path not found
def get_route_path(entry_name, exit_name):
    name_to_code, code_to_name = get_station_name_code_map()

    entry = name_to_code.get(entry_name.lower())
    exit = name_to_code.get(exit_name.lower())

    if not entry or not exit:
        return []  # Invalid station name

    graph = build_station_graph()

    visited = set()
    queue = deque([(entry, [entry])])  # station, path till now

    while queue:
        station, path = queue.popleft()

        if station == exit:
            return [code_to_name[code] for code in path]

        visited.add(station)

        for neighbor in graph.get(station, []):
            if neighbor not in visited:
                queue.append((neighbor, path + [neighbor]))

    return []  # No path found

@app.route('/')
def home():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])

def login():
    if request.method == 'POST':
        user_id = request.form['user_id']
        passcode = request.form['passcode']

        conn = get_db_connection()
        cursor = conn.cursor()

        # Check admin login
        cursor.execute("SELECT * FROM admin WHERE user_name=%s AND passcode=%s", (user_id, passcode))
        admin = cursor.fetchone()

        if admin:
            flash('Admin login successful!', 'success')
            return redirect(url_for('admin_dashboard'))

        # Else check user login
        cursor.execute("SELECT * FROM credentials WHERE user_id=%s AND passcode=%s", (user_id, passcode))
        user = cursor.fetchone()

        cursor.close()
        conn.close()

        if user:
            session['user_id'] = user_id
            session['username'] = get_username(user_id)
            flash('User login successful!', 'success')
            return redirect(url_for('user_dashboard', user_id=user_id))
        else:
            flash('Invalid credentials.', 'danger')

    return render_template('login.html')


@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        user_id = request.form['user_id']
        full_name = request.form['full_name']
        email = request.form['email']
        phone = request.form['phone']
        passcode = request.form['passcode']

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("INSERT INTO user (user_id, full_name, email, phone) VALUES (%s, %s, %s, %s)",
                           (user_id, full_name, email, phone))
            cursor.execute("INSERT INTO credentials (user_id, passcode) VALUES (%s, %s)",
                           (user_id, passcode))
            conn.commit()
            flash('Signup successful! Please log in.', 'success')
            return redirect(url_for('login'))
        except mysql.connector.Error as err:
            flash(f'Error: {err.msg}', 'danger')
        finally:
            cursor.close()
            conn.close()

    return render_template('signup.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))
@app.route('/dashboard/<user_id>')
def user_dashboard(user_id):
    return render_template('user_dashboard.html', user_id=user_id)
from datetime import datetime, timedelta
@app.route('/schedule')
def view_schedule():
    metro_id = request.args.get('metro_id', '')
    station = request.args.get('station', '')
    direction = request.args.get('direction', '')
    arrival_time = request.args.get('arrival_time', '')  # single time input

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT 
            ms.metro_id,
            ms.route_id,
            s.st_name AS station_name,
            s.line_color,
            ms.arrival_time,
            ms.departure_time,
            ms.platform,
            ms.direction
        FROM 
            metro_schedule ms
        JOIN 
            station s ON ms.st_code = s.st_code
        WHERE 
            s.line_color = 'Blue'
    """

    params = []
    if metro_id:
        query += " AND ms.metro_id LIKE %s"
        params.append(f"%{metro_id}%")
    if station:
        query += " AND s.st_name LIKE %s"
        params.append(f"%{station}%")
    if direction:
        query += " AND ms.direction = %s"
        params.append(direction)
    if arrival_time:
        try:
            time_obj = datetime.strptime(arrival_time, '%H:%M')
            arrival_from = time_obj.time()
            arrival_to = (time_obj + timedelta(minutes=10)).time()
            query += " AND ms.arrival_time BETWEEN %s AND %s"
            params.extend([arrival_from, arrival_to])
        except ValueError:
            pass  # ignore invalid format

    query += """
        ORDER BY 
            ms.metro_id, 
            FIELD(ms.direction, 'Forward', 'Reverse'), 
            ms.arrival_time
    """

    cursor.execute(query, params)
    schedule = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('schedule.html', schedule=schedule)
@app.route('/view_routes', methods=['GET'])
def view_routes():
    source = request.args.get('source')
    destination = request.args.get('destination')

    conn = get_db_connection()
    cursor = conn.cursor()

    # Get all transfer stations (stations on more than one line)
    cursor.execute("""
        SELECT st_name
        FROM station
        GROUP BY st_name
        HAVING COUNT(DISTINCT line_color) > 1
    """)
    transfer_stations = [row[0] for row in cursor.fetchall()]

    route_info = ""
    error_message = ""
    full_path = []

    if source and destination:
        if source == destination:
            route_info = "You are already at your destination."
        else:
            # Get lines for source and destination
            cursor.execute("SELECT line_color FROM station WHERE st_name = %s", (source,))
            source_lines = set(row[0] for row in cursor.fetchall())

            cursor.execute("SELECT line_color FROM station WHERE st_name = %s", (destination,))
            dest_lines = set(row[0] for row in cursor.fetchall())

            # Check if source and destination are on the same line
            common_line = source_lines & dest_lines
            if common_line:
                line = common_line.pop()
                route_info = f"Take {line} line directly from {source} to {destination}."
                full_path = get_route_path(source, destination)

            else:
                # Try to find a valid transfer station
                transfer_found = False
                for transfer in transfer_stations:
                    cursor.execute("SELECT line_color FROM station WHERE st_name = %s", (transfer,))
                    transfer_lines = set(row[0] for row in cursor.fetchall())

                    first_leg = source_lines & transfer_lines
                    second_leg = dest_lines & transfer_lines

                    if first_leg and second_leg:
                        line1 = first_leg.pop()
                        line2 = second_leg.pop()
                        route_info = (
                            f"Take {line1} line from {source} to {transfer}, "
                            f"then transfer to {line2} line to reach {destination}."
                        )
                        full_path = get_route_path(source, destination)

                        transfer_found = True
                        break

                if not transfer_found:
                    error_message = "No route found with a single transfer."
        cursor.execute("""
                        SELECT ms1.metro_id, m.metro_name, ms1.st_code AS start_station, ms1.arrival_time AS start_time, 
                               ms2.st_code AS end_station, ms2.arrival_time AS end_time
                        FROM metro_schedule ms1
                        JOIN metro_schedule ms2 ON ms1.metro_id = ms2.metro_id
                        JOIN metro m ON ms1.metro_id = m.metro_id
                        WHERE ms1.st_code = (
                            SELECT st_code FROM station WHERE st_name = %s LIMIT 1
                        )
                        AND ms2.st_code = (
                            SELECT st_code FROM station WHERE st_name = %s LIMIT 1
                        )
                        AND ms1.arrival_time < ms2.arrival_time
                        ORDER BY ms1.arrival_time
                    """, (source, destination))
        metro_options = cursor.fetchall()

    conn.close()
    return render_template('view_routes.html', route_info=route_info, error_message=error_message, full_path=full_path,metro_options=metro_options)



@app.route('/book_ticket', methods=['GET', 'POST'])
def book_ticket():
    message = ""
    qr_code_img = None
    stage = request.form.get('stage') if request.method == 'POST' else None

    if request.method == 'POST':
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if stage == 'fare_check':
            entry_code = request.form['entry_station']  # Expecting station code like S1
            exit_code = request.form['exit_station']
            fare = calculate_fare(entry_code, exit_code)  # Make sure this handles station codes

            if fare is None:
                message = "Invalid station code selection."
                cursor.close()
                conn.close()
                return render_template('book_ticket.html', message=message)

            # Proceed to confirmation stage
            return render_template('book_ticket.html', fare=fare, entry=entry_code, exit=exit_code, stage='confirm')

        elif stage == 'confirm_payment':
            entry_code = request.form['entry_station']
            exit_code = request.form['exit_station']
            fare = calculate_fare(entry_code, exit_code)

            if fare is None:
                message = "Invalid station code selection."
                cursor.close()
                conn.close()
                return render_template('book_ticket.html', message=message)

            paid = int(request.form['paid_amount'])
            if paid != fare:
                message = "Incorrect fare amount entered."
                cursor.close()
                conn.close()
                return render_template('book_ticket.html', message=message)

            username = session.get('username')
            if not username:
                cursor.close()
                conn.close()
                return "User not logged in", 403
            full_name = get_username(username)
            pnr = generate_pnr()
            today = date.today()
            details = json.dumps({
                "username": username,
                "from": entry_code,
                "to": exit_code,
                "fare": fare
            })

            img = qrcode.make(details)
            buffer = BytesIO()
            img.save(buffer)
            qr_code_img = base64.b64encode(buffer.getvalue()).decode('utf-8')
            user_id = session.get('user_id')
            try:
                cursor.execute("""
                    INSERT INTO ticket (pnr, username, entry_station, exit_station, fare, booking_details, booking_date)
                    VALUES (%s, %s, %s, %s, %s,%s, %s)
                """, (pnr, username, entry_code, exit_code, fare, "Online-Net Banking", today))
                            # Add user to passenger table
                cursor.execute("""
                    INSERT INTO passenger (user_id, pnr)
                    VALUES (%s, %s)
                """, (user_id, pnr))

                conn.commit()
            except mysql.connector.Error as err:
                conn.rollback()
                message = f"Database error: {err.msg}"
                cursor.close()
                conn.close()
                return render_template('book_ticket.html', message=message)

            cursor.close()
            conn.close()
            message = "Ticket booked successfully!"
            return render_template('book_ticket.html', message=message, qr_code_img=qr_code_img,stage='done')

    return render_template('book_ticket.html', message=message)


@app.route('/view_history')
def view_history():
    # Check if user is logged in
    username = session.get('username')
    if not username:
        return "User not logged in", 403

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    query = """
        SELECT pnr, entry_station, exit_station, fare, booking_details, booking_date
        FROM ticket
        WHERE username = %s
        ORDER BY booking_date DESC
    """
    cursor.execute(query, (username,))
    result = cursor.fetchall()

    tickets = []
    for row in result:
        tickets.append({
            "pnr": row["pnr"],
            "entry_station": row["entry_station"],
            "exit_station": row["exit_station"],
            "fare": row["fare"],
            "booking_details": row["booking_details"],
            "date": row["booking_date"]
        })

    cursor.close()
    connection.close()

    return render_template('ticket_history.html', username=username, tickets=tickets)

@app.route('/admin_dashboard')
def admin_dashboard():
    return render_template('admin_dashboard.html')

@app.route('/admin/view_users')
def view_users():
    filter_type = request.args.get('filter', 'all')  # 'all' or 'no_passenger'

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Get users based on filter
    if filter_type == 'no_passenger':
        cursor.execute("""
            SELECT * FROM user
            WHERE user_id NOT IN (SELECT user_id FROM passenger)
        """)
    else:
        cursor.execute("SELECT * FROM user")
    users = cursor.fetchall()

    # Get all passenger user_ids to identify deletable ones
    cursor.execute("SELECT DISTINCT user_id FROM passenger")
    passenger_ids = {row['user_id'] for row in cursor.fetchall()}

    cursor.close()
    conn.close()

    return render_template('view_users.html', users=users, passenger_ids=passenger_ids, filter_type=filter_type)


@app.route('/admin/delete_user/<user_id>')
def delete_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Step 1: Get all PNRs associated with this user from the passenger table
        cursor.execute("SELECT pnr FROM passenger WHERE user_id = %s", (user_id,))
        pnrs = cursor.fetchall()

        # Step 2: Delete each related ticket (if any)
        for row in pnrs:
            pnr = row[0]  # or row['pnr'] if using dictionary=True
            cursor.execute("DELETE FROM ticket WHERE pnr = %s", (pnr,))

        # Step 3: Delete passenger record
        cursor.execute("DELETE FROM passenger WHERE user_id = %s", (user_id,))

        # Step 4: Delete credentials
        cursor.execute("DELETE FROM credentials WHERE user_id = %s", (user_id,))

        # Step 5: Delete user
        cursor.execute("DELETE FROM user WHERE user_id = %s", (user_id,))

        conn.commit()
        flash(f'User {user_id} deleted successfully.', 'success')

    except mysql.connector.Error as err:
        conn.rollback()
        flash(f'Error: {err.msg}', 'danger')

    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('view_users'))

@app.route('/admin/manage_schedule')
def manage_schedule():
    search = request.args.get('search', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
    SELECT ms.schedule_id, ms.metro_id, m.metro_name, ms.st_code, s.st_name,
           ms.arrival_time, ms.departure_time, ms.platform, ms.direction
    FROM metro_schedule ms
    JOIN metro m ON ms.metro_id = m.metro_id
    JOIN station s ON ms.st_code = s.st_code
    WHERE ms.metro_id LIKE %s
    ORDER BY ms.metro_id, ms.arrival_time
    """
    cursor.execute(query, ('%' + search + '%',))
    schedule = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('manage_schedule.html', schedule=schedule, search=search)
@app.route('/admin/update_schedule_batch', methods=['POST'])
def update_schedule_batch():
    schedule_id = request.form.get('update_id')

    if not schedule_id:
        flash("No schedule selected for update.", "warning")
        return redirect(url_for('manage_schedule'))

    arrival_time = request.form.get(f'arrival_time_{schedule_id}')
    departure_time = request.form.get(f'departure_time_{schedule_id}')
    platform = request.form.get(f'platform_{schedule_id}')

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE metro_schedule
            SET arrival_time = %s,
                departure_time = %s,
                platform = %s
            WHERE schedule_id = %s
        """, (arrival_time, departure_time, platform, schedule_id))
        conn.commit()
        flash("Schedule updated successfully.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('manage_schedule', search=request.args.get('search', '')))



@app.route('/admin/manage_metro', methods=['GET', 'POST'])
def manage_metros():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Add new metro
    if request.method == 'POST' and 'add_metro' in request.form:
        metro_id = request.form.get('metro_id').strip()
        metro_name = request.form.get('metro_name').strip()
        line_color = request.form.get('line_color')

        if metro_id and metro_name and line_color:
            try:
                cursor.execute(
                    "INSERT INTO metro (metro_id, metro_name, line_color) VALUES (%s, %s, %s)",
                    (metro_id, metro_name, line_color)
                )
                conn.commit()
                flash("Metro added successfully!", "success")
            except Exception as e:
                conn.rollback()
                flash(f"Error adding metro: {str(e)}", "danger")
        else:
            flash("All fields are required to add a metro.", "warning")

    # Delete metro (only if it has no schedules)
    elif request.method == 'POST' and 'delete_metro_id' in request.form:
        delete_metro_id = request.form.get('delete_metro_id')
        cursor.execute("SELECT COUNT(*) AS count FROM metro_schedule WHERE metro_id = %s", (delete_metro_id,))
        count = cursor.fetchone()['count']

        if count > 0:
            flash("Cannot delete metro with existing schedules.", "warning")
        else:
            try:
                cursor.execute("DELETE FROM metro WHERE metro_id = %s", (delete_metro_id,))
                conn.commit()
                flash("Metro deleted successfully!", "success")
            except Exception as e:
                conn.rollback()
                flash(f"Error deleting metro: {str(e)}", "danger")

    # Load all metros
    cursor.execute("SELECT * FROM metro ORDER BY metro_id")
    metros = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template("manage_metro.html", metros=metros)


@app.route('/admin/delete_metro/<metro_id>/<st_code>')
def delete_metro(metro_id, st_code):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM metro_schedule WHERE metro_id=%s AND st_code=%s", (metro_id, st_code))
    conn.commit()
    cursor.close()
    conn.close()
    flash("Metro schedule deleted!", "success")
    return redirect(url_for('manage_metros'))


@app.route('/admin/edit_metro/<metro_id>/<st_code>', methods=['GET', 'POST'])
def edit_metro(metro_id, st_code):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        arrival_time = request.form['arrival_time']
        departure_time = request.form['departure_time']
        platform = request.form['platform']
        direction = request.form['direction']

        cursor.execute("""
            UPDATE metro_schedule
            SET arrival_time=%s, departure_time=%s, platform=%s, direction=%s
            WHERE metro_id=%s AND st_code=%s
        """, (arrival_time, departure_time, platform, direction, metro_id, st_code))
        conn.commit()
        flash("Metro schedule updated!", "success")
        return redirect(url_for('manage_metros'))

    cursor.execute("SELECT * FROM metro_schedule WHERE metro_id=%s AND st_code=%s", (metro_id, st_code))
    data = cursor.fetchone()
    cursor.close()
    conn.close()
    return render_template('edit_metro.html', data=data)


@app.route('/admin/view_tickets')
def view_tickets():
    from_date = request.args.get('from_date')
    to_date = request.args.get('to_date')
    entry_station = request.args.get('entry_station')
    exit_station = request.args.get('exit_station')
    popular_only = request.args.get('popular_only')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT st_code FROM (
            SELECT entry_station AS st_code FROM ticket
            UNION ALL
            SELECT exit_station FROM ticket
        ) AS combined
        GROUP BY st_code
        ORDER BY COUNT(*) DESC
        LIMIT 1
    """)
    popular_station = cursor.fetchone()
    most_popular_code = popular_station['st_code'] if popular_station else None
    query = """
    SELECT t.pnr, t.username, s1.st_name AS entry_station_name, s2.st_name AS exit_station_name,
           t.fare, t.booking_details, t.booking_date
    FROM ticket t
    JOIN station s1 ON t.entry_station = s1.st_code
    JOIN station s2 ON t.exit_station = s2.st_code
    WHERE 1 = 1
    """

    params = []

    if from_date:
        query += " AND DATE(t.booking_date) >= %s"
        params.append(from_date)

    if to_date:
        query += " AND DATE(t.booking_date) <= %s"
        params.append(to_date)

    if entry_station:
        query += " AND t.entry_station = %s"
        params.append(entry_station)

    if exit_station:
        query += " AND t.exit_station = %s"
        params.append(exit_station)

    if popular_only == 'on' and most_popular_code:
        query += " AND (t.entry_station = %s OR t.exit_station = %s)"
        params.extend([most_popular_code, most_popular_code])

    query += " ORDER BY t.booking_date DESC"

    cursor.execute(query, params)
    tickets = cursor.fetchall()
    ticket_count = len(tickets)

    cursor.close()
    conn.close()

    return render_template("view_tickets.html", tickets=tickets ,ticket_count = ticket_count,most_popular_code=most_popular_code)
@app.route('/analysis', methods=['GET', 'POST'])
def analysis():
    selected_date = ''
    station_traffic_results = []
    total_line_changes = None

    if request.method == 'POST':
        selected_date = request.form.get('line_change_date', '')

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # Query 1: Station traffic (entry + exit) grouped by day of week
        query1 = """
        WITH station_traffic AS (
            SELECT 
                s.st_code,
                s.st_name,
                DAYOFWEEK(t.booking_date) AS day_of_week,
                COUNT(*) AS passenger_count
            FROM ticket t
            JOIN station s ON t.entry_station = s.st_code
            GROUP BY s.st_code, s.st_name, DAYOFWEEK(t.booking_date)
            
            UNION ALL
            
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
        """
        cursor.execute(query1)
        station_traffic_results = cursor.fetchall()

        # Query 2: Total line changes on selected date
        query2 = """
        SELECT SUM(
            CASE 
                WHEN s1.line_color <> s2.line_color THEN 1 
                ELSE 0 
            END
        ) AS total_line_changes
        FROM ticket t
        JOIN station s1 ON t.entry_station = s1.st_code
        JOIN station s2 ON t.exit_station = s2.st_code
        WHERE t.booking_date = %s;
        """
        cursor.execute(query2, (selected_date,))
        result = cursor.fetchone()
        total_line_changes = result['total_line_changes'] or 0

        cursor.close()
        conn.close()

    return render_template("analysis.html",
                           selected_date=selected_date,
                           station_traffic_results=station_traffic_results,
                           total_line_changes=total_line_changes)


if __name__ == '__main__':
    app.run(debug=True)