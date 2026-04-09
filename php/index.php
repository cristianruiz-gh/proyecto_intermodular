<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
start_secure_session();
$username = (string) ($_SESSION['username'] ?? 'usuario');
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Zona privada</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; }
    a { color: #1976d2; text-decoration: none; font-weight: 600; }
  </style>
</head>
<body>
  <h1>Zona privada</h1>
  <p>Has iniciado sesión como <strong><?= htmlspecialchars($username, ENT_QUOTES, 'UTF-8') ?></strong>.</p>
  <p><a href="/logout.php">Cerrar sesión</a></p>
</body>
</html>
