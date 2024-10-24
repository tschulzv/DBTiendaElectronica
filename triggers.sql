/* 
TRIGGERS 
*/
USE TiendaElectronica;
GO

-- !!! FALTA TRIGGER COMPRA
-- AUMENTAR EL SALDO DEL PROVEEDOR

-- Trigger Compra
-- Cuando hay una nueva compra (INSERT Detalle_Compras), se dispara un aumento del stock

CREATE TRIGGER trg_ActualizarStockCompra
ON Detalle_Compras 
AFTER INSERT 
AS 
BEGIN 
	-- si el producto ya existe en ese deposito, se suma al stock 
	IF EXISTS (SELECT * 
	           FROM inserted i 
	           INNER JOIN Stock s ON s.id_producto = i.id_producto
			   INNER JOIN Compras c ON c.id_compra = i.id_compra 
			   WHERE s.id_deposito = c.id_deposito)
	BEGIN
		UPDATE Stock 
		SET Stock.cantidad = Stock.cantidad + i.cantidad
		FROM inserted i 
		INNER JOIN Compras c ON i.id_compra = c.id_compra
		WHERE Stock.id_producto = i.id_producto AND Stock.id_deposito = c.id_deposito; 
	END
	
	ELSE -- si no, se debe crear un nuevo stock
	BEGIN
		-- FALTA AGREGAR EL ID
		INSERT INTO Stock(id_producto, id_deposito, cantidad, ultima_actualizacion)
			SELECT i.id_producto, c.id_deposito, i.cantidad, GETDATE()
			FROM inserted i 
			INNER JOIN Compras c ON i.id_compra = c.id_compra
	END
END;

GO

-- Trigger Pago
-- Cuando se agrega un pago, se descuenta el monto pagado del saldo de la factura y del proveedor
CREATE TRIGGER trg_DescontarSaldo
ON Detalles_Pagos 
AFTER INSERT 
AS 
BEGIN 
	-- actualizar saldo de la factura 
	UPDATE Compras
	SET Compras.saldo_compra = Compras.saldo_compra - i.importe_pagado 
	FROM inserted i 
	WHERE i.id_compra = Compras.id_compra;

	-- actualizar saldo del proveedor
	UPDATE Proveedores
	SET Proveedores.saldo = Proveedores.saldo - i.importe_pagado 
	FROM inserted i 
	INNER JOIN Pagos pa ON i.id_pago = pa.id_pago
	WHERE pa.id_proveedor = Proveedores.id_proveedor;

END;

GO

