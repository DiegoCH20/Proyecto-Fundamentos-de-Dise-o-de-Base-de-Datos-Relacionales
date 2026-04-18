CREATE TRIGGER tr_ActualizarStockPorVenta
ON DetalleVenta
AFTER INSERT
AS
BEGIN
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
    IF EXISTS (
        SELECT 1
        FROM inserted ins
        INNER JOIN Venta V ON ins.FK_Venta = V.PK_Venta
        INNER JOIN Inventario I ON ins.FK_Producto = I.FK_Producto AND V.FK_Sucursal = I.FK_Sucursal
        WHERE I.Cantidad < ins.Cantidad
    )
    BEGIN
        RAISERROR ('Error: No hay suficiente stock en esta sucursal.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO DetalleVenta (FK_Venta, FK_Producto, Cantidad, PrecioUnitario)
        SELECT FK_Venta, FK_Producto, Cantidad, PrecioUnitario FROM inserted;
    END
END;
GO

CREATE TRIGGER tr_DevolucionAjusteStock
ON Devolucion
AFTER INSERT
AS
BEGIN
    UPDATE I
    SET I.Cantidad = I.Cantidad + ins.Cantidad
    FROM Inventario I
    INNER JOIN inserted ins ON I.FK_Producto = ins.FK_Producto
    INNER JOIN Venta V ON ins.FK_Venta = V.PK_Venta
    WHERE I.FK_Sucursal = V.FK_Sucursal;
END;
GO

CREATE TRIGGER tr_AuditoriaPrecios
ON Producto
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Precio)
    BEGIN
        INSERT INTO MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, Fecha)
        SELECT 
            I.PK_Inventario, 
            4, -- ID para 'Ajuste/Cambio'
            0, 
            'Cambio de precio detectado para el producto', 
            GETDATE()
        FROM inserted ins
        INNER JOIN Inventario I ON ins.PK_Producto = I.FK_Producto;
    END
END;
GO

CREATE TRIGGER tr_AuditoriaPrecios
ON Producto
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Precio)
    BEGIN
        INSERT INTO MovimientoInventario (FK_Inventario, FK_TipoMovimiento, Cantidad, Motivo, Fecha)
        SELECT 
            I.PK_Inventario, 
            4, -- ID para 'Ajuste/Cambio'
            0, 
            'Cambio de precio detectado para el producto', 
            GETDATE()
        FROM inserted ins
        INNER JOIN Inventario I ON ins.PK_Producto = I.FK_Producto;
    END
END;
GO

CREATE TRIGGER tr_PrevenirBorradoClienteConVentas
ON Cliente
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Venta V 
        INNER JOIN deleted d ON V.FK_Cliente = d.PK_Cliente
    )
    BEGIN
        RAISERROR ('No se puede eliminar el cliente porque tiene un historial de ventas.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM Cliente WHERE PK_Cliente IN (SELECT PK_Cliente FROM deleted);
    END
END;
GO
