/*=========================================
ARCHIVO MAESTRO - PROYECTO FERRETERIA
=========================================*/

/*======================================================
DDL(Data Definition Language)
*** Creando la Base de Datos: Proyecto Ferretería *** 
USE master;
GO
========================================================*/

IF DB_ID ('ProyectoFerreteria') IS NOT NULL
    DROP DATABASE ProyectoFerreteria;
GO

CREATE DATABASE ProyectoFerreteria;  -- Crear la base de datos
GO
-- --------------------------------------------------------
USE ProyectoFerreteria;  -- Usar la base de datos creada
GO

/*=======================================================
 BLOQUE 1: TABLAS DE CONFIGURACIÓN Y CATÁLOGOS
 ========================================================*/

CREATE TABLE Sucursal ( -- TABLA #1
    PK_Sucursal INT PRIMARY KEY IDENTITY (1,1), -- ID de la sucursal (se genera automáticamente)
    Nombre NVARCHAR (100) NOT NULL,
    Direccion NVARCHAR (200),
    Telefono NVARCHAR (20)
);

CREATE TABLE CategoriaProducto ( -- TABLA #2
    PK_Categoria INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL UNIQUE, -- Evita que se repitan nombres de categorías
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
    Signo CHAR (1) NOT NULL, -- Indica si suma o resta inventario (+ entrada, - salida)
    Descripcion NVARCHAR (200)
);

/*======================================================
-- BLOQUE 2: TABLAS MAESTRAS (ENTIDADES)
========================================================*/

CREATE TABLE Cliente ( -- TABLA #5
    PK_Cliente INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL,
    Apellidos NVARCHAR (100),
    Telefono NVARCHAR (20),
    Correo NVARCHAR (100),
    Direccion NVARCHAR (200),
    FechaRegistro DATETIME DEFAULT GETDATE()-- Guarda la fecha automáticamente
);

CREATE TABLE Empleado ( -- TABLA #6
    PK_Empleado INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR (50) NOT NULL,
    Apellidos NVARCHAR (100),
    Telefono NVARCHAR (20),
    Correo NVARCHAR (100),
    FechaContratacion DATE,
    FK_Sucursal INT, -- Relación con la sucursal donde trabaja
    FOREIGN KEY (FK_Sucursal) REFERENCES Sucursal (PK_Sucursal)
);

CREATE TABLE Usuario ( -- TABLA #7
    PK_Usuario INT PRIMARY KEY IDENTITY (1,1),
    Username NVARCHAR (50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR (255) NOT NULL,
    Activo BIT DEFAULT 1, -- 1 para activo, 0 para inactivo
    FK_Empleado INT UNIQUE, -- Relación 1 a 1 con Empleado
    FK_Rol INT NOT NULL,  -- FK hacia Rol
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
    FK_Categoria INT,-- Categoría del producto
    FOREIGN KEY (FK_Categoria) REFERENCES CategoriaProducto (PK_Categoria)
);

/* ===========================================================
BLOQUE 3: TABLAS TRANSACCIONALES (RELACIONES Y MOVIMIENTOS)
========================================================*/

CREATE TABLE ProductoProveedor ( -- TABLA #10
    FK_Producto INT NOT NULL,
    FK_Proveedor INT NOT NULL,
    PrecioCompra DECIMAL (10,2),
    TiempoEntregaDias INT NOT NULL,
    PRIMARY KEY (FK_Producto, FK_Proveedor),  -- Clave primaria combinada
    FOREIGN KEY (FK_Producto) REFERENCES Producto (PK_Producto),
    FOREIGN KEY (FK_Proveedor) REFERENCES Proveedor (PK_Proveedor)
);

CREATE TABLE Inventario ( -- TABLA #11
    PK_Inventario INT PRIMARY KEY IDENTITY (1,1),
    FK_Sucursal INT NOT NULL,
    FK_Producto INT NOT NULL,
    Cantidad INT NOT NULL DEFAULT 0,
    FechaUltimaActualizacion DATETIME DEFAULT GETDATE(),
    UNIQUE (FK_Sucursal, FK_Producto), -- Evita duplicar producto en misma sucursal
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
    PK_Venta INT PRIMARY KEY,  -- ID manual o Identity
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
    Subtotal AS (Cantidad * PrecioUnitario), -- Columna calculada automáticamente
    PRIMARY KEY (FK_Venta, FK_Producto), -- PK Compuesta
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

/* ======================================================
 INICIO DEL DML (Carga Inicial de Datos)
 ========================================================*/

/* ==========================================
 Tablas De Catálogo
 ============================================*/

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
('Cerrajería', 'Candado, cerraduras, llaves'),
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

/*===========================================
 Tablas Maestras
============================================*/

-- Empleado
Insert Into Empleado (Nombre, Apellidos, Telefono, Correo, FechaContratacion, FK_Sucursal) Values
('Luis','García López','2841-5930','luis.garcia@ferreteria.com','2022-01-10',1),
('Gabriela','Rojas Aguilar','7643-0918','gabriela.rojas@ferreteria.com','2022-01-12',2),
('María','Rodríguez Pérez','8372-1056','maria.rodriguez@ferreteria.com','2022-02-15',1),
('Kevin','Araya Delgado','1925-8364','kevin.araya@ferreteria.com','2022-02-18',2),
('Carlos','Sánchez Mora','4925-8471','carlos.sanchez@ferreteria.com','2022-03-20',1),
('Camila','Esquivel Montero','8450-2719','camila.esquivel@ferreteria.com','2022-03-28',2),
('Ana','Ramírez Vargas','6103-9284','ana.ramirez@ferreteria.com','2022-04-05',1),
('Bryan','Sandoval Reyes','2398-6150','bryan.Sandoval@ferreteria.com','2022-04-10',2),
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
('Fernando','Cordero Soto','3081-5472','Fernando.cordero@ferreteria.com','2023-03-25',1),
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
('Fernando','Pineda Soto','9061-5327','Fernando.pineda@gmail.com','Moravia, San Vicente, Avenida 4, Casa #9',GetDate()),
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
('Cristian','Vargas León','8531-7264','cristian.vargas@gmail.com','Monteverde, Santa Elena, Casa #12',GetDate()),
('Jorge','Mora Rojas','8881-1001','jorge.mora1@gmail.com','San José, Barrio México',GETDATE()),
('Andrea','Solís Pérez','8881-1002','andrea.solis2@gmail.com','Heredia, Santo Domingo',GETDATE()),
('Luis','Vargas Castro','8881-1003','luis.vargas3@gmail.com','Cartago, Oreamuno',GETDATE()),
('Daniela','Herrera Soto','8881-1004','daniela.herrera4@gmail.com','Alajuela, Grecia',GETDATE()),
('Marco','Rojas León','8881-1005','marco.rojas5@gmail.com','San Ramón, Centro',GETDATE()),
('Valeria','Campos Núñez','8881-1006','valeria.campos6@gmail.com','Liberia, Guanacaste',GETDATE()),
('Sebastián','Pérez Mora','8881-1007','sebastian.perez7@gmail.com','Puntarenas, Centro',GETDATE()),
('Carolina','Jiménez Rojas','8881-1008','carolina.jimenez8@gmail.com','Limón, Centro',GETDATE()),
('Fernando','Castro Solano','8881-1009','fernando.castro9@gmail.com','Desamparados, San Miguel',GETDATE()),
('Gabriela','Torres Vargas','8881-1010','gabriela.torres10@gmail.com','Curridabat, Granadilla',GETDATE()),
('Mauricio','Araya Rojas','8881-1011','mauricio.araya11@gmail.com','Moravia, San Vicente',GETDATE()),
('Natalia','Cordero Mora','8881-1012','natalia.cordero12@gmail.com','Tibás, Cinco Esquinas',GETDATE()),
('Ricardo','Valverde Castro','8881-1013','ricardo.valverde13@gmail.com','Santa Ana, Pozos',GETDATE()),
('Laura','Segura León','8881-1014','laura.segura14@gmail.com','Escazú, San Rafael',GETDATE()),
('Esteban','Campos Rojas','8881-1015','esteban.campos15@gmail.com','Hatillo, San Sebastián',GETDATE()),
('Mónica','Pineda Vargas','8881-1016','monica.pineda16@gmail.com','Zapote, Centro',GETDATE()),
('Andrés','Durán Mora','8881-1017','andres.duran17@gmail.com','Goicoechea, Guadalupe',GETDATE()),
('Sofía','Arias Solano','8881-1018','sofia.arias18@gmail.com','Alajuelita, Centro',GETDATE()),
('Kevin','Navarro Rojas','8881-1019','kevin.navarro19@gmail.com','San Pedro, UCR',GETDATE()),
('Paola','Gutiérrez Castro','8881-1020','paola.gutierrez20@gmail.com','Tres Ríos, La Unión',GETDATE());

-- Proveedor
Insert Into Proveedor (CedulaJuridica, Nombre, Telefono, Correo, Direccion) Values
('3-101-459283','Distribuidora El Martillo','2215-9034','ventas@martillo.com','San José, Calle 10, Avenida 5, Edificio Comercial #12'),
('3-002-714056','Suministros Industriales CR','4082-1576','contacto@suministroscr.com','Heredia, Zona Industrial, Bodega #4'),
('3-101-823947','Materiales y Construcción del Valle','2537-8842','info@materialesvalle.com','Cartago, Paraíso, Ruta Nacional 2, Local #7'),
('3-002-105682','FerreEléctrica Costa Rica','2290-3315','soporte@ferreelectrica.com','Alajuela, Centro, Calle 3, Frente al parque'),
('3-101-638520','Importadora Técnica Global','4701-6289','ventas@tecnicaglobal.com','Escazú, San Rafael, Plaza Comercial Torre Norte, Local 21'),
('3-002-558741','Distribuidora del Norte CR','2245-7788','ventas@nortecr.com','Heredia, San Joaquín, Zona Comercial, Local 5'),
('3-101-774209','Materiales El Constructor','2560-3344','info@constructorcr.com','Cartago, Centro, Avenida 2, Edificio #10'),
('3-002-893415','Suministros Técnicos del Sur','2784-9901','contacto@tecnicosur.com','Pérez Zeledón, Barrio San Isidro, Local 3'),
('3-101-662318','Importadora Industrial del Pacífico','2661-5522','ventas@pacificoind.com','Puntarenas, Centro, Frente al muelle'),
('3-002-481920','Ferretería Profesional CR','2233-1199','soporte@ferrepro.com','San José, Zapote, Calle 15, Casa #22'),
('3-101-990234','Distribuciones Globales','2299-4455','ventas@globalcr.com','Escazú, Guachipelín, Plaza Comercial Sur'),
('3-002-775619','Materiales del Caribe','2758-2233','info@caribecr.com','Limón, Centro, Avenida Principal'),
('3-101-443287','Proveedora Nacional Técnica','2221-6677','contacto@nacionaltec.com','San Pedro, Montes de Oca, Edificio Azul'),
('3-002-118764','Suministros Eléctricos CR','2244-8899','ventas@electricoscr.com','Alajuela, Centro, Calle 8, Local 2'),
('3-101-559832','Importadora del Valle Central','2288-5566','info@vallecentral.com','Heredia, Santo Domingo, Zona Industrial'),
('3-002-334455','Distribuidora MegaTools','2255-1122','ventas@megatools.com','San José, Tibás, Calle Principal'),
('3-101-667788','Materiales y Acabados CR','2277-3344','info@acabadoscr.com','Cartago, Oreamuno, Ruta Nacional'),
('3-002-889900','Ferretería Industrial del Norte','2480-5566','soporte@ferreind.com','San Carlos, Ciudad Quesada, Centro'),
('3-101-223344','Proveedora Técnica Avanzada','2295-7788','contacto@tecnicaavanzada.com','Curridabat, Centro, Plaza del Sol'),
('3-002-556677','Importadora ConstruMarket','2266-9900','ventas@construmarket.com','Escazú, Multiplaza, Local 15');

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
('3000000000033','Reflector','Reflector LED',12000,9000,5,11),
('3000000000043','Extensión eléctrica','Extensión 5 metros',6500,4500,10,5),
('3000000000044','Brocha 4 pulgadas','Brocha profesional',3500,2500,8,4),
('3000000000045','Disco de corte','Disco para pulidora',2500,1500,15,2),
('3000000000046','Llave tubo','Llave tubo 1/2',6000,4000,10,1),
('3000000000047','Regleta eléctrica','Regleta 6 tomas',7000,5000,8,5),
('3000000000048','Pintura azul','Galón pintura azul',13000,10000,5,4),
('3000000000049','Mazo','Mazo de goma',8000,6000,5,1),
('3000000000050','Bomba agua','Bomba pequeña',45000,38000,2,6),
('3000000000051','Escalera','Escalera aluminio',55000,45000,2,8),
('3000000000052','Taladro inalámbrico','Taladro batería',65000,55000,2,2);

/* ==========================================
 Tablas Relacionales
 ============================================*/

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

-- Sucursal 1 (Productos 1–50)
(1,1,30),(1,2,25),(1,3,40),(1,4,60),(1,5,20),
(1,6,35),(1,7,45),(1,8,50),(1,9,55),(1,10,30),
(1,11,25),(1,12,10),(1,13,20),(1,14,15),(1,15,30),
(1,16,45),(1,17,35),(1,18,25),(1,19,40),(1,20,50),
(1,21,30),(1,22,20),(1,23,15),(1,24,25),(1,25,20),
(1,26,30),(1,27,25),(1,28,40),(1,29,60),(1,30,20),
(1,31,35),(1,32,45),(1,33,50),(1,34,55),(1,35,30),
(1,36,25),(1,37,10),(1,38,20),(1,39,15),(1,40,30),
(1,41,45),(1,42,35),(1,43,25),(1,44,40),(1,45,50),
(1,46,30),(1,47,20),(1,48,15),(1,49,25),(1,50,10),

-- Sucursal 2 (Productos 1–50)
(2,1,28),(2,2,22),(2,3,38),(2,4,55),(2,5,18),
(2,6,30),(2,7,42),(2,8,48),(2,9,50),(2,10,28),
(2,11,22),(2,12,12),(2,13,18),(2,14,14),(2,15,28),
(2,16,40),(2,17,32),(2,18,22),(2,19,38),(2,20,45),
(2,21,28),(2,22,18),(2,23,12),(2,24,22),(2,25,8),
(2,26,28),(2,27,22),(2,28,38),(2,29,55),(2,30,18),
(2,31,30),(2,32,42),(2,33,48),(2,34,50),(2,35,28),
(2,36,22),(2,37,12),(2,38,18),(2,39,14),(2,40,28),
(2,41,40),(2,42,32),(2,43,22),(2,44,38),(2,45,45),
(2,46,28),(2,47,18),(2,48,12),(2,49,22),(2,50,8);

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

/* ==========================================
 Movimientos de Inventario
 ============================================ */

Insert Into MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, FK_Usuario) Values 
(1,1,20,'Compra proveedor',1),
(2,2,5,'Venta',3),
(3,2,3,'Venta',3),
(4,1,10,'Reposicion',2),
(5,2,8,'Venta',4),
(6,3,2,'Devolucion cliente',3),
(7,4,5,'Ajuste positivo',2),
(8,5,4,'Ajuste negativo',2),
(9,2,4,'Venta',3),
(10,1,15,'Compra proveedor',2),
(11,2,2,'Venta',3),
(12,3,1,'Devolucion cliente',4),
(13,4,5,'Ajuste positivo',2),
(14,5,3,'Ajuste negativo',2),
(15,2,6,'Venta',3),
(16,1,20,'Compra proveedor',1),
(17,2,2,'Venta',3),
(18,3,1,'Devolucion cliente',4),
(19,2,3,'Venta',3),
(20,1,10,'Reposicion',2),
(21,2,4,'Venta',3),
(22,3,2,'Devolucion cliente',4),
(23,4,6,'Ajuste positivo',2),
(24,5,2,'Ajuste negativo',2),
(25,2,5,'Venta',3),
(26,1,12,'Compra proveedor',1),
(27,2,3,'Venta',3),
(28,3,1,'Devolucion cliente',4);

/*===========================================
 Ventas y Detalles de Venta
 ============================================*/

-- Venta
Insert Into Venta (PK_Venta, Fecha, FK_Cliente, FK_Empleado, FK_Sucursal) Values 
(1,'2025-04-01', 1, 1, 1),
(2,'2025-04-02', 2, 2, 2),
(3,'2025-04-03', 3, 3, 1),
(4,'2025-04-04', 4, 4, 2),
(5,'2025-04-05', 5, 5, 1),
(6,'2025-04-06', 6, 6, 2),
(7,'2025-04-07', 7, 7, 1),
(8,'2025-04-08', 8, 8, 2),
(9,'2025-04-09', 9, 9, 1),
(10,'2025-04-10', 10, 10, 2),
(11,'2025-04-11', 11, 11, 1),
(12,'2025-04-12', 12, 12, 2),
(13,'2025-04-13', 13, 13, 1),
(14,'2025-04-14', 14, 14, 2),
(15,'2025-04-15', 15, 15, 1),
(16,'2025-04-16', 16, 16, 2),
(17,'2025-04-17', 17, 17, 1),
(18,'2025-04-18', 18, 18, 2),
(19,'2025-04-19', 19, 19, 1),
(20,'2025-04-20', 20, 20, 2),
(21,'2025-04-21', 21, 21, 1),
(22,'2025-04-22', 22, 22, 2),
(23,'2025-04-23', 23, 23, 1),
(24,'2025-04-24', 24, 24, 2),
(25,'2025-04-25', 25, 25, 1),
(26,'2025-04-26', 26, 26, 2),
(27,'2025-04-27', 27, 27, 1),
(28,'2025-04-28', 28, 28, 2),
(29,'2025-04-29', 29, 29, 1),
(30,'2025-04-30', 30, 30, 2),
(31,'2025-05-01', 31, 1, 1),
(32,'2025-05-02', 32, 2, 2),
(33,'2025-05-03', 33, 3, 1),
(34,'2025-05-04', 34, 4, 2),
(35,'2025-05-05', 35, 5, 1),
(36,'2025-05-06', 36, 6, 2),
(37,'2025-05-07', 37, 7, 1),
(38,'2025-05-08', 38, 8, 2),
(39,'2025-05-09', 39, 9, 1),
(40,'2025-05-10', 40, 10, 2),
(41,'2025-05-11', 41, 11, 1),
(42,'2025-05-12', 42, 12, 2),
(43,'2025-05-13', 43, 13, 1),
(44,'2025-05-14', 44, 14, 2),
(45,'2025-05-15', 45, 15, 1),
(46,'2025-05-16', 46, 16, 2),
(47,'2025-05-17', 47, 17, 1),
(48,'2025-05-18', 48, 18, 2),
(49,'2025-05-19', 49, 19, 1),
(50,'2025-05-20', 50, 20, 2);

-- DetalleVenta
INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) VALUES 
(1,1,2,3500),
(1,4,1,35000),
(2,7,3,8500),
(2,10,2,2500),
(3,15,1,18000),
(3,20,4,3500),
(4,25,2,2500),
(4,30,1,12000),
(5,35,5,1500),
(5,40,2,4500),
(6,11,2,8500),
(6,12,1,12000),
(7,13,3,3000),
(7,14,2,3000),
(8,15,1,18000),
(8,16,2,3000),
(9,17,1,15000),
(9,18,2,3000),
(10,19,2,3000),
(10,20,1,3500),
(11,21,2,4000),
(11,22,1,8000),
(12,23,3,2000),
(12,24,1,4500),
(13,25,2,4500),
(13,2,1,3000),
(14,3,2,2500),
(14,4,1,5000),
(15,5,2,4000),
(15,6,1,35000),
(16,7,2,4500),
(16,8,1,9000),
(17,9,2,12500),
(17,10,1,2500),
(18,11,2,8500),
(18,12,1,12000),
(19,13,2,3000),
(19,14,1,3000),
(20,15,2,18000),
(20,16,1,3000),
(21,17,2,15000),
(21,18,1,3000),
(22,19,2,3000),
(22,20,1,3500),
(23,1,2,3500),
(23,2,1,3000),
(24,3,2,2500),
(24,4,1,5000),
(25,5,2,4000),
(25,6,1,35000),
(26,7,2,4500),
(26,8,1,9000),
(27,9,2,12500),
(27,10,1,2500),
(28,11,2,8500),
(28,12,1,12000),
(29,13,2,3000),
(29,14,1,3000),
(30,15,2,18000),
(30,16,1,3000),
(31,17,2,15000),
(31,18,1,3000),
(32,19,2,3000),
(32,20,1,3500),
(33,21,2,4000),
(33,22,1,8000),
(34,23,2,2000),
(34,24,1,4500),
(35,25,2,4500),
(35,1,1,3500),
(36,2,2,3000),
(36,3,1,2500),
(37,4,2,5000),
(37,5,1,4000),
(38,6,2,35000),
(38,7,1,4500),
(39,8,2,9000),
(39,9,1,12500),
(40,10,2,2500),
(40,11,1,8500),
(41,12,2,12000),
(41,13,1,3000),
(42,14,2,3000),
(42,15,1,18000),
(43,16,2,3000),
(43,17,1,15000),
(44,18,2,3000),
(44,19,1,3000),
(45,20,2,3500),
(45,1,1,3500),
(46,2,2,3000),
(46,3,1,2500),
(47,4,2,5000),
(47,5,1,4000),
(48,6,2,35000),
(48,7,1,4500),
(49,8,2,9000),
(49,9,1,12500),
(50,10,2,2500),
(50,11,1,8500);

/* ========================================
 DEVOLUCIONES
============================================*/

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
(6,11,1,'Producto defectuoso',6),
(7,13,1,'Error en compra',7),
(8,15,1,'Producto dañado',8),
(9,17,1,'No era el producto solicitado',9),
(10,19,1,'Defecto de fábrica',10),
(11,21,1,'Error en facturación',11),
(12,23,1,'Producto incompleto',12),
(13,25,1,'No cumple expectativas',13),
(14,3,1,'Cliente insatisfecho',14),
(15,5,1,'Producto incorrecto',15),
(16,7,1,'Falla funcional',16),
(17,9,1,'Cambio de producto',17),
(18,11,1,'Producto dañado',18),
(19,13,1,'Error en compra',19),
(20,15,1,'No lo necesitaba',20),
(21,17,1,'Producto vencido',21),
(22,19,1,'Defecto menor',22),
(23,1,1,'Entrega incorrecta',23),
(24,3,1,'Producto defectuoso',24),
(25,5,1,'Error en compra',25),
(26,7,1,'Producto dañado',26),
(27,9,1,'No era el producto solicitado',27),
(28,11,1,'Defecto de fábrica',28),
(29,13,1,'Error en facturación',29),
(30,15,1,'Producto incompleto',30),
(31,17,1,'No cumple expectativas',1),
(32,19,1,'Cliente insatisfecho',2),
(33,21,1,'Producto incorrecto',3),
(34,23,1,'Falla funcional',4),
(35,25,1,'Cambio de producto',5),
(36,2,1,'Producto dañado',6),
(37,4,1,'Error en compra',7),
(38,6,1,'No lo necesitaba',8),
(39,8,1,'Producto vencido',9),
(40,10,1,'Defecto menor',10),
(41,12,1,'Entrega incorrecta',11),
(42,14,1,'Producto defectuoso',12),
(43,16,1,'Error en compra',13),
(44,18,1,'Producto dañado',14),
(45,20,1,'No era el producto solicitado',15),
(46,2,1,'Defecto de fábrica',16),
(47,4,1,'Error en facturación',17),
(48,6,1,'Producto incompleto',18),
(49,8,1,'No cumple expectativas',19),
(50,10,1,'Cliente insatisfecho',20);

/* =======================================
 Actualizaciones (Update)
============================================*/

-- Cambiar teléfono de un cliente
Update Cliente
Set Telefono = '8426-3197'
Where PK_Cliente = 12; -- Se modifica Sofia

-- Cambiar precio de un producto
Update Producto
Set PrecioVenta = 4000
Where PK_Producto = 27; -- Se modifica Tubo PVC

-- Cambiar rol de un usuario
Update Usuario
Set FK_Rol = 2 -- Pasa a ser Encargado
Where PK_Usuario = 13; -- Se modifica Pedro Castro Cajero

-- Actualizar correo de un empleado
Update Empleado
Set Correo = 'nduran.campos@gmail.com'
Where PK_Empleado = 28; -- Se modifica Noelia

-- Modificar motivo de devolución
Update Devolucion
Set Motivo = 'Producto con defecto grave'
Where PK_Devolucion = 6;

/* =========================================================
 Eliminaciones
========================================================= */

-- Eliminar una devolución
Delete From Devolucion
Where PK_Devolucion = 2;

-- Eliminar un detalle de venta
Delete From DetalleVenta
Where FK_Venta = 1 And FK_Producto = 2;

-- Eliminar un usuario inactivo
Delete From Usuario
Where Activo = 0;

-- Eliminar un cliente específico

-- Borrar devoluciones relacionadas con las ventas del cliente
DELETE FROM Devolucion 
WHERE FK_Venta IN (
    SELECT PK_Venta FROM Venta WHERE FK_Cliente = 5
);

-- Borrar detalles de venta relacionados
DELETE FROM DetalleVenta 
WHERE FK_Venta IN (
    SELECT PK_Venta FROM Venta WHERE FK_Cliente = 5
);

-- Borrar ventas del cliente
DELETE FROM Venta 
WHERE FK_Cliente = 5;

-- Finalmente borrar el cliente
DELETE FROM Cliente 
WHERE PK_Cliente = 5;

-- Eliminar inventario de un producto en una sucursal
Delete From Inventario
Where FK_Producto = 3 And FK_Sucursal = 2;


/*==============================================================
  DESARROLLO DE FUNCIONES DEFINIDAS POR EL USUARIO
==============================================================*/

-- Calcula subtotal
GO
CREATE FUNCTION fn_calcular_subtotal
(
    @cantidad INT,
    @precio DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN (@cantidad * @precio);
END;
GO
SELECT dbo.fn_calcular_subtotal(3, 1500);
-- Calcula impuesto
GO
CREATE FUNCTION fn_impuesto
(
    @monto DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN (@monto * 0.13);
END
GO
-- Calcula total con impuesto
GO
CREATE FUNCTION fn_total
(
    @monto DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @monto + (@monto * 0.13)
END
GO
-- Aplica descuento
GO
CREATE FUNCTION fn_descuento
(
    @precio DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @precio * 0.90
END
GO
-- Aplica aumento
GO
CREATE FUNCTION fn_aumento
(
    @precio DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @precio * 1.05
END
GO
--Precio Venta
SELECT 
p.PrecioVenta,
dbo.fn_impuesto(p.PrecioVenta) AS impuesto,
dbo.fn_total(p.PrecioVenta) AS total
FROM Producto p;
--Precio Costo
SELECT 
p.PrecioCosto,
dbo.fn_impuesto(p.PrecioCosto) AS impuesto,
dbo.fn_total(p.PrecioCosto) AS total
FROM Producto p;

/*=================================================================
Procedimientos almacenados (STORED PROCEDURES)
===================================================================*/

-- ELIMINAR PROCEDIMIENTOS SI EXISTEN


IF OBJECT_ID('sp_InsertarCliente') IS NOT NULL DROP PROCEDURE sp_InsertarCliente;
IF OBJECT_ID('sp_ConsultarClientes') IS NOT NULL DROP PROCEDURE sp_ConsultarClientes;

IF OBJECT_ID('sp_InsertarProducto') IS NOT NULL DROP PROCEDURE sp_InsertarProducto;
IF OBJECT_ID('sp_ActualizarProducto') IS NOT NULL DROP PROCEDURE sp_ActualizarProducto;
IF OBJECT_ID('sp_ConsultarProductos') IS NOT NULL DROP PROCEDURE sp_ConsultarProductos;

IF OBJECT_ID('sp_AjustarInventario') IS NOT NULL DROP PROCEDURE sp_AjustarInventario;

IF OBJECT_ID('sp_CrearVenta') IS NOT NULL DROP PROCEDURE sp_CrearVenta;
IF OBJECT_ID('sp_AgregarDetalleVenta') IS NOT NULL DROP PROCEDURE sp_AgregarDetalleVenta;
IF OBJECT_ID('sp_ConsultarVentas') IS NOT NULL DROP PROCEDURE sp_ConsultarVentas;

IF OBJECT_ID('sp_RegistrarDevolucion') IS NOT NULL DROP PROCEDURE sp_RegistrarDevolucion;

IF OBJECT_ID('sp_ProductosBajoStock') IS NOT NULL DROP PROCEDURE sp_ProductosBajoStock;
GO

-- PROCEDIMIENTOS DE CLIENTES

GO
CREATE PROCEDURE sp_InsertarCliente 
    @Nombre NVARCHAR(50),
    @Apellidos NVARCHAR(100),
    @Telefono NVARCHAR(20),
    @Correo NVARCHAR(100),
    @Direccion NVARCHAR(200)
AS
BEGIN
    INSERT INTO Cliente (Nombre, Apellidos, Telefono, Correo, Direccion)-- Inserta un cliente nuevo
    VALUES (@Nombre, @Apellidos, @Telefono, @Correo, @Direccion);
END;
GO

CREATE PROCEDURE sp_ConsultarClientes -- Muestra todos los clientes
AS
BEGIN
    SELECT * FROM Cliente;
END;
GO

-- PROCEDIMIENTOS DE PRODUCTOS

CREATE PROCEDURE sp_InsertarProducto 
    @CodigoBarras NVARCHAR(50),
    @Nombre NVARCHAR(100),
    @Descripcion NVARCHAR(500),
    @PrecioVenta DECIMAL(10,2),
    @PrecioCosto DECIMAL(10,2),
    @StockMinimo INT,
    @FK_Categoria INT
AS
BEGIN
    INSERT INTO Producto  -- Agrega un producto
    (CodigoBarras, Nombre, Descripcion, PrecioVenta, PrecioCosto, StockMinimo, FK_Categoria)
    VALUES
    (@CodigoBarras, @Nombre, @Descripcion, @PrecioVenta, @PrecioCosto, @StockMinimo, @FK_Categoria);
END;
GO

CREATE PROCEDURE sp_ActualizarProducto  -- Actualiza información básica de un producto
    @PK_Producto INT,
    @Nombre NVARCHAR(100),
    @PrecioVenta DECIMAL(10,2)
AS
BEGIN
    UPDATE Producto
    SET Nombre = @Nombre,
        PrecioVenta = @PrecioVenta
    WHERE PK_Producto = @PK_Producto;
END;
GO

CREATE PROCEDURE sp_ConsultarProductos -- Lista productos con su categoría
AS
BEGIN
    SELECT P.*, C.Nombre AS Categoria
    FROM Producto P
    INNER JOIN CategoriaProducto C 
        ON P.FK_Categoria = C.PK_Categoria;
END;
GO


-- PROCEDIMIENTO DE INVENTARIO

CREATE PROCEDURE sp_AjustarInventario 
    @FK_Sucursal INT,
    @FK_Producto INT,
    @Cantidad INT
AS
BEGIN
    UPDATE Inventario  
    SET Cantidad = Cantidad + @Cantidad,
        FechaUltimaActualizacion = GETDATE()
    WHERE FK_Sucursal = @FK_Sucursal
    AND FK_Producto = @FK_Producto;
END;
GO


--PROCEDIMIENTOS DE VENTAS


CREATE PROCEDURE sp_CrearVenta     
    @PK_Venta INT,
    @FK_Cliente INT,
    @FK_Empleado INT,
    @FK_Sucursal INT
AS
BEGIN
    INSERT INTO Venta (PK_Venta, Fecha, FK_Cliente, FK_Empleado, FK_Sucursal) -- Crea una venta
    VALUES (@PK_Venta, GETDATE(), @FK_Cliente, @FK_Empleado, @FK_Sucursal);
END;
GO

CREATE PROCEDURE sp_AgregarDetalleVenta 
    @FK_Venta INT,
    @FK_Producto INT,
    @Cantidad INT
AS
BEGIN
    DECLARE @Precio DECIMAL(10,2);
    DECLARE @Sucursal INT;

    SELECT @Precio = PrecioVenta -- Busca el precio del producto
    FROM Producto
    WHERE PK_Producto = @FK_Producto;

    IF @Precio IS NULL
    BEGIN
        PRINT 'Error: Producto no existe'; -- Verifica que el producto exista
        RETURN;
    END

    SELECT @Sucursal = FK_Sucursal  -- Busca la sucursal de la venta
    FROM Venta
    WHERE PK_Venta = @FK_Venta;

    INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) -- Agrega el detalle de la venta
    VALUES (@FK_Venta, @FK_Producto, @Cantidad, @Precio);

    --UPDATE Inventario -- Actualizar inventario SOLO en la sucursal correspondiente
    --SET Cantidad = Cantidad - @Cantidad,
        --FechaUltimaActualizacion = GETDATE()
    --WHERE FK_Producto = @FK_Producto
    --AND FK_Sucursal = @Sucursal;
END;
GO

CREATE PROCEDURE sp_ConsultarVentas -- Muestra ventas con cliente, empleado y total
AS
BEGIN
    SELECT 
        V.PK_Venta,
        C.Nombre + ' ' + C.Apellidos AS Cliente,
        S.Nombre AS Sucursal,
        E.Nombre + ' ' + E.Apellidos AS Empleado,
        V.Fecha,
        SUM(D.Subtotal) AS Total
    FROM Venta V
    INNER JOIN Cliente C ON V.FK_Cliente = C.PK_Cliente
    INNER JOIN Sucursal S ON V.FK_Sucursal = S.PK_Sucursal
    INNER JOIN Empleado E ON V.FK_Empleado = E.PK_Empleado
    INNER JOIN DetalleVenta D ON V.PK_Venta = D.FK_Venta
    GROUP BY 
        V.PK_Venta, C.Nombre, C.Apellidos, 
        S.Nombre, E.Nombre, E.Apellidos, V.Fecha;
END;
GO


--PROCEDIMIENTO DE DEVOLUCIONES


CREATE PROCEDURE sp_RegistrarDevolucion 
    @FK_Venta INT,
    @FK_Producto INT,
    @Cantidad INT,
    @Motivo NVARCHAR(200),
    @FK_Empleado INT
AS
BEGIN
    DECLARE @Sucursal INT;

    SELECT @Sucursal = FK_Sucursal  -- Busca la sucursal de la venta
    FROM Venta
    WHERE PK_Venta = @FK_Venta;

    INSERT INTO Devolucion (FK_Venta, FK_Producto, Cantidad, Motivo, FK_Empleado) -- Guarda la devolución
    VALUES (@FK_Venta, @FK_Producto, @Cantidad, @Motivo, @FK_Empleado);

    UPDATE Inventario  -- Suma los productos al inventario
    SET Cantidad = Cantidad + @Cantidad
    WHERE FK_Producto = @FK_Producto
    AND FK_Sucursal = @Sucursal;
END;
GO


-- PROCEDIMIENTO DE REPORTES

CREATE PROCEDURE sp_ProductosBajoStock  -- Muestra productos con poco stock
AS
BEGIN
    SELECT P.*
    FROM Producto P
    INNER JOIN Inventario I 
        ON P.PK_Producto = I.FK_Producto
    WHERE I.Cantidad <= P.StockMinimo;
END;
GO
/*=================================================================
              VISTAS 
===================================================================*/

-- ELIMINAR VISTAS SI EXISTEN


IF OBJECT_ID('vw_ProductosDetalle') IS NOT NULL DROP VIEW vw_ProductosDetalle;
IF OBJECT_ID('vw_InventarioSucursal') IS NOT NULL DROP VIEW vw_InventarioSucursal;
IF OBJECT_ID('vw_VentasDetalle') IS NOT NULL DROP VIEW vw_VentasDetalle;
IF OBJECT_ID('vw_FacturaDetalle') IS NOT NULL DROP VIEW vw_FacturaDetalle;
IF OBJECT_ID('vw_ProductosMasVendidos') IS NOT NULL DROP VIEW vw_ProductosMasVendidos;
GO

-- VISTA DE PRODUCTOS

CREATE VIEW vw_ProductosDetalle
AS
SELECT 
    p.PK_Producto,
    p.Nombre AS Producto,
    cp.Nombre AS Categoria,
    pr.Nombre AS Proveedor,
    p.PrecioVenta,
    p.PrecioCosto
FROM Producto p
INNER JOIN CategoriaProducto cp 
    ON p.FK_Categoria = cp.PK_Categoria
INNER JOIN ProductoProveedor pp 
    ON p.PK_Producto = pp.FK_Producto
INNER JOIN Proveedor pr 
    ON pp.FK_Proveedor = pr.PK_Proveedor;
GO


-- VISTA DE INVENTARIO POR SUCURSAL


CREATE VIEW vw_InventarioSucursal
AS
SELECT 
    s.Nombre AS Sucursal,
    p.Nombre AS Producto,
    i.Cantidad,
    i.FechaUltimaActualizacion
FROM Inventario i
INNER JOIN Sucursal s 
    ON i.FK_Sucursal = s.PK_Sucursal
INNER JOIN Producto p 
    ON i.FK_Producto = p.PK_Producto;
GO


-- VISTA DE VENTAS

CREATE VIEW vw_VentasDetalle
AS
SELECT 
    v.PK_Venta,
    v.Fecha,
    c.Nombre AS Cliente,
    e.Nombre AS Empleado,
    s.Nombre AS Sucursal
FROM Venta v
INNER JOIN Cliente c 
    ON v.FK_Cliente = c.PK_Cliente
INNER JOIN Empleado e 
    ON v.FK_Empleado = e.PK_Empleado
INNER JOIN Sucursal s 
    ON v.FK_Sucursal = s.PK_Sucursal;
GO

-- VISTA DETALLE DE FACTURA

CREATE VIEW vw_FacturaDetalle
AS
SELECT 
    v.PK_Venta,
    c.Nombre AS Cliente,
    p.Nombre AS Producto,
    dv.Cantidad,
    dv.PrecioUnitario,
    dv.Subtotal,
    v.Fecha
FROM DetalleVenta dv
INNER JOIN Venta v 
    ON dv.FK_Venta = v.PK_Venta
INNER JOIN Producto p 
    ON dv.FK_Producto = p.PK_Producto
INNER JOIN Cliente c 
    ON v.FK_Cliente = c.PK_Cliente;
GO


-- VISTA DE PRODUCTOS MAS VENDIDOS

CREATE VIEW vw_ProductosMasVendidos
AS
SELECT 
    p.Nombre AS Producto,
    SUM(dv.Cantidad) AS TotalVendido
FROM DetalleVenta dv
INNER JOIN Producto p 
    ON dv.FK_Producto = p.PK_Producto
GROUP BY p.Nombre;
GO

/*=================================================================
Disparadores (Triggers)
===================================================================*/



-- TRIGGERS DE VENTAS


CREATE TRIGGER tr_ActualizarStockPorVenta
ON DetalleVenta
AFTER INSERT
AS
BEGIN
    -- Resta del inventario lo que se vendió
    UPDATE I
    SET I.Cantidad = I.Cantidad - ins.Cantidad
    FROM Inventario I
    INNER JOIN inserted ins ON I.FK_Producto = ins.FK_Producto
    INNER JOIN Venta V ON ins.FK_Venta = V.PK_Venta
    WHERE I.FK_Sucursal = V.FK_Sucursal;
END;
GO


CREATE TRIGGER tr_ValidarStockDisponible
ON DetalleVenta
INSTEAD OF INSERT
AS
BEGIN
    -- Valida que exista suficiente stock antes de registrar una venta
    IF EXISTS (
        SELECT 1
        FROM inserted ins
        INNER JOIN Venta V ON ins.FK_Venta = V.PK_Venta
        INNER JOIN Inventario I 
            ON ins.FK_Producto = I.FK_Producto 
            AND V.FK_Sucursal = I.FK_Sucursal
        WHERE I.Cantidad < ins.Cantidad
    )
    BEGIN
        RAISERROR ('Error: No hay suficiente stock en esta sucursal.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario)
        SELECT FK_Venta, FK_Producto, Cantidad, PrecioUnitario 
        FROM inserted;
    END
END;
GO


-- TRIGGERS DE DEVOLUCIONES

CREATE TRIGGER tr_DevolucionAjusteStock
ON Devolucion
AFTER INSERT
AS
BEGIN
    -- Suma al inventario los productos que han sido devueltos
    UPDATE I
    SET I.Cantidad = I.Cantidad + ins.Cantidad
    FROM Inventario I
    INNER JOIN inserted ins ON I.FK_Producto = ins.FK_Producto
    INNER JOIN Venta V ON ins.FK_Venta = V.PK_Venta
    WHERE I.FK_Sucursal = V.FK_Sucursal;
END;
GO


-- TRIGGERS DE AUDITORÍA

CREATE TRIGGER tr_AuditoriaPrecios
ON Producto
AFTER UPDATE
AS
BEGIN
    -- Registra en el historial cuando se modifica el precio de un producto
    IF UPDATE(PrecioVenta)
    BEGIN
        INSERT INTO MovimientoInventario 
        (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, Fecha)
        SELECT 
            I.PK_Inventario, 
            4, -- Tipo de movimiento: ajuste/cambio
            1, 
            'Cambio de precio detectado para el producto', 
            GETDATE()
        FROM inserted ins
        INNER JOIN Inventario I 
            ON ins.PK_Producto = I.FK_Producto;
    END
END;
GO

-- TRIGGERS DE SEGURIDAD

CREATE TRIGGER tr_PrevenirBorradoClienteConVentas
ON Cliente
INSTEAD OF DELETE
AS
BEGIN
    -- Evita eliminar clientes que tengan historial de ventas
    IF EXISTS (
        SELECT 1 
        FROM Venta V 
        INNER JOIN deleted d 
            ON V.FK_Cliente = d.PK_Cliente
    )
    BEGIN
        RAISERROR ('No se puede eliminar el cliente porque tiene un historial de ventas.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM Cliente 
        WHERE PK_Cliente IN (SELECT PK_Cliente FROM deleted);
    END
END;
GO

USE ProyectoFerreteria;
GO

-- ===================================================================
-- 						Script Prueba TRIGGERS
-- ===================================================================

PRINT 'Inicio Prueba TRIGGERS';
PRINT '---------------------------------------------------';

-- 0. Se limpian pruebaas anteriores 
DELETE FROM Devolucion WHERE FK_Venta = 888;
DELETE FROM DetalleVenta WHERE FK_Venta = 888;
DELETE FROM Venta WHERE PK_Venta = 888;

-- 1. preparacion stock
UPDATE Inventario 
SET Cantidad = 100 
WHERE FK_Producto = 1 AND FK_Sucursal = 1;

PRINT 'PRUEBA 1 & 2: Venta y Validación de Stock';
SELECT 'Stock Inicial' AS Estado, Cantidad FROM Inventario WHERE FK_Producto = 1 AND FK_Sucursal = 1;

-- Venta exitosa
INSERT INTO Venta (PK_Venta, Fecha, FK_Cliente, FK_Empleado, FK_Sucursal) 
VALUES (888, GETDATE(), 1, 1, 1);

INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) 
VALUES (888, 1, 10, 1500.00);

SELECT 'Stock Post-Venta (10 unidades)' AS Estado, Cantidad FROM Inventario WHERE FK_Producto = 1 AND FK_Sucursal = 1;

-- Validación de Stock (Debe fallar con el RAISERROR del trigger)
PRINT 'Intentando vender 500 unidades (Debe fallar):';
BEGIN TRY
    INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) 
    VALUES (888, 1, 500, 1500.00);
END TRY
BEGIN CATCH
    PRINT 'MENSAJE CAPTURADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '---------------------------------------------------';
PRINT 'PRUEBA 3: Devoluciones';

INSERT INTO Devolucion (FK_Venta, FK_Producto, Cantidad, Motivo, FK_Empleado)
VALUES (888, 1, 5, 'Prueba de retorno de stock', 1);

SELECT 'Stock Post-Devolución (5 unidades)' AS Estado, Cantidad FROM Inventario WHERE FK_Producto = 1 AND FK_Sucursal = 1;
GO

PRINT '---------------------------------------------------';
PRINT 'PRUEBA 4: Auditoría de Precios';


IF EXISTS (SELECT * FROM sys.columns WHERE Name = 'PrecioVenta' AND Object_ID = OBJECT_ID('Producto'))
BEGIN
    UPDATE Producto SET PrecioVenta = PrecioVenta + 5.00 WHERE PK_Producto = 1;
    
    SELECT TOP 1 'Último Movimiento' AS Log, Motivo, Fecha 
    FROM MovimientoInventario 
    ORDER BY PK_Movimiento DESC;
END
ELSE
BEGIN
    PRINT 'La columna se llama distinto. Intenta con Precio o PrecioVenta.';
END
GO

PRINT '---------------------------------------------------';
PRINT 'PRUEBA 5: Protección de Clientes';

PRINT 'Intentando borrar cliente con ventas (Debe fallar):';
BEGIN TRY
    DELETE FROM Cliente WHERE PK_Cliente = 1;
END TRY
BEGIN CATCH
    PRINT 'MENSAJE CAPTURADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '---------------------------------------------------';
PRINT 'PRUEBAS FINALIZADAS.';




/* ===================================================
Select: Tablas De Catálogo
 ========================================================*/

Select * From Sucursal;
Select * From CategoriaProducto;
Select * From Rol;
Select * From TipoMovimiento;


-- Select: Tablas Maestras

Select * From Cliente;
Select * From Empleado;
Select * From Usuario;
Select * From Proveedor;
Select * From Producto;


-- Select: Tablas Relacionales

Select * From ProductoProveedor;
Select * From Inventario;


-- Select: Movimientos

Select * From MovimientoInventario;


-- Select: Ventas

Select * From Venta;
Select * From DetalleVenta;


-- Select: Devoluciones

Select * From Devolucion;
