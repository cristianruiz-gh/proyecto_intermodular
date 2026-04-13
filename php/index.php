<?php
require_once __DIR__ . '/auth.php';
$username = (string) ($_SESSION['username'] ?? 'usuario');
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Zona privada</title>
  <style><?= app_css() ?></style>
</head>
<body>
  <main class="card">
    <h1>Zona privada</h1>
    <p>Bienvenido, <strong><?= htmlspecialchars($username, ENT_QUOTES, 'UTF-8') ?></strong>.</p>

    <div class="actions">
      <a class="btn" href="/login.php?logout=1">Cerrar sesión</a>
    </div>
  </main>
</body>
</html>
