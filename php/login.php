<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';

start_secure_session();

if (is_authenticated()) {
    header('Location: /index.php');
    exit;
}

$error = '';

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $username = trim((string) ($_POST['username'] ?? ''));
    $password = trim((string) ($_POST['password'] ?? ''));

    if (attempt_login($username, $password)) {
        header('Location: /index.php');
        exit;
    }

    $error = 'Usuario o contraseña incorrectos.';
}
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f4f6f8; margin: 0; }
    .wrap { max-width: 360px; margin: 8vh auto; background: #fff; border-radius: 8px; box-shadow: 0 8px 24px rgba(0,0,0,.08); padding: 24px; }
    h1 { font-size: 1.25rem; margin-top: 0; }
    label { display:block; margin:.75rem 0 .35rem; font-weight: 600; }
    input { width:100%; padding:.65rem; border:1px solid #cfd8dc; border-radius:6px; box-sizing:border-box; }
    button { width:100%; margin-top:1rem; padding:.7rem; border:0; border-radius:6px; background:#1976d2; color:#fff; font-weight:700; cursor:pointer; }
    .error { margin-top:.75rem; color:#b00020; font-size:.92rem; }
  </style>
</head>
<body>
  <main class="wrap">
    <h1>Acceso privado</h1>
    <form method="post" action="/login.php">
      <label for="username">Usuario</label>
      <input id="username" name="username" type="text" autocomplete="username" required>

      <label for="password">Contraseña</label>
      <input id="password" name="password" type="password" autocomplete="current-password" required>

      <button type="submit">Entrar</button>
      <?php if ($error !== ''): ?>
        <p class="error"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></p>
      <?php endif; ?>
    </form>
  </main>
</body>
</html>
