/*==============================================================
  DESARROLLO DE FUNCIONES DEFINIDAS POR EL USUARIO
  Descripción:
  Script que crea funciones deterministas para cálculos de 
  subtotal, impuesto, total, descuento y aumento de precios 
  en el sistema de ferretería.
==============================================================*/

-------------Calcular total sin impuesto--------------------------------------
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
----------------Calcular impuesto-----------------------------------
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
----------------Calcula total con impuesto------------------------------------------------------
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
-----------------Calcula impuesto --------------------------------------------------
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
---------------Calcula Aumento-----------------------------------------------------
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
------------------Precio Venta-------------------------------------------------
SELECT 
p.PrecioVenta,
dbo.fn_impuesto(p.PrecioVenta) AS impuesto,
dbo.fn_total(p.PrecioVenta) AS total
FROM Producto p;
----------------Precio Costo----------------------------------------------
SELECT 
p.PrecioCosto,
dbo.fn_impuesto(p.PrecioCosto) AS impuesto,
dbo.fn_total(p.PrecioCosto) AS total
FROM Producto p;