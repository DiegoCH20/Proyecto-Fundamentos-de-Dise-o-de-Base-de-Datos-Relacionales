-- ============================================================
-- VISTAS (VIEWS) - Base de datos ProyectoFerreteria
-- ============================================================

USE ProyectoFerreteria;
GO

-- ELIMINAR VISTAS SI EXISTEN
--------------------------------------------------------------------

IF OBJECT_ID('vw_ConsultarVentas')         IS NOT NULL DROP VIEW vw_ConsultarVentas;
IF OBJECT_ID('vw_ConsultarProductos')      IS NOT NULL DROP VIEW vw_ConsultarProductos;
IF OBJECT_ID('vw_ConsultarInventario')     IS NOT NULL DROP VIEW vw_ConsultarInventario;
IF OBJECT_ID('vw_ProductosBajoStock')      IS NOT NULL DROP VIEW vw_ProductosBajoStock;
IF OBJECT_ID('vw_ConsultarDevoluciones')   IS NOT NULL DROP VIEW vw_ConsultarDevoluciones;
IF OBJECT_ID('vw_ConsultarEmpleados')      IS NOT NULL DROP VIEW vw_ConsultarEmpleados;
IF OBJECT_ID('vw_ConsultarClientes')       IS NOT NULL DROP VIEW vw_ConsultarClientes;
IF OBJECT_ID('vw_MovimientosInventario')   IS NOT NULL DROP VIEW vw_MovimientosInventario;
IF OBJECT_ID('vw_ResumenVentasPorSucursal') IS NOT NULL DROP VIEW vw_ResumenVentasPorSucursal;
IF OBJECT_ID('vw_ProductosPorProveedor')   IS NOT NULL DROP VIEW vw_ProductosPorProveedor;
GO


-- ============================================================
-- BLOQUE 1: VISTAS DE VENTAS
-- ============================================================

CREATE VIEW vw_ConsultarVentas -- Vista que muestra ventas con cliente, empleado, sucursal y total calculado
AS
    SELECT
        V.PK_Venta                              AS IdVenta,
        C.Nombre + ' ' + C.Apellidos            AS Cliente,
        C.Telefono                              AS TelefonoCliente,
        E.Nombre + ' ' + E.Apellidos            AS Empleado,
        S.Nombre                                AS Sucursal,
        V.Fecha,
        SUM(D.Subtotal)                         AS TotalVenta
    FROM Venta V
    INNER JOIN Cliente     C ON V.FK_Cliente   = C.PK_Cliente
    INNER JOIN Empleado    E ON V.FK_Empleado  = E.PK_Empleado
    INNER JOIN Sucursal    S ON V.FK_Sucursal  = S.PK_Sucursal
    INNER JOIN DetalleVenta D ON V.PK_Venta   = D.FK_Venta
    GROUP BY
        V.PK_Venta, C.Nombre, C.Apellidos, C.Telefono,
        E.Nombre, E.Apellidos, S.Nombre, V.Fecha;
GO

-- ============================================================
-- BLOQUE 2: VISTAS DE PRODUCTOS
-- ============================================================

CREATE VIEW vw_ConsultarProductos -- Vista que muestra productos junto con su categoría
AS
    SELECT
        P.PK_Producto,
        P.CodigoBarras,
        P.Nombre                                AS Producto,
        P.Descripcion,
        P.PrecioVenta,
        P.PrecioCosto,
        P.StockMinimo,
        C.Nombre                                AS Categoria
    FROM Producto P
    INNER JOIN CategoriaProducto C ON P.FK_Categoria = C.PK_Categoria;
GO

CREATE VIEW vw_ProductosBajoStock -- Vista que muestra productos cuyo inventario está por debajo del mínimo
AS
    SELECT
        P.PK_Producto,
        P.CodigoBarras,
        P.Nombre                                AS Producto,
        P.StockMinimo,
        I.Cantidad                              AS StockActual,
        S.Nombre                                AS Sucursal
    FROM Producto P
    INNER JOIN Inventario I  ON P.PK_Producto  = I.FK_Producto
    INNER JOIN Sucursal   S  ON I.FK_Sucursal  = S.PK_Sucursal
    WHERE I.Cantidad <= P.StockMinimo;
GO

CREATE VIEW vw_ProductosPorProveedor -- Vista que muestra productos con su proveedor y condiciones de compra
AS
    SELECT
        P.PK_Producto,
        P.Nombre                                AS Producto,
        PR.Nombre                               AS Proveedor,
        PR.Telefono                             AS TelefonoProveedor,
        PP.PrecioCompra,
        PP.TiempoEntregaDias
    FROM Producto P
    INNER JOIN ProductoProveedor PP ON P.PK_Producto    = PP.FK_Producto
    INNER JOIN Proveedor         PR ON PP.FK_Proveedor  = PR.PK_Proveedor;
GO

-- ============================================================
-- BLOQUE 3: VISTAS DE INVENTARIO
-- ============================================================

CREATE VIEW vw_ConsultarInventario -- Vista que muestra el inventario completo por sucursal y producto
AS
    SELECT
        I.PK_Inventario,
        S.Nombre                                AS Sucursal,
        P.Nombre                                AS Producto,
        P.CodigoBarras,
        I.Cantidad,
        P.StockMinimo,
        I.FechaUltimaActualizacion
    FROM Inventario I
    INNER JOIN Sucursal S  ON I.FK_Sucursal = S.PK_Sucursal
    INNER JOIN Producto P  ON I.FK_Producto = P.PK_Producto;
GO

CREATE VIEW vw_MovimientosInventario -- Vista que muestra los movimientos de inventario con detalle completo
AS
    SELECT
        M.PK_Movimiento,
        S.Nombre                                AS Sucursal,
        P.Nombre                                AS Producto,
        TM.Nombre                               AS TipoMovimiento,
        TM.Signo,
        M.Cantidad,
        M.Fecha,
        M.Motivo,
        U.Username                              AS UsuarioResponsable
    FROM MovimientoInventario M
    INNER JOIN Inventario     I  ON M.FK_Inventario      = I.PK_Inventario
    INNER JOIN Sucursal       S  ON I.FK_Sucursal        = S.PK_Sucursal
    INNER JOIN Producto       P  ON I.FK_Producto        = P.PK_Producto
    INNER JOIN TipoMovimiento TM ON M.FK_TipoMovimiento  = TM.PK_TipoMovimiento
    LEFT  JOIN Usuario        U  ON M.FK_Usuario         = U.PK_Usuario;
GO

-- ============================================================
-- BLOQUE 4: VISTAS DE PERSONAL
-- ============================================================

CREATE VIEW vw_ConsultarEmpleados -- Vista que muestra empleados con su sucursal asignada
AS
    SELECT
        E.PK_Empleado,
        E.Nombre + ' ' + E.Apellidos            AS NombreCompleto,
        E.Telefono,
        E.Correo,
        E.FechaContratacion,
        S.Nombre                                AS Sucursal
    FROM Empleado E
    INNER JOIN Sucursal S ON E.FK_Sucursal = S.PK_Sucursal;
GO

CREATE VIEW vw_ConsultarClientes -- Vista que muestra todos los clientes registrados
AS
    SELECT
        PK_Cliente,
        Nombre + ' ' + Apellidos                AS NombreCompleto,
        Telefono,
        Correo,
        Direccion,
        FechaRegistro
    FROM Cliente;
GO

-- ============================================================
-- BLOQUE 5: VISTAS DE DEVOLUCIONES Y REPORTES
-- ============================================================

CREATE VIEW vw_ConsultarDevoluciones -- Vista que muestra devoluciones con detalle de venta, producto y empleado
AS
    SELECT
        D.PK_Devolucion,
        D.Fecha                                 AS FechaDevolucion,
        V.PK_Venta                              AS IdVenta,
        P.Nombre                                AS Producto,
        D.Cantidad,
        D.Motivo,
        E.Nombre + ' ' + E.Apellidos            AS EmpleadoResponsable
    FROM Devolucion D
    INNER JOIN Venta    V ON D.FK_Venta     = V.PK_Venta
    INNER JOIN Producto P ON D.FK_Producto  = P.PK_Producto
    INNER JOIN Empleado E ON D.FK_Empleado  = E.PK_Empleado;
GO

CREATE VIEW vw_ResumenVentasPorSucursal -- Vista que muestra el resumen de ventas agrupadas por sucursal
AS
    SELECT
        S.Nombre                                AS Sucursal,
        COUNT(DISTINCT V.PK_Venta)              AS TotalVentas,
        SUM(D.Subtotal)                         AS MontoTotal
    FROM Venta V
    INNER JOIN Sucursal     S ON V.FK_Sucursal = S.PK_Sucursal
    INNER JOIN DetalleVenta D ON V.PK_Venta   = D.FK_Venta
    GROUP BY S.Nombre;
GO


-- ============================================================
-- CONSULTAS DE PRUEBA PARA CADA VISTA
-- ============================================================

Select * From vw_ConsultarVentas;
Select * From vw_ConsultarProductos;
Select * From vw_ProductosBajoStock;
Select * From vw_ProductosPorProveedor;
Select * From vw_ConsultarInventario;
Select * From vw_MovimientosInventario;
Select * From vw_ConsultarEmpleados;
Select * From vw_ConsultarClientes;
Select * From vw_ConsultarDevoluciones;
Select * From vw_ResumenVentasPorSucursal;
GO