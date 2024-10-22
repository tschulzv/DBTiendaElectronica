USE TiendaElectronica;
GO; -- iniciar un nuevo lote
/*
El diseño deberá contener algunas vistas como:
- Facturas de proveedores vencidas (1)
- Stocks de productos. (1)*/
 
-- Algunas declaraciones, como CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, etc., 
-- deben ser las únicas en el lote porque el servidor las trata como operaciones independientes

-- FACTURAS DE PROVEEDORES VENCIDAS
-- Obs. Sólo se seleccionan las VENCIDAS Y PENDIENTES DE PAGO
CREATE VIEW view_facturas_vencidas AS
	SELECT c.id_compra AS "Factura", c.fecha_compra AS "Fecha Compra", c.fecha_vencimiento AS "Fecha Vencimiento", pr.nombre AS "Proveedor",  
		c.total_compra AS "Total", c.saldo_compra AS "Saldo"
	FROM Compras c
	INNER JOIN Proveedores pr ON c.id_proveedor = pr.id_proveedor
	WHERE c.saldo_compra > 0 AND c.fecha_vencimiento < GETDATE();

GO;

-- STOCK DE PRODUCTOS
-- 1. Ver stock de los depósitos por separado
CREATE VIEW stock_productos AS
	SELECT st.id_stock AS "Stock", de.nombre AS "Deposito", pr.descripcion AS "Producto", 
	st.cantidad AS "cantidad", pr.ultimo_costo_unitario AS "Ult. Costo Unitario", st.ultima_actualizacion AS "Ult. Actualizacion"
	FROM Stock st
	INNER JOIN Productos pr ON st.id_producto = pr.id_producto
	INNER JOIN Depositos de ON st.id_deposito = de.id_deposito;

GO;

-- 2. Ver el total del stock de ambos depósitos 
CREATE VIEW stock_total_productos AS
	SELECT pr.descripcion AS "Producto", SUM(st.cantidad) AS "Total Cantidad", pr.ultimo_costo_unitario AS "Ult. Costo Unitario", MAX(st.ultima_actualizacion) AS "Ult. Actualizacion"
	FROM Stock st
	INNER JOIN Productos pr ON st.id_producto = pr.id_producto
	INNER JOIN Depositos de ON st.id_deposito = de.id_deposito
	GROUP BY st.id_producto, pr.descripcion, pr.ultimo_costo_unitario;