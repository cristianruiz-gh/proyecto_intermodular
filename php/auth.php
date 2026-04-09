<?php
declare(strict_types=1);

function start_secure_session(): void
{
    if (session_status() === PHP_SESSION_NONE) {
        session_set_cookie_params([
            'lifetime' => 0,
            'path' => '/',
            'httponly' => true,
            'secure' => false,
            'samesite' => 'Lax',
        ]);
        session_start();
    }
}

function auth_config(): array
{
    $user = trim((string) (getenv('PHP_AUTH_USER') ?: ''));
    $password = trim((string) (getenv('PHP_AUTH_PASSWORD') ?: ''));

    return [
        'user' => $user,
        'password' => $password,
    ];
}

function is_authenticated(): bool
{
    start_secure_session();
    return !empty($_SESSION['authenticated']) && $_SESSION['authenticated'] === true;
}

function attempt_login(string $username, string $password): bool
{
    start_secure_session();
    $config = auth_config();

    $username = trim($username);
    $password = trim($password);

    $userOk = hash_equals($config['user'], $username);
    $passOk = hash_equals($config['password'], $password);

    if ($userOk && $passOk) {
        $_SESSION['authenticated'] = true;
        $_SESSION['username'] = $username;
        session_regenerate_id(true);
        return true;
    }

    return false;
}

function require_authentication(): void
{
    if (is_authenticated()) {
        return;
    }

        $currentPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $whitelist = ['/login.php'];

    if (in_array($currentPath, $whitelist, true)) {

        return;
    }

    header('Location: /login.php');
    exit;
}

function logout_user(): void
{
    start_secure_session();

    $_SESSION = [];

    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            '',
            time() - 42000,
            $params['path'],
            $params['domain'] ?? '',
            (bool) ($params['secure'] ?? false),
            (bool) ($params['httponly'] ?? true)
        );
    }

    session_destroy();
}
