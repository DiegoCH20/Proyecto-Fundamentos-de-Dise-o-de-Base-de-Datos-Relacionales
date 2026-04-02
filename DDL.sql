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