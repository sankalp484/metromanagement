from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector

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

@app.route('/timings')
def view_timings():
    return "<h2>Train Timings Page (coming soon)</h2>"

@app.route('/book/<user_id>')
def book_train(user_id):
    return f"<h2>Book Ticket for {user_id} (coming soon)</h2>"

@app.route('/admin_dashboard')
def admin_dashboard():
    return "<h2>Admin Dashboard (coming soon)</h2>"

if __name__ == '__main__':
    app.run(debug=True)