<?php

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function is_logged_in(): bool
{
    return !empty($_SESSION['logged_in']);
}

function login_user(string $username, string $password): bool
{
    $validUser = trim((string) (getenv('PHP_AUTH_USER') ?: ''));
    $validPass = trim((string) (getenv('PHP_AUTH_PASSWORD') ?: ''));

    if (trim($username) !== $validUser || trim($password) !== $validPass) {
        return false;
    }

    $_SESSION['logged_in'] = true;
    $_SESSION['username'] = trim($username);
    return true;
}

function logout_user(): void
{
    $_SESSION = [];

    if (session_status() === PHP_SESSION_ACTIVE) {
        session_destroy();
    }
}

function app_css(): string
{
    return <<<CSS
    :root {
      --bg: #f4f7fb;
      --card: #ffffff;
      --text: #1f2937;
      --muted: #6b7280;
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --danger: #dc2626;
      --border: #e5e7eb;
      --shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, Helvetica, sans-serif;
      background: linear-gradient(160deg, #eef2ff, var(--bg));
      color: var(--text);
      display: grid;
      place-items: center;
      padding: 20px;
    }

    .card {
      width: 100%;
      max-width: 420px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      box-shadow: var(--shadow);
      padding: 24px;
    }

    h1 {
      margin: 0 0 12px;
      font-size: 1.5rem;
    }

    p {
      margin: 0 0 14px;
      color: var(--muted);
    }

    label {
      display: block;
      margin-bottom: 6px;
      font-weight: 600;
      color: var(--text);
    }

    input {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid var(--border);
      border-radius: 8px;
      margin-bottom: 14px;
      outline: none;
    }

    input:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }

    .btn {
      display: inline-block;
      width: 100%;
      border: 0;
      border-radius: 8px;
      padding: 11px 14px;
      font-weight: 700;
      cursor: pointer;
      color: #fff;
      background: var(--primary);
      text-decoration: none;
      text-align: center;
    }

    .btn:hover { background: var(--primary-hover); }

    .error {
      margin-top: 12px;
      color: var(--danger);
      font-size: 0.95rem;
    }

    .actions {
      margin-top: 16px;
      display: flex;
      gap: 10px;
    }
    CSS;
}

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
if ($path !== '/login.php' && !is_logged_in()) {
    header('Location: /login.php');
    exit;
}
