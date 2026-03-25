--Base de datos de nuestro proyecto: Ferreteria
-- Normalizacion hasta la 3ra forma normal

USE master;
GO
------------------------------
IF DB_ID ('ProyectoFerreteria') IS NOT NULL
	DROP DATABASE ProyectoFerreteria;
GO
------------------------------
CREATE DATABASE ProyectoFerreteria;
GO
------------------------------
USE ProyectoFerreteria;
GO

-- Aca comenzamos a crear las tablas de nuestra base de datos
-- Comenzamos con  0FN: Tabla No Normalizada (Todos los datos en una sola tabla)
CREATE TABLE Ferreteria_0FN (
	IdVenta INT PRIMARY KEY,
	Cliente NVARCHAR (100),
	ClienteTelefono NVARCHAR (20),
	ClienteCorreo NVARCHAR (100),
	ClienteDireccion NVARCHAR (200),
	Sucursal NVARCHAR (100),
	Empleado NVARCHAR (100),
	FechaVenta DATE,
	Productos NVARCHAR (500),      -- Multivaluado (varios productos)
	Cantidades NVARCHAR (200),     -- Multivaluado (varias cantidades)
	PreciosUnitarios NVARCHAR (200), -- Multivaluado (varios precios)
	Proveedores NVARCHAR (500),    -- Multivaluado (varios proveedores)
	Total DECIMAL (10,2)
);

INSERT INTO Ferreteria_0FN VALUES 
(1, 'Carlos Pérez', '8888-1111', 'carlos@gmail.com', 'Residencial Vista Linda', 
 'Sucursal Central', 'Laura Mora', '2025-03-20', 
 'Martillo, Destornillador, Taladro', '2, 1, 1', '3500, 4500, 35000',
 'Ferretería Central, Herramientas S.A.', 43000.00),
(2, 'Ana Gómez', '8888-2222', 'ana.gomez@yahoo.com', 'Condominio Jardines',
 'Sucursal Norte', 'Sofía Rojas', '2025-03-21',
 'Cemento, Clavos, Pintura', '1, 10, 2', '8500, 2500, 12500',
 'Distribuidora Nacional, Ferretería Central', 36000.00),
(3, 'Luis Rodríguez', '8888-3333', 'luis.rod@gmail.com', 'Barrio San José',
 'Sucursal Central', 'Laura Mora', '2025-03-22',
 'Taladro, Martillo', '1, 3', '35000, 3500',
 'Herramientas S.A., Ferretería Central', 45500.00);

SELECT * FROM Ferreteria_0FN;
GO

-- 1FN: Eliminamos grupos repetitivos y asegurar que cada atributo contenga un solo valor atómico.

CREATE TABLE Ferreteria_1FN (
	IdVenta INT,
	Cliente NVARCHAR (100),
	ClienteTelefono NVARCHAR (20),
	ClienteCorreo NVARCHAR (100),
	ClienteDireccion NVARCHAR (200),
	Sucursal NVARCHAR (100),
	Empleado NVARCHAR (100),
	FechaVenta DATE,
	Producto NVARCHAR (100),        -- Ahora es atómico (Estamos utilizando un solo producto)
	Cantidad INT,                   -- Ahora es atómico
	PrecioUnitario DECIMAL (10,2),  -- Ahora es atómico
	Proveedor NVARCHAR (100),       -- Un solo proveedor por fila
	Total DECIMAL (10,2)
);

-- Pero si notamos sigue siendo inconveniente porque tenemos que repetir la información del cliente, sucursal, empleado, fecha y total para cada producto vendido en la misma venta. Esto nos lleva a la 2FN.

INSERT INTO Ferreteria_1FN VALUES 
(1, 'Carlos Pérez', '8888-1111', 'carlos@gmail.com', 'Residencial Vista Linda',
 'Sucursal Central', 'Laura Mora', '2025-03-20', 'Martillo', 2, 3500.00,
 'Ferretería Central', 43000.00),
(1, 'Carlos Pérez', '8888-1111', 'carlos@gmail.com', 'Residencial Vista Linda',
 'Sucursal Central', 'Laura Mora', '2025-03-20', 'Destornillador', 1, 4500.00,
 'Ferretería Central', 43000.00),
(1, 'Carlos Pérez', '8888-1111', 'carlos@gmail.com', 'Residencial Vista Linda',
 'Sucursal Central', 'Laura Mora', '2025-03-20', 'Taladro', 1, 35000.00,
 'Herramientas S.A.', 43000.00),
(2, 'Ana Gómez', '8888-2222', 'ana.gomez@yahoo.com', 'Condominio Jardines',
 'Sucursal Norte', 'Sofía Rojas', '2025-03-21', 'Cemento', 1, 8500.00,
 'Distribuidora Nacional', 36000.00),
(2, 'Ana Gómez', '8888-2222', 'ana.gomez@yahoo.com', 'Condominio Jardines',
 'Sucursal Norte', 'Sofía Rojas', '2025-03-21', 'Clavos', 10, 2500.00,
 'Ferretería Central', 36000.00),
(2, 'Ana Gómez', '8888-2222', 'ana.gomez@yahoo.com', 'Condominio Jardines',
 'Sucursal Norte', 'Sofía Rojas', '2025-03-21', 'Pintura', 2, 12500.00,
 'Ferretería Central', 36000.00),
(3, 'Luis Rodríguez', '8888-3333', 'luis.rod@gmail.com', 'Barrio San José',
 'Sucursal Central', 'Laura Mora', '2025-03-22', 'Taladro', 1, 35000.00,
 'Herramientas S.A.', 45500.00),
(3, 'Luis Rodríguez', '8888-3333', 'luis.rod@gmail.com', 'Barrio San José',
 'Sucursal Central', 'Laura Mora', '2025-03-22', 'Martillo', 3, 3500.00,
 'Ferretería Central', 45500.00);

SELECT * FROM Ferreteria_1FN;
GO

-- 2FN: Eliminamos dependencias parciales. Cada tabla debe depender completamente de la clave primaria.
-- Solucion en este escenario: Separar en tablas según las entidades

-- Aqui manejamos nuestras entidades Maestras mencionadas en el punto 4.1

-- Tabla: Sucursal
CREATE TABLE Sucursal (
	PK_Sucursal INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (100) NOT NULL,
	Direccion NVARCHAR (200),
	Telefono NVARCHAR (20)
);

-- Tabla: Empleado
CREATE TABLE Empleado (
	PK_Empleado INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (50) NOT NULL,
	Apellidos NVARCHAR (100),
	Telefono NVARCHAR (20),
	Correo NVARCHAR (100),
	FechaContratacion DATE,
	FK_Sucursal INT,
	    FOREIGN KEY (FK_Sucursal) REFERENCES SUCURSAL (PK_Sucursal)
);

-- Tabla: Cliente
CREATE TABLE Cliente (
	PK_Cliente INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (50) NOT NULL,
	Apellidos NVARCHAR (100),
	Telefono NVARCHAR (20),
	Correo NVARCHAR (100),
	Direccion NVARCHAR (200),
	FechaRegistro DATE
);

-- Tabla: Proveedor
CREATE TABLE Proveedor (
	PK_Proveedor INT PRIMARY KEY IDENTITY (1,1),
	CedulaJuridica NVARCHAR (20) UNIQUE NOT NULL,
	Nombre NVARCHAR (100) NOT NULL,
	Telefono NVARCHAR (20),
	Correo NVARCHAR (100),
	Direccion NVARCHAR (200)
);

-- Tabla: Producto
CREATE TABLE Producto (
	PK_Producto INT PRIMARY KEY IDENTITY (1,1),
	CodigoBarras NVARCHAR (50) UNIQUE NOT NULL,
	Nombre NVARCHAR (100) NOT NULL,
	Descripcion NVARCHAR (500),
	PrecioVenta DECIMAL (10,2) NOT NULL,
	PrecioCosto DECIMAL (10,2) NOT NULL,
	StockMinimo INT DEFAULT 0
);

-- Aqui manejamos las entidades de configuracion mencionadas en el punto 4.2

-- Tabla: CategoriaProducto
CREATE TABLE CategoriaProducto (
	PK_Categoria INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (50) NOT NULL UNIQUE, -- No permitimos categorias duplicadas
	Descripcion NVARCHAR (200)
);

-- Agregamos Foreign Key a Producto
ALTER TABLE Producto ADD FK_Categoria INT;
ALTER TABLE Producto ADD FOREIGN KEY (FK_Categoria) REFERENCES CategoriaProducto (PK_Categoria);

-- Tabla: Rol
CREATE TABLE Rol (
	PK_Rol INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (50) NOT NULL UNIQUE,
	Descripcion NVARCHAR (200)
);

-- Tabla: TipoMovimiento
CREATE TABLE TipoMovimiento (
	PK_TipoMovimiento INT PRIMARY KEY IDENTITY (1,1),
	Nombre NVARCHAR (50) NOT NULL UNIQUE,
	Signo CHAR (1) NOT NULL,
	Descripcion NVARCHAR (200)
);

-- Aqui manejamos las entidades transaccionales mencionadas en el punto 4.3

-- Tabla: Usuario
CREATE TABLE Usuario (
	PK_Usuario INT PRIMARY KEY IDENTITY (1,1),
	Username NVARCHAR (50) NOT NULL UNIQUE,
	PasswordHash NVARCHAR (255) NOT NULL,
	Activo BIT DEFAULT 1, -- 1 para activo, 0 para inactivo
	FK_Empleado INT UNIQUE,
	FK_Rol INT NOT NULL,
	    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado),
	    FOREIGN KEY (FK_Rol) REFERENCES Rol (PK_Rol)
);

-- Tabla: Venta
CREATE TABLE Venta (
	PK_Venta INT PRIMARY KEY,
	Fecha DATETIME NOT NULL,
	FK_Cliente INT NOT NULL,
	FK_Empleado INT NOT NULL,
	FK_Sucursal INT NOT NULL,
	Total DECIMAL (10,2) NOT NULL,
	    FOREIGN KEY (FK_Cliente) REFERENCES Cliente (PK_Cliente),
	    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado),
	    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal)
);

-- Tabla: DetalleVenta
CREATE TABLE DetalleVenta (
	FK_Venta INT NOT NULL,
	FK_Producto INT NOT NULL,
	Cantidad INT NOT NULL,
	PrecioUnitario DECIMAL (10,2) NOT NULL,
	Subtotal DECIMAL (10,2) NOT NULL,
	    PRIMARY KEY (FK_Venta, FK_Producto), -- Clave primaria compuesta por FK_Venta y FK_Producto
	    FOREIGN KEY (FK_Venta) REFERENCES Venta (PK_Venta),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto)
);

-- Tabla: ProductoProveedor (Relacion muchos a muchos entre Producto y Proveedor, con atributos adicionales)
CREATE TABLE ProductoProveedor (
	FK_Producto INT NOT NULL,
	FK_Proveedor INT NOT NULL,
	PrecioCompra DECIMAL (10,2),
	TiempoEntregaDias INT NOT NULL,
	    PRIMARY KEY (FK_Producto, FK_Proveedor),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto),
	    FOREIGN KEY (FK_Proveedor) REFERENCES Proveedor (PK_Proveedor)
);

-- Tabla: Inventario
CREATE TABLE Inventario (
	PK_Inventario INT PRIMARY KEY IDENTITY (1,1),
	FK_Sucursal INT NOT NULL,
	FK_Producto INT NOT NULL,
	Cantidad INT NOT NULL DEFAULT 0,
	FechaUltimaActualizacion DATETIME DEFAULT GETDATE(),
	    UNIQUE (FK_Sucursal, FK_Producto),
	    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto)
);

-- Tabla: MovimientoInventario (Registra cada movimiento de inventario, ya sea entrada o salida, con su motivo y usuario responsable)
CREATE TABLE MovimientoInventario (
	PK_Movimiento INT PRIMARY KEY IDENTITY (1,1),
	FK_Inventario INT NOT NULL,
	FK_TipoMovimiento INT NOT NULL,
	Cantidad INT NOT NULL,
	Fecha DATETIME DEFAULT GETDATE(),
	Motivo NVARCHAR (200),
	FK_Usuario INT,
	    FOREIGN KEY (FK_Inventario) REFERENCES Inventario (PK_Inventario),
	    FOREIGN KEY (FK_TipoMovimiento) REFERENCES TipoMovimiento (PK_TipoMovimiento),
	    FOREIGN KEY (FK_Usuario) REFERENCES Usuario (PK_Usuario)
);

-- Tabla: Devolucion
CREATE TABLE Devolucion (
	PK_Devolucion INT PRIMARY KEY IDENTITY (1,1),
	Fecha DATETIME DEFAULT GETDATE(),
	FK_Venta INT NOT NULL,
	FK_Producto INT NOT NULL,
	Cantidad INT NOT NULL,
	Motivo NVARCHAR (200),
	FK_Empleado INT NOT NULL,
	    FOREIGN KEY (FK_Venta) REFERENCES Venta (PK_Venta),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto),
	    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado)
);

-- Se insertan datos de ejemplo en las tablas maestras y de configuración para poder realizar pruebas posteriormente

INSERT INTO Sucursal (Nombre, Direccion, Telefono) VALUES 
('Sucursal Central', 'Avenida Principal 123', '2222-1111'),
('Sucursal Norte', 'Calle Secundaria 456', '2222-2222');

INSERT INTO Empleado (Nombre, Apellidos, Telefono, Correo, FechaContratacion, FK_Sucursal) VALUES 
('Laura', 'Mora Solano', '8888-6666', 'laura.mora@ferreteria.com', '2023-01-15', 1),
('Sofía', 'Rojas Brenes', '8888-8888', 'sofia.rojas@ferreteria.com', '2023-03-10', 2);

INSERT INTO Cliente (Nombre, Apellidos, Telefono, Correo, Direccion, FechaRegistro) VALUES 
('Carlos', 'Pérez González', '8888-1111', 'carlos@gmail.com', 'Residencial Vista Linda, Casa 12', GETDATE()),
('Ana', 'Gómez Rodríguez', '8888-2222', 'ana.gomez@yahoo.com', 'Condominio Jardines, Apto 3B', GETDATE()),
('Luis', 'Rodríguez Vargas', '8888-3333', 'luis.rod@gmail.com', 'Barrio San José, Calle 4', GETDATE());

INSERT INTO Proveedor (CedulaJuridica, Nombre, Telefono, Correo, Direccion) VALUES 
('3-101-123456', 'Ferretería Central', '2222-4444', 'central@ferreteria.com', 'Avenida Principal 123'),
('3-102-789012', 'Distribuidora Nacional', '2222-5555', 'distribuidora@ferreteria.com', 'Calle Secundaria 456'),
('3-103-345678', 'Herramientas S.A.', '2222-6666', 'herramientas@ferreteria.com', 'Zona Industrial 789');

INSERT INTO CategoriaProducto (Nombre, Descripcion) VALUES 
('Herramientas manuales', 'Martillos, destornilladores, llaves'),
('Herramientas eléctricas', 'Taladros, sierras, pulidoras'),
('Materiales de construcción', 'Cemento, arena, blocks'),
('Pinturas y accesorios', 'Pinturas, brochas, rodillos');

INSERT INTO Producto (CodigoBarras, Nombre, Descripcion, PrecioVenta, PrecioCosto, StockMinimo, FK_Categoria) VALUES 
('1234567890123', 'Martillo', 'Martillo de acero con mango de madera', 3500.00, 2500.00, 5, 1),
('1234567890124', 'Destornillador', 'Juego de destornilladores 6 piezas', 4500.00, 3200.00, 3, 1),
('1234567890125', 'Taladro', 'Taladro eléctrico 500W', 35000.00, 28000.00, 2, 2),
('1234567890126', 'Cemento', 'Bolsa de cemento 50kg', 8500.00, 7200.00, 10, 3),
('1234567890127', 'Clavos', 'Caja de clavos 2 pulgadas', 2500.00, 1800.00, 15, 4),
('1234567890128', 'Pintura Blanca', 'Galerón de pintura blanca mate', 12500.00, 9800.00, 5, 4);

INSERT INTO ProductoProveedor VALUES 
(1, 1, 2300.00, 3),
(2, 1, 3000.00, 3),
(3, 3, 26000.00, 5),
(4, 2, 7000.00, 4),
(5, 1, 1700.00, 2),
(6, 1, 9200.00, 4);

INSERT INTO Rol (Nombre, Descripcion) VALUES 
('Administrador', 'Acceso completo al sistema'),
('Encargado', 'Control de inventario y empleados'),
('Cajero', 'Registro de ventas y devoluciones'),
('Consulta', 'Solo visualización de información');

INSERT INTO Usuario (Username, PasswordHash, Activo, FK_Empleado, FK_Rol) VALUES 
('lmora', 'hash_para_laura', 1, 1, 1),   -- Laura es Administrador
('srojas', 'hash_para_sofia', 1, 2, 3);  -- Sofia es Cajero

INSERT INTO Venta VALUES 
(1, '2025-03-20', 1, 1, 1, 43000.00),
(2, '2025-03-21', 2, 2, 2, 36000.00),
(3, '2025-03-22', 3, 1, 1, 45500.00);

INSERT INTO DetalleVenta VALUES 
(1, 1, 2, 3500.00, 7000.00),  
(1, 2, 1, 4500.00, 4500.00),  
(1, 3, 1, 35000.00, 35000.00),
(2, 4, 1, 8500.00, 8500.00), 
(2, 5, 10, 2500.00, 25000.00),
(2, 6, 2, 12500.00, 25000.00),
(3, 3, 1, 35000.00, 35000.00),
(3, 1, 3, 3500.00, 10500.00);

INSERT INTO Inventario (FK_Sucursal, FK_Producto, Cantidad) VALUES 
(1, 1, 50),
(1, 2, 30),
(1, 3, 15),
(1, 4, 100),
(1, 5, 200),
(1, 6, 25), 
(2, 1, 40),
(2, 2, 25);

INSERT INTO TipoMovimiento (Nombre, Signo, Descripcion) VALUES 
('Compra', '+', 'Entrada por compra a proveedor'),
('Venta', '-', 'Salida por venta'),
('DevolucionCliente', '+', 'Entrada por devolución de cliente'),
('AjusteInventario', '+', 'Ajuste manual positivo'),
('AjusteInventarioNeg', '-', 'Ajuste manual negativo');

INSERT INTO MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, FK_Usuario) VALUES 
(1, 1, 20, 'Compra a Ferretería Central', 1),
(3, 2, 1, 'Venta #1', 1),
(1, 2, 2, 'Venta #1', 1); 

SELECT * FROM Sucursal;
SELECT * FROM Empleado;
SELECT * FROM Cliente;
SELECT * FROM Proveedor;
SELECT * FROM CategoriaProducto;
SELECT * FROM Producto;
SELECT * FROM ProductoProveedor;
SELECT * FROM Rol;
SELECT * FROM Usuario;
SELECT * FROM Venta;
SELECT * FROM DetalleVenta;
SELECT * FROM Inventario;
SELECT * FROM TipoMovimiento;
SELECT * FROM MovimientoInventario;
GO


-- Como resultado: Se eliminaron dependencias parciales. Se cumple 2FN.
-- Pero siguen existiendo dependencias transitivas, por ejemplo: En la tabla Venta, el Total depende de la cantidad y precio unitario de los productos vendidos, lo cual no es parte de la clave primaria. 
-- Esto nos lleva a la 3FN.

-- 3FN: Eliminamos dependencias transitivas. Cada atributo no clave debe depender únicamente de la clave primaria.

DROP TABLE MovimientoInventario;
DROP TABLE Devolucion;
DROP TABLE DetalleVenta;
DROP TABLE Venta;

-- Creamos nuevamente la tabla Venta sin el atributo Total, ya que este se puede calcular a partir de los detalles de la venta (DetalleVenta) y no debe depender directamente de la tabla Venta.
CREATE TABLE Venta (
	PK_Venta INT PRIMARY KEY,
	Fecha DATETIME NOT NULL,
	FK_Cliente INT NOT NULL,
	FK_Empleado INT NOT NULL,
	FK_Sucursal INT NOT NULL, -- Total DECIMAL(10,2) lo eliminamos, lo vamos a calcular desde detalle
	    FOREIGN KEY (FK_Cliente) REFERENCES Cliente (PK_Cliente),
	    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado),
	    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal)
);

CREATE TABLE DetalleVenta (
	FK_Venta INT NOT NULL,
	FK_Producto INT NOT NULL,
	Cantidad INT NOT NULL,
	PrecioUnitario DECIMAL (10,2) NOT NULL,
	Subtotal DECIMAL (10,2) NOT NULL,
	    PRIMARY KEY (FK_Venta, FK_Producto),
	    FOREIGN KEY (FK_Venta) REFERENCES Venta (PK_Venta),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto)
);

CREATE TABLE Devolucion (
	PK_Devolucion INT PRIMARY KEY IDENTITY (1,1),
	Fecha DATETIME DEFAULT GETDATE(),
	FK_Venta INT NOT NULL,
	FK_Producto INT NOT NULL,
	Cantidad INT NOT NULL,
	Motivo NVARCHAR (200),
	FK_Empleado INT NOT NULL,
	    FOREIGN KEY (FK_Venta) REFERENCES Venta (PK_Venta),
	    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto),
	    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado)
);

CREATE TABLE MovimientoInventario (
	PK_Movimiento INT PRIMARY KEY IDENTITY (1,1),
	FK_Inventario INT NOT NULL,
	FK_TipoMovimiento INT NOT NULL,
	Cantidad INT NOT NULL,
	Fecha DATETIME DEFAULT GETDATE(),
	Motivo NVARCHAR (200),
	FK_Usuario INT,
	    FOREIGN KEY (FK_Inventario) REFERENCES Inventario (PK_Inventario),
	    FOREIGN KEY (FK_TipoMovimiento) REFERENCES TipoMovimiento (PK_TipoMovimiento),
	    FOREIGN KEY (FK_Usuario) REFERENCES Usuario (PK_Usuario)
);

-- Aca insertamos info sin el total en la tabla Venta, ya que este se puede calcular a partir de DetalleVenta
INSERT INTO Venta VALUES 
(1, '2025-03-20', 1, 1, 1),
(2, '2025-03-21', 2, 2, 2),
(3, '2025-03-22', 3, 1, 1);

INSERT INTO DetalleVenta VALUES 
(1, 1, 2, 3500.00, 7000.00),   -- Venta 1: 2 Martillos
(1, 2, 1, 4500.00, 4500.00),   -- Venta 1: 1 Destornillador
(1, 3, 1, 35000.00, 35000.00), -- Venta 1: 1 Taladro
(2, 4, 1, 8500.00, 8500.00),   -- Venta 2: 1 Cemento
(2, 5, 10, 2500.00, 25000.00), -- Venta 2: 10 Clavos
(2, 6, 2, 12500.00, 25000.00), -- Venta 2: 2 Pinturas
(3, 3, 1, 35000.00, 35000.00), -- Venta 3: 1 Taladro
(3, 1, 3, 3500.00, 10500.00);  -- Venta 3: 3 Martillos

INSERT INTO MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, FK_Usuario) VALUES 
(1, 1, 20, 'Compra a Ferretería Central', 1),
(3, 2, 1, 'Venta #1', 1),
(1, 2, 2, 'Venta #1', 1);

-- Ejemplo SELECT
SELECT 
	V.PK_Venta AS IdVenta,
	C.Nombre + ' ' + C.Apellidos AS Cliente,
	S.Nombre AS Sucursal,
	E.Nombre + ' ' + E.Apellidos AS Empleado,
	V.Fecha,
	SUM(D.Subtotal) AS TotalCalculado
FROM VENTA V
INNER JOIN CLIENTE C ON V.FK_Cliente = C.PK_Cliente
INNER JOIN SUCURSAL S ON V.FK_Sucursal = S.PK_Sucursal
INNER JOIN EMPLEADO E ON V.FK_Empleado = E.PK_Empleado
INNER JOIN DETALLE_VENTA D ON V.PK_Venta = D.FK_Venta
GROUP BY V.PK_Venta, C.Nombre, C.Apellidos, S.Nombre, E.Nombre, E.Apellidos, V.Fecha
ORDER BY V.PK_Venta;

-- Resumen de nuestra Normalización:
-- 0FN: Todos los datos en una sola tabla, con atributos multivaluados y redundantes.
-- 1FN: Eliminamos grupos repetitivos y aseguramos que cada atributo contenga un solo valor atómico, pero aún tenemos redundancia de datos.
-- 2FN: Eliminamos dependencias parciales separando en tablas según las entidades,
-- pero aún tenemos dependencias transitivas (por ejemplo, el Total en Venta).
-- 3FN: Eliminamos dependencias transitivas, por ejemplo, eliminamos el Total de la tabla Venta, ya que se puede calcular a partir de DetalleVenta, logrando así una estructura más limpia y eficiente.