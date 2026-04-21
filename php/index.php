<?php
$mensajeError = $_SESSION['mensaje_error'] ?? null;
$mensajes = $_SESSION['mensajes'] ?? null;
unset($_SESSION['mensaje_error'], $_SESSION['mensajes']);
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulario de Cliente</title>
    <link rel="stylesheet" href="styles.css">
    <script src="script.js" defer></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.3.0/papaparse.min.js"></script>
</head>
<body>
    <div class="card card-wide">
        <h2>Formulario de Clientes</h2>

        <?php if (!empty($mensajeError)): ?>
            <div class='error'><?php echo $mensajeError; ?></div>
        <?php endif; ?>

        <?php if (!empty($mensajes)): ?>
            <?php foreach ($mensajes as $m): ?>
                <?php echo $m; ?>
            <?php endforeach; ?>
        <?php endif; ?>

        <div class="file-upload">
            <input type="file" id="fileInput" accept=".json,.txt,.csv">
            <label for="fileInput">🗂️ Seleccionar archivo</label>
            <span id="fileName">Ningún archivo seleccionado</span>
        </div>

        <form id="clientesForm" action="procesar.php" method="POST">
            <div id="clientesContainer">
                <div class="cliente-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Código Cliente:</label>
                            <input type="number" name="codcliente[]">
                        </div>
                        <div class="form-group">
                            <label>Nombre:</label>
                            <input type="text" name="nombre[]">
                        </div>
                        <div class="form-group">
                            <label>Apellidos:</label>
                            <input type="text" name="apellidos[]">
                        </div>
                        <div class="form-group">
                            <label>Tipo de Cliente:</label>
                            <select name="tipo_cliente[]">
                                <option value="Nuevo">Nuevo</option>
                                <option value="Recurrente">Recurrente</option>
                                <option value="VIP">VIP</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Fecha:</label>
                            <input type="date" name="fecha[]">
                        </div>
                        <div class="form-group">
                            <label>Código Producto:</label>
                            <input type="number" name="codproducto[]">
                        </div>
                        <div class="form-group">
                            <label>Código Producto de Cliente:</label>
                            <input type="number" name="codproducto_de_cliente[]">
                        </div>
                        <div class="form-group">
                            <label>Descripción:</label>
                            <textarea name="descripcion_atributo[]" rows="4"></textarea>
                        </div>
                    </div>
                    <div class="botones">
                        <button type="button" class="eliminar-btn">Eliminar</button>
                    </div>
                </div>
            </div>

            <div class="botones">
                <button type="button" class="añadir-btn">Añadir Cliente</button>
            </div>

            <input type="submit" value="Enviar" class="form-submit-btn">
        </form>
    </div>
</body>
</html>