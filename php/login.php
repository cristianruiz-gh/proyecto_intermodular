<?php
require_once __DIR__ . '/auth.php';

if (isset($_GET['logout'])) {
    logout_user();
    header('Location: /login.php');
    exit;
}

if (is_logged_in()) {
    header('Location: /index.php');
    exit;
}

$error = '';
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $username = (string) ($_POST['username'] ?? '');
    $password = (string) ($_POST['password'] ?? '');

    if (login_user($username, $password)) {
        header('Location: /index.php');
        exit;
    }

    $error = 'Usuario o contraseña incorrectos';
}
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Iniciar sesión</title>
  <style><?= app_css() ?></style>
</head>
<body>
  <main class="card">
    <h1>Iniciar sesión</h1>
    <p>Accede con tu usuario y contraseña.</p>

    <form method="post" action="/login.php">
      <label for="username">Usuario</label>
      <input id="username" type="text" name="username" required>

      <label for="password">Contraseña</label>
      <input id="password" type="password" name="password" required>

      <button class="btn" type="submit">Entrar</button>
    </form>

    <?php if ($error !== ''): ?>
      <div class="error"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></div>
    <?php endif; ?>
  </main>
</body>
</html>
