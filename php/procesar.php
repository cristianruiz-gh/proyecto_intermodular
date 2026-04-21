<?php
$servername = "172.26.203.60";
$username = "root";
$password = "Crylam2526+";
$dbname = "crylam_db";

function conectarDB() {
    global $servername, $username, $password, $dbname;
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        return null;
    }
    return $conn;
}

function validarFecha($fecha) {
    $fecha_formato = DateTime::createFromFormat('Y-m-d', $fecha);
    return $fecha_formato && $fecha_formato->format('Y-m-d') === $fecha;
}

function productoExiste($conn, $codproducto) {
    $stmt = $conn->prepare("SELECT codproducto FROM catalogo_de_productos WHERE codproducto = ?");
    $stmt->bind_param("s", $codproducto);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->num_rows > 0;
}

function clienteExiste($conn, $codcliente) {
    $stmt = $conn->prepare("SELECT codcliente FROM cabecera_de_clientes WHERE codcliente = ?");
    $stmt->bind_param("s", $codcliente);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->num_rows > 0;
}

function detalleProductoExiste($conn, $codproducto_de_cliente) {
    $stmt = $conn->prepare("SELECT codproducto_de_cliente FROM detalle_de_producto WHERE codproducto_de_cliente = ?");
    $stmt->bind_param("s", $codproducto_de_cliente);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->num_rows > 0;
}

function detalleClienteExiste($conn, $codcliente, $codproducto_de_cliente) {
    $stmt = $conn->prepare("SELECT codcliente, codproducto_de_cliente FROM detalle_de_cliente WHERE codcliente = ? AND codproducto_de_cliente = ?");
    $stmt->bind_param("ss", $codcliente, $codproducto_de_cliente);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->num_rows > 0;
}

function insertarCliente($conn, $datos) {
    $sql = "INSERT INTO cabecera_de_clientes
           (codcliente, nombre_cliente, apellidos_cliente, tipo_cliente, fecha)
           VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param(
        "sssss",
        $datos['codcliente'],
        $datos['nombre'],
        $datos['apellidos'],
        $datos['tipo_cliente'],
        $datos['fecha']
    );
    return $stmt->execute();
}

function insertarDetalleCliente($conn, $datos) {
    $sql = "INSERT INTO detalle_de_cliente
           (codcliente, codproducto_de_cliente, descripcion_atributo, fecha)
           VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param(
        "ssss",
        $datos['codcliente'],
        $datos['codproducto_de_cliente'],
        $datos['descripcion'],
        $datos['fecha']
    );
    return $stmt->execute();
}

function insertarDetalleProducto($conn, $datos) {
    $sql = "INSERT INTO detalle_de_producto
           (codproducto_de_cliente, codcliente, codproducto, descripcion_atributo, fecha)
           VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param(
        "sssss",
        $datos['codproducto_de_cliente'],
        $datos['codcliente'],
        $datos['codproducto'],
        $datos['descripcion'],
        $datos['fecha']
    );
    return $stmt->execute();
}

function insertarRegistro($conn, $datos, $observaciones, $tiempo) {
    $sql = "INSERT INTO registros (fecha, registro, observaciones, tiempo)
            VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param(
        "ssss",
        $datos['fecha'],
        $datos['registro'],
        $observaciones,
        $tiempo
    );
    return $stmt->execute();
}

session_start();
$mensajes = [];

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    $_SESSION['mensaje_error'] = "Método no permitido. Use POST.";
    header("Location: index.php");
    exit;
}

$codcliente = $_POST['codcliente'] ?? [];
$nombre = $_POST['nombre'] ?? [];
$apellidos = $_POST['apellidos'] ?? [];
$tipo_cliente = $_POST['tipo_cliente'] ?? [];
$fecha = $_POST['fecha'] ?? [];
$codproducto = $_POST['codproducto'] ?? [];
$codproducto_de_cliente = $_POST['codproducto_de_cliente'] ?? [];
$descripcion = $_POST['descripcion_atributo'] ?? [];

$conn = conectarDB();

if ($conn === null) {
    $_SESSION['mensaje_error'] = "Error: No se pudo conectar a la base de datos.";
    header("Location: index.php");
    exit;
}

$numClientes = count($codcliente);

for ($i = 0; $i < $numClientes; $i++) {
    $inicio = microtime(true);

    $codcliente_i = trim($codcliente[$i]);
    $nombre_i = trim($nombre[$i]);
    $apellidos_i = trim($apellidos[$i]);
    $tipo_i = trim($tipo_cliente[$i]);
    $fecha_i = trim($fecha[$i]);
    $producto_i = trim($codproducto[$i]);
    $producto_cli = trim($codproducto_de_cliente[$i]);
    $desc_i = $descripcion[$i] ?? null;
    $insertado = false;
    $motivo = "";

    if ($codcliente_i === "") {
        $motivo = "Código de cliente vacío";
    } elseif ($nombre_i === "") {
        $motivo = "Nombre vacío";
    } elseif (!validarFecha($fecha_i)) {
        $motivo = "Fecha inválida";
    } elseif ($producto_i === "") {
        $motivo = "Código de producto vacío";
    } elseif (!productoExiste($conn, $producto_i)) {
        $motivo = "Producto no existe";
    } elseif (clienteExiste($conn, $codcliente_i)) {
        $motivo = "Cliente repetido";
    } elseif (detalleProductoExiste($conn, $producto_cli)) {
        $motivo = "Detalle de producto repetido";
    } elseif (detalleClienteExiste($conn, $codcliente_i, $producto_cli)) {
        $motivo = "Detalle de cliente repetido";
    } else {
        $datosCliente = [
            'codcliente' => $codcliente_i,
            'nombre' => $nombre_i,
            'apellidos' => $apellidos_i,
            'tipo_cliente' => $tipo_i,
            'fecha' => $fecha_i
        ];
        insertarCliente($conn, $datosCliente);

        $datosDetalleProd = [
            'codproducto_de_cliente' => $producto_cli,
            'codcliente' => $codcliente_i,
            'codproducto' => $producto_i,
            'descripcion' => $desc_i,
            'fecha' => $fecha_i
        ];
        insertarDetalleProducto($conn, $datosDetalleProd);

        $datosDetalleCli = [
            'codcliente' => $codcliente_i,
            'codproducto_de_cliente' => $producto_cli,
            'descripcion' => $desc_i,
            'fecha' => $fecha_i
        ];
        insertarDetalleCliente($conn, $datosDetalleCli);

        $insertado = true;
    }

    $tiempo = round((microtime(true) - $inicio) * 1000);
    $datosRegistro = [
        'fecha' => date('Y-m-d'),
        'registro' => "web"
    ];

    if ($insertado) {
        $observaciones = "Insertado correctamente - Cliente {$codcliente_i}";
        insertarRegistro($conn, $datosRegistro, $observaciones, $tiempo . "ms");
        $mensajes[] = "<div class='success'>Cliente {$codcliente_i} procesado correctamente</div>";
    } else {
        $observaciones = "Insertado incorrectamente - Cliente {$codcliente_i} - {$motivo}";
        insertarRegistro($conn, $datosRegistro, $observaciones, $tiempo . "ms");
        $mensajes[] = "<div class='error'>{$motivo} para cliente {$codcliente_i}</div>";
    }
}

$conn->close();
$_SESSION['mensajes'] = $mensajes;
header("Location: index.php");
exit;
