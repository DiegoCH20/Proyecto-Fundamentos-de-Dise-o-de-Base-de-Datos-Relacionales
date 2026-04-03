-- DDL(Data Definition Language)
-- *** Creando la Base de Datos: Proyecto Ferretería *** --
-- USE master;
-- GO
-- --------------------------------------------------------
IF DB_ID ('ProyectoFerreteria') IS NOT NULL
    DROP DATABASE ProyectoFerreteria;
GO

CREATE DATABASE ProyectoFerreteria;    -- Crear la base de datos
GO
-- --------------------------------------------------------
USE ProyectoFerreteria;                -- Usar la base de datos creada
GO

-- ========================================================
-- BLOQUE 1: TABLAS DE CONFIGURACIÓN Y CATÁLOGOS
-- ========================================================

CREATE TABLE Sucursal ( -- TABLA #1
    PK_Sucursal INT PRIMARY KEY IDENTITY (1,1), -- PK auto-incremental
    Nombre NVARCHAR (100) NOT NULL,
    Direccion NVARCHAR (200),
    Telefono NVARCHAR (20)
);

CREATE TABLE CategoriaProducto ( -- TABLA #2
    PK_Categoria INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL UNIQUE,      -- UNIQUE para no repetir categorías
    Descripcion NVARCHAR (200)
);

CREATE TABLE Rol ( -- TABLA #3
    PK_Rol INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL UNIQUE,
    Descripcion NVARCHAR (200)
);

CREATE TABLE TipoMovimiento ( -- TABLA #4
    PK_TipoMovimiento INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL UNIQUE,
    Signo CHAR (1) NOT NULL,                   -- Ejemplo: '+' entrada, '-' salida
    Descripcion NVARCHAR (200)
);

-- ========================================================
-- BLOQUE 2: TABLAS MAESTRAS (ENTIDADES)
-- ========================================================

CREATE TABLE Cliente ( -- TABLA #5
    PK_Cliente INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL,
    Apellidos NVARCHAR (100),
    Telefono NVARCHAR (20),
    Correo NVARCHAR (100),
    Direccion NVARCHAR (200),
    FechaRegistro DATETIME DEFAULT GETDATE()   -- DEFAULT para fecha actual
);

CREATE TABLE Empleado ( -- TABLA #6
    PK_Empleado INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL,
    Apellidos NVARCHAR (100),
    Telefono NVARCHAR (20),
    Correo NVARCHAR (100),
    FechaContratacion DATE,
    FK_Sucursal INT,                           -- FK hacia Sucursal
    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal)
);

CREATE TABLE Usuario ( -- TABLA #7
    PK_Usuario INT PRIMARY KEY IDENTITY (1,1),
    Username NVARCHAR (50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR (255) NOT NULL,
    Activo BIT DEFAULT 1,                      -- 1 para activo, 0 para inactivo
    FK_Empleado INT UNIQUE,                    -- Relación 1 a 1 con Empleado
    FK_Rol INT NOT NULL,                       -- FK hacia Rol
    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado),
    FOREIGN KEY (FK_Rol) REFERENCES Rol (PK_Rol)
);

CREATE TABLE Proveedor ( -- TABLA #8
    PK_Proveedor INT PRIMARY KEY IDENTITY (1,1),
    CedulaJuridica NVARCHAR (20) UNIQUE NOT NULL,
    Nombre NVARCHAR (100) NOT NULL,
    Telefono NVARCHAR (20),
    Correo NVARCHAR (100),
    Direccion NVARCHAR (200)
);

CREATE TABLE Producto ( -- TABLA #9
    PK_Producto INT PRIMARY KEY IDENTITY (1,1),
    CodigoBarras NVARCHAR (50) UNIQUE NOT NULL,
    Nombre NVARCHAR (100) NOT NULL,
    Descripcion NVARCHAR (500),
    PrecioVenta DECIMAL (10,2) NOT NULL CHECK (PrecioVenta >= 0), -- Evitar precios negativos
    PrecioCosto DECIMAL (10,2) NOT NULL,
    StockMinimo INT DEFAULT 0,
    FK_Categoria INT,                          -- FK hacia Categoria
    FOREIGN KEY (FK_Categoria) REFERENCES CategoriaProducto (PK_Categoria)
);

-- ========================================================
-- BLOQUE 3: TABLAS TRANSACCIONALES (RELACIONES Y MOVIMIENTOS)
-- ========================================================

CREATE TABLE ProductoProveedor ( -- TABLA #10
    FK_Producto INT NOT NULL,
    FK_Proveedor INT NOT NULL,
    PrecioCompra DECIMAL (10,2),
    TiempoEntregaDias INT NOT NULL,
    PRIMARY KEY (FK_Producto, FK_Proveedor),   -- PK Compuesta
    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto),
    FOREIGN KEY (FK_Proveedor) REFERENCES Proveedor (PK_Proveedor)
);

CREATE TABLE Inventario ( -- TABLA #11
    PK_Inventario INT PRIMARY KEY IDENTITY (1,1),
    FK_Sucursal INT NOT NULL,
    FK_Producto INT NOT NULL,
    Cantidad INT NOT NULL DEFAULT 0,
    FechaUltimaActualizacion DATETIME DEFAULT GETDATE(),
    UNIQUE (FK_Sucursal, FK_Producto),         -- Evita duplicar producto en misma sucursal
    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal),
    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto)
);

CREATE TABLE MovimientoInventario ( -- TABLA #12
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

CREATE TABLE Venta ( -- TABLA #13 (Sin Total por 3FN)
    PK_Venta INT PRIMARY KEY,                  -- ID manual o Identity
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    FK_Cliente INT NOT NULL,
    FK_Empleado INT NOT NULL,
    FK_Sucursal INT NOT NULL,
    FOREIGN KEY (FK_Cliente) REFERENCES Cliente (PK_Cliente),
    FOREIGN KEY (FK_Empleado) REFERENCES Empleado (PK_Empleado),
    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal)
);

CREATE TABLE DetalleVenta ( -- TABLA #14
    FK_Venta INT NOT NULL,
    FK_Producto INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL (10,2) NOT NULL,
    Subtotal AS (Cantidad * PrecioUnitario),   -- Columna calculada automáticamente
    PRIMARY KEY (FK_Venta, FK_Producto),       -- PK Compuesta
    FOREIGN KEY (FK_Venta) REFERENCES Venta (PK_Venta) ON DELETE CASCADE,
    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto)
);

CREATE TABLE Devolucion ( -- TABLA #15
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
GO



-- ========================================================
-- INICIO DEL DML (Carga Inicial de Datos)
-- ========================================================



-- ============================================
-- Tablas De Catálogo
-- ============================================

-- Sucursal
Insert Into Sucursal (Nombre, Direccion, Telefono) Values
('Sucursal Central', 'Avenida Principal 123', '2537-2342'),
('Sucursal Norte', 'Calle Secundaria 456', '2537-0130');

-- CategoriaProducto
Insert Into CategoriaProducto (Nombre, Descripcion) Values 
('Herramientas manuales', 'Martillos, destornilladores, llaves'),
('Herramientas eléctricas', 'Taladros, sierras, pulidoras'),
('Materiales de construcción', 'Cemento, arena, blocks'),
('Pinturas y accesorios', 'Pinturas, brochas, rodillos'),
('Electricidad', 'Cables, enchufes, interruptores'),
('Plomería', 'Tuberías, llaves de paso, accesorios de agua'),
('Seguridad industrial', 'Equipo de protección personal'),
('Jardinería', 'Herramientas y accesorios de jardín'),
('Adhesivos y selladores', 'Silicones, pegamentos, resinas'),
('Ferretería general', 'Tornillos, tuercas, fijaciones'),
('Iluminación', 'Bombillos, lámparas, reflectores'),
('Cerrajería', 'CAndados, cerraduras, llaves'),
('Medición y precisión', 'Instrumentos de medición'),
('Limpieza y mantenimiento', 'Productos de limpieza industrial');

-- Rol
Insert Into Rol (Nombre, Descripcion) Values
('Administrador','Acceso completo'),
('Encargado','Gestiona inventario'),
('Cajero','Realiza ventas'),
('Consulta','Solo lectura');

-- TipoMovimiento
Insert Into TipoMovimiento (Nombre, Signo, Descripcion) Values
('Compra', '+', 'Entrada por compra a proveedor'),
('Venta', '-', 'Salida por venta'),
('DevolucionCliente', '+', 'Entrada por devolución de cliente'),
('AjusteInventario', '+', 'Ajuste manual positivo'),
('AjusteInventarioNeg', '-', 'Ajuste manual negativo');

-- ============================================
-- Tablas Maestras
-- ============================================

-- Empleado
Insert Into Empleado (Nombre, Apellidos, Telefono, Correo, FechaContratacion, FK_Sucursal) Values
('Luis','García López','2841-5930','luis.garcia@ferreteria.com','2022-01-10',1),
('Gabriela','Rojas Aguilar','7643-0918','gabriela.rojas@ferreteria.com','2022-01-12',2),
('María','Rodríguez Pérez','8372-1056','maria.rodriguez@ferreteria.com','2022-02-15',1),
('Kevin','Araya Delgado','1925-8364','kevin.araya@ferreteria.com','2022-02-18',2),
('Carlos','Sánchez Mora','4925-8471','carlos.sanchez@ferreteria.com','2022-03-20',1),
('Camila','Esquivel Montero','8450-2719','camila.esquivel@ferreteria.com','2022-03-28',2),
('Ana','Ramírez Vargas','6103-9284','ana.ramirez@ferreteria.com','2022-04-05',1),
('Bryan','SAndoval Reyes','2398-6150','bryan.sAndoval@ferreteria.com','2022-04-10',2),
('Jorge','Fernández Solano','7548-2169','jorge.fernAndez@ferreteria.com','2022-05-12',1),
('Tatiana','Villalobos Cruz','6174-0532','tatiana.villalobos@ferreteria.com','2022-05-22',2),
('Laura','Jiménez Cruz','3290-5714','laura.jimenez@ferreteria.com','2022-06-18',1),
('Oscar','Alvarado Méndez','9502-1847','oscar.alvarado@ferreteria.com','2022-06-30',2),
('Pedro','Castro Rojas','9067-4328','pedro.castro@ferreteria.com','2022-07-22',1),
('Melissa','Segura Gutiérrez','4836-7291','melissa.segura@ferreteria.com','2022-07-15',2),
('Sofía','Vega Morales','1485-6092','sofia.vega@ferreteria.com','2022-08-30',1),
('Adrián','Valverde Torres','7215-4083','adrian.valverde@ferreteria.com','2022-08-19',2),
('Daniel','Navarro Chaves','5731-8426','daniel.navarro@ferreteria.com','2022-09-14',1),
('Karina','Durán Pacheco','3694-5120','karina.duran@ferreteria.com','2022-09-27',2),
('Andrea','Mendoza Herrera','2159-3847','Andrea.mendoza@ferreteria.com','2022-10-01',1),
('Rafael','Soto Herrera','5081-6374','rafael.soto@ferreteria.com','2022-10-09',2),
('Miguel','Ortega Campos','6802-1593','miguel.ortega@ferreteria.com','2022-11-11',1),
('Lucía','Chaves Mora','1427-9856','lucia.chaves@ferreteria.com','2022-11-14',2),
('Valeria','Pineda León','4376-2085','valeria.pineda@ferreteria.com','2022-12-20',1),
('Diego','Campos Solís','8760-2413','diego.campos@ferreteria.com','2022-12-21',2),
('Esteban','Quesada Arias','8914-7630','esteban.quesada@ferreteria.com','2023-01-08',1),
('Elena','Pérez Vargas','2539-8607','elena.perez@ferreteria.com','2023-01-30',2),
('Diana','Salazar Núñez','5267-9104','diana.salazar@ferreteria.com','2023-02-16',1),
('Hugo','Mora Jiménez','6942-1735','hugo.mora@ferreteria.com','2023-02-11',2),
('FernAndo','Cordero Soto','3081-5472','fernAndo.cordero@ferreteria.com','2023-03-25',1),
('Verónica','Arias Rojas','4108-5926','veronica.arias@ferreteria.com','2023-03-05',2);

-- Cliente
Insert Into Cliente (Nombre, Apellidos, Telefono, Correo, Direccion, FechaRegistro) Values
('Andrés','Mora López','8492-1056','Andres.mora@gmail.com','San José, Calle 5, Avenida Central, Casa #12',GetDate()),
('Camila','Rojas Pérez','2731-5984','camila.rojas@gmail.com','Heredia, Barva, Residencial Las Flores, Casa #8',GetDate()),
('Javier','Soto Ramírez','6058-2341','javier.soto@gmail.com','Cartago, Paraíso, Barrio El Carmen, Casa #22',GetDate()),
('Valeria','Castro Gómez','4927-6103','valeria.castro@gmail.com','Alajuela, Centro, Calle 2, Apartamento 3B',GetDate()),
('Diego','Fernández Ruiz','7183-4592','diego.fernAndez@gmail.com','Escazú, San Rafael, Condominio Vista Real, Casa #15',GetDate()),
('Paula','Jiménez Vargas','3250-8714','paula.jimenez@gmail.com','Desamparados, San Miguel, Calle 7, Casa #30',GetDate()),
('Ricardo','Navarro Mora','1946-0238','ricardo.navarro@gmail.com','Curridabat, Granadilla, Residencial El Prado, Casa #5',GetDate()),
('Lucía','Morales Chaves','5832-7410','lucia.morales@gmail.com','Tibás, Cinco Esquinas, Calle 3, Casa #18',GetDate()),
('FernAndo','Pineda Soto','9061-5327','fernAndo.pineda@gmail.com','Moravia, San Vicente, Avenida 4, Casa #9',GetDate()),
('Daniela','Campos Herrera','2374-8169','daniela.campos@gmail.com','Pavas, Rohrmoser, Condominio Los Robles, Apto 12A',GetDate()),
('Kevin','Salazar Cruz','6510-3942','kevin.salazar@gmail.com','Hatillo, Hatillo 6, Calle 10, Casa #45',GetDate()),
('Sofía','Araya León','4185-2073','sofia.araya@gmail.com','Zapote, Barrio Córdoba, Calle 6, Casa #20',GetDate()),
('Bryan','Cordero Vega','8729-4651','bryan.cordero@gmail.com','San Pedro, Montes de Oca, Residencial UCR, Casa #3',GetDate()),
('Natalia','Ortega Núñez','5403-1896','natalia.ortega@gmail.com','Guadalupe, Calle Blancos, Avenida 8, Casa #14',GetDate()),
('Esteban','Quesada Solano','3692-7504','esteban.quesada@gmail.com','Tres Ríos, La Unión, Residencial Omega, Casa #27',GetDate()),
('Mariana','Aguilar Rojas','7215-9438','mariana.aguilar@gmail.com','Aserrí, San Gabriel, Calle 1, Casa #11',GetDate()),
('Oscar','Villalobos Mora','1358-6027','oscar.villalobos@gmail.com','Alajuelita, Tejarcillos, Calle 9, Casa #6',GetDate()),
('Gabriela','Vega Campos','8940-3761','gabriela.vega@gmail.com','San Sebastián, Barrio Cristo Rey, Casa #33',GetDate()),
('Hugo','Chaves Delgado','2067-5149','hugo.chaves@gmail.com','Santa Ana, Pozos, Condominio Santa Verde, Casa #10',GetDate()),
('Melissa','Pacheco Rojas','6431-8295','melissa.pacheco@gmail.com','Belén, La Ribera, Calle 2, Casa #19',GetDate()),
('Adrián','Montero Pérez','9752-1084','adrian.montero@gmail.com','Heredia, Centro, Avenida 6, Casa #21',GetDate()),
('Carla','SAndoval Mora','4286-3517','carla.sAndoval@gmail.com','Barva, San Pedro, Calle 4, Casa #7',GetDate()),
('Luis','Torres Campos','7109-4623','luis.torres@gmail.com','Flores, San Joaquín, Residencial Los Ángeles, Casa #2',GetDate()),
('Tatiana','Arias Vega','3548-9270','tatiana.arias@gmail.com','San Rafael, Heredia, Calle 5, Casa #25',GetDate()),
('Mauricio','Rojas Herrera','5921-0836','mauricio.rojas@gmail.com','Atenas, Centro, Barrio Jesús, Casa #13',GetDate()),
('Elena','Solís Gutiérrez','1873-5462','elena.solis@gmail.com','Grecia, Barrio Latino, Calle 8, Casa #4',GetDate()),
('Cristian','Segura Mora','8630-2197','cristian.segura@gmail.com','Naranjo, San Miguel, Casa #16',GetDate()),
('Noelia','Durán Campos','2495-7301','noelia.duran@gmail.com','Palmares, Zaragoza, Calle 3, Casa #9',GetDate()),
('Iván','Alvarado León','6158-4029','ivan.alvarado@gmail.com','Orotina, Coyolar, Casa #12',GetDate()),
('Karina','Méndez Soto','4307-9658','karina.mendez@gmail.com','San Ramón, Centro, Avenida 2, Casa #6',GetDate()),
('Rafael','Gutiérrez Mora','7682-1430','rafael.gutierrez@gmail.com','Turrialba, Santa Rosa, Casa #18',GetDate()),
('Silvia','Valverde Rojas','9215-8746','silvia.valverde@gmail.com','Paraíso, Llanos de Santa Lucía, Casa #5',GetDate()),
('Erick','Campos Pérez','5043-6912','erick.campos@gmail.com','Cervantes, Barrio San Isidro, Casa #7',GetDate()),
('Verónica','Pineda Mora','2871-3504','veronica.pineda@gmail.com','Pacayas, Centro, Casa #11',GetDate()),
('Andrés','Araya Soto','6394-8127','Andres.araya@gmail.com','Siquirres, Barrio El Bosque, Casa #20',GetDate()),
('Mónica','Reyes Vargas','1526-0783','monica.reyes@gmail.com','Guápiles, Centro, Calle 6, Casa #14',GetDate()),
('Julio','Núñez Campos','8402-9365','julio.nunez@gmail.com','Limón, Centro, Avenida 3, Casa #8',GetDate()),
('Patricia','Cruz Mora','3759-4210','patricia.cruz@gmail.com','Pococí, Cariari, Casa #17',GetDate()),
('Mauricio','Delgado Pérez','7914-5083','mauricio.delgado@gmail.com','Matina, Barrio Boston, Casa #10',GetDate()),
('SAndra','Arias Gómez','2167-3845','sAndra.arias@gmail.com','Bribrí, Talamanca, Casa #6',GetDate()),
('Álvaro','Torres Mora','5380-1692','alvaro.torres@gmail.com','Puntarenas, Centro, Avenida 1, Casa #3',GetDate()),
('Lisbeth','Rojas Cruz','9046-2751','lisbeth.rojas@gmail.com','Esparza, Barrio San Rafael, Casa #9',GetDate()),
('Ronald','Segura Mora','4713-8520','ronald.segura@gmail.com','Barranca, Calle Principal, Casa #15',GetDate()),
('Yessenia','Campos Soto','6295-0437','yessenia.campos@gmail.com','Miramar, Centro, Casa #7',GetDate()),
('Cristian','Vargas León','8531-7264','cristian.vargas@gmail.com','Monteverde, Santa Elena, Casa #12',GetDate());

-- Proveedor
Insert Into Proveedor (CedulaJuridica, Nombre, Telefono, Correo, Direccion) Values
('3-101-459283','Distribuidora El Martillo','2215-9034','ventas@martillo.com','San José, Calle 10, Avenida 5, Edificio Comercial #12'),
('3-002-714056','Suministros Industriales CR','4082-1576','contacto@suministroscr.com','Heredia, Zona Industrial, Bodega #4'),
('3-101-823947','Materiales y Construcción del Valle','2537-8842','info@materialesvalle.com','Cartago, Paraíso, Ruta Nacional 2, Local #7'),
('3-002-105682','FerreEléctrica Costa Rica','2290-3315','soporte@ferreelectrica.com','Alajuela, Centro, Calle 3, Frente al parque'),
('3-101-638520','Importadora Técnica Global','4701-6289','ventas@tecnicaglobal.com','Escazú, San Rafael, Plaza Comercial Torre Norte, Local 21');

-- Producto
Insert Into Producto (CodigoBarras, Nombre, Descripcion, PrecioVenta, PrecioCosto, StockMinimo, FK_Categoria) Values 
('3000000000013','Interruptor','Interruptor sencillo',2500,1500,10,5),
('3000000000001','Martillo','Martillo de acero',3500,2500,5,1),
('3000000000031','Bombillo LED','Bombillo 12W',2500,1500,10,11),
('3000000000016','Llave de paso','Llave de agua',5000,3500,8,6),
('3000000000028','Tornillos','Caja tornillos',4000,2500,20,10),
('3000000000004','Taladro','Taladro eléctrico 500W',35000,28000,2,2),
('3000000000034','CAndado','CAndado seguridad',4500,3000,10,12),
('3000000000022','Pala','Pala metálica',9000,7000,5,8),
('3000000000010','Pintura blanca','Galón pintura blanca',12500,9800,5,4),
('3000000000037','Cinta métrica','Cinta 5m',2500,1500,10,13),
('3000000000007','Cemento','Bolsa 50kg',8500,7200,10,3),
('3000000000019','Casco','Casco de seguridad',12000,9000,5,7),
('3000000000025','Silicón','Silicón sellador',3000,2000,10,9),
('3000000000002','Destornillador','Destornillador plano',3000,2000,5,1),
('3000000000032','Lámpara','Lámpara techo',18000,14000,3,11),
('3000000000014','Tomacorriente','Toma doble',3000,2000,10,5),
('3000000000035','Cerradura','Cerradura puerta',15000,12000,5,12),
('3000000000029','Tuercas','Paquete tuercas',3000,1800,20,10),
('3000000000008','Arena','Saco de arena',3000,2000,15,3),
('3000000000020','Guantes','Guantes protectores',3500,2000,10,7),
('3000000000038','Nivel','Nivel burbuja',4000,2800,6,13),
('3000000000023','Manguera','Manguera 10m',8000,6000,6,8),
('3000000000011','Brocha','Brocha 2 pulgadas',2000,1200,10,4),
('3000000000026','Pegamento','Pegamento industrial',4500,3000,10,9),
('3000000000030','ArAndelas','Paquete arAndelas',2500,1500,20,10),
('3000000000005','Pulidora','Pulidora angular',42000,35000,2,2),
('3000000000017','Tubo PVC','Tubo 1/2 pulgada',3500,2500,20,6),
('3000000000040','Desengrasante','Producto industrial',5000,3500,8,14),
('3000000000015','Cable eléctrico','Cable 12 AWG',1200,800,50,5),
('3000000000039','Calibrador','Calibrador vernier',12000,9000,3,13),
('3000000000024','Tijera podar','Tijera jardín',6500,5000,5,8),
('3000000000012','Rodillo','Rodillo pintura',3500,2500,8,4),
('3000000000041','Escoba','Escoba plástica',3000,2000,10,14),
('3000000000009','Block','Block de concreto',1200,800,50,3),
('3000000000036','Llave','Copia de llave',1500,800,20,12),
('3000000000027','Resina','Resina epóxica',7000,5000,5,9),
('3000000000006','Sierra eléctrica','Sierra circular',60000,50000,1,2),
('3000000000021','Lentes','Lentes de seguridad',4000,2500,8,7),
('3000000000018','Cinta teflón','Cinta selladora',1000,500,20,6),
('3000000000042','Trapeador','Trapeador algodón',4500,3000,8,14),
('3000000000003','Llave inglesa','Llave ajustable',8000,6000,3,1),
('3000000000033','Reflector','Reflector LED',12000,9000,5,11);

-- ============================================
-- Tablas Relacionales
-- ============================================

-- ProductoProveedor
Insert Into ProductoProveedor Values
(1,1,2300,3),
(2,1,1800,2),
(3,5,1200,4),
(4,2,3500,3),
(5,1,2500,2),
(6,5,28000,5),
(7,3,7000,4),
(8,4,6000,3),
(9,2,9800,4),
(10,3,1500,2),
(11,2,7200,5),
(12,4,8500,3),
(13,5,2000,2),
(14,1,2000,2),
(15,3,14000,4),
(16,2,2000,3),
(17,3,12000,4),
(18,1,1800,2),
(19,2,2000,3),
(20,4,2000,2),
(21,3,2800,2),
(22,4,6000,3),
(23,2,1200,2),
(24,5,3000,2),
(25,1,1500,2),
(26,5,35000,5),
(27,2,2500,3),
(28,3,3500,2),
(29,2,800,2),
(30,3,9000,3),
(31,4,5000,2),
(32,2,2500,2),
(33,5,2000,2),
(34,2,800,2),
(35,3,800,2),
(36,5,5000,3),
(37,5,50000,6),
(38,4,2500,2),
(39,2,500,1),
(40,3,3000,2),
(41,1,6000,3),
(42,5,9000,4);

-- Inventario
Insert Into Inventario (FK_Sucursal, FK_Producto, Cantidad) Values 
(1,1,50),
(1,2,40),
(1,3,60),
(1,4,15),
(1,5,80),
(1,6,10),
(1,7,100),
(1,8,70),
(1,9,30),
(1,10,90),
(2,1,45),
(2,2,35),
(2,3,50),
(2,4,20),
(2,5,60),
(2,6,12),
(2,7,95),
(2,8,65),
(2,9,25),
(2,10,85);

-- Usuario
Insert Into Usuario (Username, PasswordHash, Activo, FK_Empleado, FK_Rol) Values 
('lgarcia','hash1',1,1,1), -- Luis García es Administrador
('grojas','hash2',1,2,1), -- Gabriela Rojas es Administrador
('mrodriguez','hash3',1,3,1), -- María Rodríguez es Administrador
('karaya','hash4',1,4,1), -- Kevin Araya es Administrador

('csanchez','hash5',1,5,2), -- Carlos Sánchez es Encargado
('cesquivel','hash6',1,6,2), -- Camila Esquivel es Encargado
('aramirez','hash7',1,7,2), -- Ana Ramírez es Encargado
('bsAndoval','hash8',1,8,2), -- Bryan SAndoval es Encargado
('jfernAndez','hash9',1,9,2), -- Jorge Fernández es Encargado
('tvillalobos','hash10',1,10,2), -- Tatiana Villalobos es Encargado
('ljimenez','hash11',1,11,2), -- Laura Jiménez es Encargado
('oalvarado','hash12',1,12,2), -- Oscar Alvarado es Encargado

('pcastro','hash13',1,13,3), -- Pedro Castro es Cajero
('msegura','hash14',1,14,3), -- Melissa Segura es Cajero
('svega','hash15',1,15,3), -- Sofía Vega es Cajero
('avalverde','hash16',1,16,3), -- Adrián Valverde es Cajero
('dnavarro','hash17',1,17,3), -- Daniel Navarro es Cajero
('kduran','hash18',1,18,3), -- Karina Durán es Cajero
('amendoza','hash19',1,19,3), -- Andrea Mendoza es Cajero
('rsoto','hash20',1,20,3), -- Rafael Soto es Cajero
('mortega','hash21',1,21,3), -- Miguel Ortega es Cajero

('lchaves','hash22',1,22,4), -- Lucía Chaves es Consulta
('vpineda','hash23',1,23,4), -- Valeria Pineda es Consulta
('dcampos','hash24',1,24,4), -- Diego Campos es Consulta
('equesada','hash25',1,25,4), -- Esteban Quesada es Consulta
('eperez','hash26',1,26,4), -- Elena Pérez es Consulta
('dsalazar','hash27',1,27,4), -- Diana Salazar es Consulta
('hmora','hash28',1,28,4), -- Hugo Mora es Consulta
('fcordero','hash29',1,29,4), -- FernAndo Cordero es Consulta
('varias','hash30',1,30,4); -- Verónica Arias es Consulta

-- ============================================
-- Movimientos de Inventario
-- ============================================

Insert Into MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, FK_Usuario) Values 
(1,1,20,'Compra proveedor',1),
(2,2,5,'Venta',3),
(3,2,3,'Venta',3),
(4,1,10,'Reposicion',2),
(5,2,8,'Venta',4),
(6,3,2,'Devolucion cliente',3),
(7,4,5,'Ajuste positivo',2),
(8,5,4,'Ajuste negativo',2);

-- ============================================
-- Ventas y Detalles de Venta
-- ============================================

-- Venta
Insert Into Venta (PK_Venta, Fecha, FK_Cliente, FK_Empleado, FK_Sucursal) Values 
(1,'2025-04-01', 1, 1, 1),
(2,'2025-04-02', 2, 2, 2),
(3,'2025-04-03', 3, 3, 1),
(4,'2025-04-04', 4, 4, 2),
(5,'2025-04-05', 5, 5, 1);

-- DetalleVenta
INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) VALUES 
(1, 1, 2, 3500),
(1, 4, 1, 35000),
(2, 7, 3, 8500),
(2, 10, 2, 2500),
(3, 15, 1, 18000),
(3, 20, 4, 3500),
(4, 25, 2, 2500),
(4, 30, 1, 12000),
(5, 35, 5, 1500),
(5, 40, 2, 4500);

-- ============================================
-- DEVOLUCIONES
-- ============================================

Insert Into Devolucion (FK_Venta, FK_Producto, Cantidad, Motivo, FK_Empleado) Values
(1,1,1,'Producto defectuoso',1),
(2,3,1,'Error en compra',2),
(3,15,1,'Producto dañado',3),
(4,25,2,'No era el producto solicitado',4),
(5,35,1,'Defecto de fábrica',5),
(1,4,1,'Error en facturación',2),
(2,7,2,'Producto incompleto',3),
(3,20,1,'No cumple expectativas',4),
(4,30,1,'Cliente insatisfecho',5),
(5,40,1,'Producto incorrecto',1),
(1,2,1,'Falla funcional',2),
(2,10,1,'Cambio de producto',3),
(3,15,2,'Producto dañado',4),
(4,25,1,'Error en compra',5),
(5,35,1,'No lo necesitaba',1),
(2,7,1,'Producto vencido',2),
(3,20,1,'Defecto menor',3),
(4,30,2,'Entrega incorrecta',4);

-- ============================================
-- Actualizaciones (Update)
-- ============================================

-- 1. Actualizar teléfono de un cliente
Update Cliente
Set Telefono = '8426-3197'
Where PK_Cliente = 12; -- Se modifica Sofia

-- 2. Cambiar precio de un producto
Update Producto
Set PrecioVenta = 4000
Where PK_Producto = 27; -- Se modifica Tubo PVC

-- 3. Actualizar stock en inventario
Update Inventario
Set Cantidad = Cantidad + 10
Where FK_Producto = 7 And FK_Sucursal = 1;

-- 4. Cambiar rol de un usuario
Update Usuario
Set FK_Rol = 2 -- Pasa a ser Encargado
Where PK_Usuario = 13; -- Se modifica Pedro Castro Cajero

-- 5. Actualizar correo de un empleado
Update Empleado
Set Correo = 'nduran.campos@gmail.com'
Where PK_Empleado = 28; -- Se modifica Noelia

-- 6. Modificar motivo de devolución
Update Devolucion
Set Motivo = 'Producto con defecto grave'
Where PK_Devolucion = 6;

-- ============================================
-- Eliminaciones (Delete)
-- ============================================

-- 1. Eliminar una devolución
Delete From Devolucion
Where PK_Devolucion = 2;

-- 2. Eliminar un detalle de venta
Delete From DetalleVenta
Where FK_Venta = 1 And FK_Producto = 2;

-- 3. Eliminar un usuario inactivo
Delete From Usuario
Where Activo = 0;

-- 4. Eliminar un cliente específico
Delete From Cliente
Where PK_Cliente = 5;

-- 5. Eliminar inventario de un producto en una sucursal
Delete From Inventario
Where FK_Producto = 3 And FK_Sucursal = 2;

-- ========================================================
-- Select: Tablas De Catálogo
-- ========================================================

Select * From Sucursal;
Select * From CategoriaProducto;
Select * From Rol;
Select * From TipoMovimiento;

-- ========================================================
-- Select: Tablas Maestras
-- ========================================================

Select * From Cliente;
Select * From Empleado;
Select * From Usuario;
Select * From Proveedor;
Select * From Producto;

-- ========================================================
-- Select: Tablas Relacionales
-- ========================================================

Select * From ProductoProveedor;
Select * From Inventario;

-- ========================================================
-- Select: Movimientos
-- ========================================================

Select * From MovimientoInventario;

-- ========================================================
-- Select: Ventas
-- ========================================================

Select * From Venta;
Select * From DetalleVenta;

-- ========================================================
-- Select: Devoluciones
-- ========================================================

Select * From Devolucion;