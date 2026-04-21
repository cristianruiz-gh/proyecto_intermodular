CREATE DATABASE IF NOT EXISTS crylam_db;

USE crylam_db;

CREATE TABLE catalogo_de_productos (
    codproducto INT PRIMARY KEY,
    nombre_producto VARCHAR(45),
    precio_producto VARCHAR(45)
);

CREATE TABLE cabecera_de_clientes (
    codcliente INT PRIMARY KEY,
    nombre_cliente VARCHAR(45) NOT NULL,
    apellidos_cliente VARCHAR(45),
    tipo_cliente VARCHAR(45),
    fecha DATE
);

CREATE TABLE detalle_de_cliente (
    codcliente INT NOT NULL,
    codproducto_de_cliente INT NOT NULL,
    descripcion_atributo TEXT,
    fecha DATE,
    PRIMARY KEY (codcliente, codproducto_de_cliente)
);

CREATE TABLE detalle_de_producto (
    codproducto_de_cliente INT PRIMARY KEY AUTO_INCREMENT,
    codcliente INT NOT NULL,
    codproducto INT NOT NULL,
    descripcion_atributo VARCHAR(45),
    fecha DATE
);

CREATE TABLE registros (
    codregistro INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    registro TEXT,
    observaciones TEXT,
    tiempo VARCHAR(12)
);

INSERT INTO catalogo_de_productos (codproducto, nombre_producto, precio_producto) VALUES
(100, 'Producto A', 55.99),
(101, 'Producto B', 75.49),
(102, 'Producto C', 120.00),
(103, 'Producto D', 30.50),
(104, 'Producto E', 85.25);
(105, 'Producto F', 60.00),
(106, 'Producto G', 45.75),
(107, 'Producto H', 150.00),
(108, 'Producto I', 25.99),
(109, 'Producto J', 90.00);
(110, 'Producto K', 110.50),
(111, 'Producto L', 70.00),
(112, 'Producto M', 40.25),
(113, 'Producto N', 95.00),
(114, 'Producto O', 80.75);
(115, 'Producto P', 65.00),
(116, 'Producto Q', 55.50),
(117, 'Producto R', 130.00),
(118, 'Producto S', 35.99),
(119, 'Producto T', 100.00);
(120, 'Producto U', 150.00),
(121, 'Producto V', 45.00),
(122, 'Producto W', 60.75),
(123, 'Producto X', 85.00),
(124, 'Producto Y', 70.25);
(125, 'Producto Z', 90.50);

