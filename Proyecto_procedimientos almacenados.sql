--Procedimientos almacenados (STORED PROCEDURES)
--------------------------------------------------------------------

USE ProyectoFerreteria;
GO

-- ELIMINAR PROCEDIMIENTOS SI EXISTEN
--------------------------------------------------------------------

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
--------------------------------------------------------------------

GO
CREATE PROCEDURE sp_InsertarCliente 
    @Nombre NVARCHAR(50),
    @Apellidos NVARCHAR(100),
    @Telefono NVARCHAR(20),
    @Correo NVARCHAR(100),
    @Direccion NVARCHAR(200)
AS
BEGIN
    INSERT INTO Cliente (Nombre, Apellidos, Telefono, Correo, Direccion)-- Inserta un nuevo cliente en la base de datos
    VALUES (@Nombre, @Apellidos, @Telefono, @Correo, @Direccion);
END;
GO

CREATE PROCEDURE sp_ConsultarClientes -- Consulta todos los clientes registrados
AS
BEGIN
    SELECT * FROM Cliente;
END;
GO


-- PROCEDIMIENTOS DE PRODUCTOS
--------------------------------------------------------------------

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
    INSERT INTO Producto  -- Inserta un nuevo producto en el sistema
    (CodigoBarras, Nombre, Descripcion, PrecioVenta, PrecioCosto, StockMinimo, FK_Categoria)
    VALUES
    (@CodigoBarras, @Nombre, @Descripcion, @PrecioVenta, @PrecioCosto, @StockMinimo, @FK_Categoria);
END;
GO

CREATE PROCEDURE sp_ActualizarProducto    -- Actualiza información básica de un producto
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

CREATE PROCEDURE sp_ConsultarProductos -- Consulta productos junto con su categoría
AS
BEGIN
    SELECT P.*, C.Nombre AS Categoria
    FROM Producto P
    INNER JOIN CategoriaProducto C 
        ON P.FK_Categoria = C.PK_Categoria;
END;
GO


-- PROCEDIMIENTO DE INVENTARIO
--------------------------------------------------------------------

CREATE PROCEDURE sp_AjustarInventario 
    @FK_Sucursal INT,
    @FK_Producto INT,
    @Cantidad INT
AS
BEGIN
    UPDATE Inventario  -- Ajusta el inventario sumando o restando cantidad
    SET Cantidad = Cantidad + @Cantidad,
        FechaUltimaActualizacion = GETDATE()
    WHERE FK_Sucursal = @FK_Sucursal
    AND FK_Producto = @FK_Producto;
END;
GO


-- PROCEDIMIENTOS DE VENTAS
--------------------------------------------------------------------

CREATE PROCEDURE sp_CrearVenta     
    @PK_Venta INT,
    @FK_Cliente INT,
    @FK_Empleado INT,
    @FK_Sucursal INT
AS
BEGIN
    INSERT INTO Venta (PK_Venta, Fecha, FK_Cliente, FK_Empleado, FK_Sucursal) -- Registra una nueva venta con fecha actual
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

    SELECT @Precio = PrecioVenta -- Obtener el precio del producto
    FROM Producto
    WHERE PK_Producto = @FK_Producto;

    IF @Precio IS NULL
    BEGIN
        PRINT 'Error: Producto no existe'; -- Validar que el producto exista
        RETURN;
    END

    SELECT @Sucursal = FK_Sucursal  -- Obtener la sucursal asociada a la venta
    FROM Venta
    WHERE PK_Venta = @FK_Venta;

    INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario) -- Insertar el detalle de la venta
    VALUES (@FK_Venta, @FK_Producto, @Cantidad, @Precio);

    UPDATE Inventario -- Actualizar inventario SOLO en la sucursal correspondiente
    SET Cantidad = Cantidad - @Cantidad,
        FechaUltimaActualizacion = GETDATE()
    WHERE FK_Producto = @FK_Producto
    AND FK_Sucursal = @Sucursal;
END;
GO

CREATE PROCEDURE sp_ConsultarVentas -- Consulta ventas con cliente, empleado, sucursal y total
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


-- PROCEDIMIENTO DE DEVOLUCIONES
--------------------------------------------------------------------

CREATE PROCEDURE sp_RegistrarDevolucion 
    @FK_Venta INT,
    @FK_Producto INT,
    @Cantidad INT,
    @Motivo NVARCHAR(200),
    @FK_Empleado INT
AS
BEGIN
    DECLARE @Sucursal INT;

    SELECT @Sucursal = FK_Sucursal  -- Obtener la sucursal de la venta
    FROM Venta
    WHERE PK_Venta = @FK_Venta;

    INSERT INTO Devolucion (FK_Venta, FK_Producto, Cantidad, Motivo, FK_Empleado) -- Registrar devolución
    VALUES (@FK_Venta, @FK_Producto, @Cantidad, @Motivo, @FK_Empleado);

    UPDATE Inventario     -- Devolver productos al inventario
    SET Cantidad = Cantidad + @Cantidad
    WHERE FK_Producto = @FK_Producto
    AND FK_Sucursal = @Sucursal;
END;
GO


-- PROCEDIMIENTO DE REPORTES
--------------------------------------------------------------------
CREATE PROCEDURE sp_ProductosBajoStock  -- Muestra productos con inventario que esten por debajo del mínimo
AS
BEGIN
    SELECT P.*
    FROM Producto P
    INNER JOIN Inventario I 
        ON P.PK_Producto = I.FK_Producto
    WHERE I.Cantidad <= P.StockMinimo;
END;
GO