#!/usr/bin/env python3
import os
import sqlite3
from flask import Flask, request, render_template_string, redirect, session
import subprocess

app = Flask(__name__)
app.secret_key = 'super_secret_key_123'  # Уязвимость: слабый секретный ключ

# Инициализация базы данных (уязвимой)
def init_db():
    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS users 
                     (id INTEGER PRIMARY KEY, username TEXT, password TEXT)''')
    cursor.execute("INSERT OR IGNORE INTO users VALUES (1, 'admin', 'admin123')")
    cursor.execute("INSERT OR IGNORE INTO users VALUES (2, 'user', 'password')")
    conn.commit()
    conn.close()

@app.route('/')
def home():
    return '''
    <h1>Vulnerable Web Application</h1>
    <p>This is a deliberately vulnerable web application for cybersecurity training.</p>
    <ul>
        <li><a href="/login">Login</a></li>
        <li><a href="/search">Search</a></li>
        <li><a href="/command">Command Execution</a></li>
        <li><a href="/file">File Operation</a></li>
    </ul>
    '''

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        # SQL Injection уязвимость
        conn = sqlite3.connect('app.db')
        cursor = conn.cursor()
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
        result = cursor.execute(query).fetchone()
        conn.close()

        if result:
            session['user'] = username
            return f"Welcome {username}! <a href='/'>Home</a>"
        else:
            return "Invalid credentials! <a href='/login'>Try again</a>"

    return '''
    <form method="POST">
        Username: <input type="text" name="username"><br>
        Password: <input type="password" name="password"><br>
        <input type="submit" value="Login">
    </form>
    <p>Try: admin/admin123 or use SQL injection</p>
    '''

@app.route('/search')
def search():
    query = request.args.get('q', '')
    if query:
        # XSS уязвимость
        return f"Search results for: {query} <br><a href='/'>Home</a>"
    return '''
    <form>
        Search: <input type="text" name="q">
        <input type="submit" value="Search">
    </form>
    <p>Try: &lt;script&gt;alert('XSS')&lt;/script&gt;</p>
    '''

@app.route('/command', methods=['GET', 'POST'])
def command():
    if request.method == 'POST':
        cmd = request.form.get('cmd', '')
        if cmd:
            try:
                # Command Injection уязвимость
                result = subprocess.check_output(cmd, shell=True, text=True)
                return f"<pre>{result}</pre><a href='/command'>Back</a>"
            except Exception as e:
                return f"Error: {str(e)} <a href='/command'>Back</a>"

    return '''
    <form method="POST">
        Command: <input type="text" name="cmd" placeholder="ls -la">
        <input type="submit" value="Execute">
    </form>
    <p>Try: ls -la, cat /etc/passwd, id</p>
    '''

@app.route('/file')
def file_operation():
    filename = request.args.get('file', '')
    if filename:
        try:
            # Directory Traversal уязвимость
            with open(filename, 'r') as f:
                content = f.read()
            return f"<pre>{content}</pre><a href='/file'>Back</a>"
        except Exception as e:
            return f"Error: {str(e)} <a href='/file'>Back</a>"

    return '''
    <form>
        File: <input type="text" name="file" placeholder="app.py">
        <input type="submit" value="Read File">
    </form>
    <p>Try: app.py, /etc/passwd, ../../../etc/hosts</p>
    '''

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)