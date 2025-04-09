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

    conn.close()
    return render_template('view_routes.html', route_info=route_info, error_message=error_message, full_path=full_path)



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

            pnr = generate_pnr()
            today = date.today()
            details = f"{username}|From:{entry_code}|To:{exit_code}|Fare:₹{fare}"

            img = qrcode.make(details)
            buffer = BytesIO()
            img.save(buffer)
            qr_code_img = base64.b64encode(buffer.getvalue()).decode('utf-8')

            try:
                cursor.execute("""
                    INSERT INTO ticket (pnr, username, entry_station, exit_station, fare, booking_details, booking_date)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (pnr, username, entry_code, exit_code, 0, details, today))
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
            return render_template('book_ticket.html', message=message, qr_code_img=qr_code_img, stage='done')

    return render_template('book_ticket.html', message=message)


@app.route('/view_history/<user_id>')
def view_history(user_id):
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    query = """
        SELECT pnr, entry_station, exit_station, fare, booking_details, booking_date
        FROM ticket
        WHERE username = %s
        ORDER BY booking_date DESC
    """
    cursor.execute(query, (user_id,))
    result = cursor.fetchall()

    # Convert into format expected by template
    tickets = []
    for row in result:
        # Optional: parse booking_details for time/train/seat if needed
        booking_details = row['booking_details']
        parsed = booking_details.split(',') if booking_details else ['-', '-', '-']
        train_number = parsed[0] if len(parsed) > 0 else '-'
        time = parsed[1] if len(parsed) > 1 else '-'
        seat_number = parsed[2] if len(parsed) > 2 else '-'

        tickets.append({
            "pnr": row["pnr"],
            "entry_station": row["entry_station"],
            "exit_station": row["exit_station"],
            "date": row["booking_date"],
            "train_number": train_number,
            "time": time,
            "seat_number": seat_number
        })

    cursor.close()
    connection.close()

    return render_template('ticket_history.html', user_id=user_id, tickets=tickets)

@app.route('/admin_dashboard')
def admin_dashboard():
    return "<h2>Admin Dashboard (coming soon)</h2>"

if __name__ == '__main__':
    app.run(debug=True)