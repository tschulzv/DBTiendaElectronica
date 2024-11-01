/*
1. detalles_transferencia sobre venteos inserrt delet y update
  actualizar stock: restar para deposito irigen y sumar para deposito destino

(2. stock control si es menor a 0 como un trigger sobre el update)

(3. linea de credito de los proveedores : sobre la tabla de compras , sila compra es a credito validar )

4. compras
trigger actualizar cabecera de compras, el total de la factura y tbn actualizar el stock
los 3 eventos

5. pagos de proveedores 
los  3 eventos



*/

USE TiendaElectronica;


-- probando insert
INSERT INTO Detalles_Transferencia VALUES (
4, 1, 1, 2);

-- probando update
UPDATE Detalles_Transferencia
SET id_producto = 2
WHERE id_detalle_transferencia = 4;

DELETE FROM Detalles_Transferencia
WHERE id_detalle_transferencia = 4;

USE TiendaElectronica;
GO

-- TRIGGERS PARA DETALLES_TRANSFERENCIA ------------------------------------------
-- INSERT

CREATE TRIGGER tia_detalles_transferencia
ON Detalles_Transferencia
AFTER INSERT
AS
BEGIN 
	DECLARE @depo_origen INT;
	DECLARE @depo_destino INT;
	DECLARE @stock_origen NUMERIC(6);
	DECLARE @stock_destino NUMERIC(6);
	DECLARE @cantidad NUMERIC(6);
	DECLARE @id_producto INT;

	-- inicializar variables produtco y cantidad
	SET @cantidad = (SELECT cantidad FROM inserted);
	SET @id_producto = (SELECT id_producto FROM inserted);

	-- recuperar depositos origen y destino de la cabecera
	SELECT @depo_origen = id_deposito_origen, @depo_destino = id_deposito_destino
	FROM Transferencias_Productos t
	INNER JOIN inserted i ON i.id_transferencia = t.id_transferencia;

	-- recuperar cantidad actual en deposito de origen
	SELECT @stock_origen = st.cantidad
	FROM Stock st
	WHERE st.id_producto = @id_producto
	  AND id_deposito = @depo_origen;

	-- validar la cantidad 
	IF @cantidad > @stock_origen 
	BEGIN
		ROLLBACK TRANSACTION;
		THROW 50001, 'La cantidad solicitada excede el stock', 1;
	END;

	-- actualizar el stock del deposito de origen
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad - @cantidad,
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto AND id_deposito = @depo_origen;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

	-- actualizar el stock del deposito de destino
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad + @cantidad,
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto AND id_deposito = @depo_destino;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

END;

GO

-- DELETE

CREATE TRIGGER tid_detalles_transferencia
ON Detalles_Transferencia
AFTER DELETE
AS
BEGIN 
	DECLARE @depo_origen INT;
	DECLARE @depo_destino INT;
	DECLARE @stock_origen NUMERIC(6);
	DECLARE @stock_destino NUMERIC(6);
	DECLARE @cantidad NUMERIC(6);
	DECLARE @id_producto INT;

	-- inicializar variables produtco y cantidad
	SET @cantidad = (SELECT cantidad FROM deleted);
	SET @id_producto = (SELECT id_producto FROM deleted);

	-- recuperar depositos origen y destino de la cabecera
	SELECT @depo_origen = id_deposito_origen, @depo_destino = id_deposito_destino
	FROM Transferencias_Productos t
	INNER JOIN deleted i ON i.id_transferencia = t.id_transferencia;

	-- recuperar cantidad actual en deposito de origen
	SELECT @stock_origen = st.cantidad
	FROM Stock st
	WHERE st.id_producto = @id_producto
	  AND id_deposito = @depo_origen;

	-- actualizar el stock del deposito de origen
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad + @cantidad,
		--  no se como hacer para volver a la fecha anterior :( -------------------
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto AND id_deposito = @depo_origen;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

	-- actualizar el stock del deposito de destino
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad - @cantidad,
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto AND id_deposito = @depo_destino;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

END;

GO

CREATE TRIGGER tiu_detalles_transferencia
ON Detalles_Transferencia
AFTER UPDATE
AS
BEGIN 
    DECLARE @depo_origen INT;
    DECLARE @depo_destino INT;
    DECLARE @stock_origen NUMERIC(6);
    DECLARE @stock_destino NUMERIC(6);
    DECLARE @cantidad_nueva NUMERIC(6);
    DECLARE @cantidad_vieja NUMERIC(6);
    DECLARE @id_producto_nuevo INT;
    DECLARE @id_producto_viejo INT;

    -- obtener los valores de cantidad e id_producto
    SELECT @cantidad_nueva = i.cantidad, 
           @cantidad_vieja = d.cantidad,
           @id_producto_nuevo = i.id_producto,
           @id_producto_viejo = d.id_producto
    FROM inserted i
    INNER JOIN deleted d ON i.id_transferencia = d.id_transferencia;

    -- recuperar depósitos de origen y destino desde Transferencias_Productos
    SELECT @depo_origen = t.id_deposito_origen, 
           @depo_destino = t.id_deposito_destino
    FROM Transferencias_Productos t
    INNER JOIN inserted i ON i.id_transferencia = t.id_transferencia;

    -- recuperar la cantidad actual en el depósito de origen
    SELECT @stock_origen = st.cantidad
    FROM Stock st
    WHERE st.id_producto = @id_producto_viejo
      AND st.id_deposito = @depo_origen;

    -- codigo para actualizar cantidad
    IF UPDATE(cantidad)
    BEGIN
        -- Verificar que la nueva cantidad no exceda el stock
        IF @cantidad_nueva > @stock_origen
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50001, 'La cantidad solicitada excede el stock', 1;
        END;

        -- actualizar el stock del depósito de origen
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad + @cantidad_vieja - @cantidad_nueva,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_origen;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock en el depósito de origen', 2;
        END CATCH;

        -- Actualizar el stock del depósito de destino
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad - @cantidad_vieja + @cantidad_nueva,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_destino;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock en el depósito de destino', 2;
        END CATCH;
    END;

    -- codigo para actualizar el producto
    IF UPDATE(id_producto)
    BEGIN
        -- actualizar el stock del producto viejo en el depósito de origen
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad + @cantidad_vieja,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_origen;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock para el producto viejo en el depósito de origen', 2;
        END CATCH;

        -- actualizar el stock del producto viejo en el depósito de destino
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad - @cantidad_vieja,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_destino;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock para el producto viejo en el depósito de destino', 2;
        END CATCH;

        -- validar el stock disponible para el nuevo producto en el depósito de origen
        SELECT @stock_origen = cantidad
        FROM Stock
        WHERE id_producto = @id_producto_nuevo AND id_deposito = @depo_origen;

        IF @cantidad_nueva > @stock_origen
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50001, 'La cantidad solicitada excede el stock para el nuevo producto', 1;
        END;

        -- actualizar el stock del nuevo producto en el depósito de origen
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad - @cantidad_nueva,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_nuevo AND id_deposito = @depo_origen;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock para el nuevo producto en el depósito de origen', 2;
        END CATCH;

        -- actualizar el stock del nuevo producto en el depósito de destino
        BEGIN TRY
            UPDATE Stock
            SET cantidad = cantidad + @cantidad_nueva,
                ultima_actualizacion = GETDATE()
            WHERE id_producto = @id_producto_nuevo AND id_deposito = @depo_destino;
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW 50002, 'No se pudo actualizar el stock para el nuevo producto en el depósito de destino', 2;
        END CATCH;
    END;
END;

/** 
PAGOS A PROVEEDORES
**/

Select * from Pagos;
select * from Detalles_Pagos;
select * from Compras;
select * from Proveedores;
-- INSERT 

GO

CREATE TRIGGER tia_detalle_pago
ON Detalles_Pagos
AFTER INSERT
AS
BEGIN 
	DECLARE @id_pago INT;
	DECLARE @id_compra INT;
	DECLARE @id_proveedor INT;
	DECLARE @id_detalle_forma_pago INT;
	DECLARE @importe NUMERIC(12);

	-- inicializar variables con valores del detalle
	SET @importe= (SELECT importe_pagado FROM inserted);
	SET @id_pago = (SELECT id_pago FROM inserted);
	SET @id_compra = (SELECT id_compra FROM inserted);

	-- recuperar proveedor e importe actual de la cabecera
	SELECT @id_proveedor = P.id_proveedor
	FROM Pagos p
	INNER JOIN inserted i ON i.id_pago = p.id_pago;

	-- sumar al importe actual el nuevo importe insertado
	BEGIN TRY 
		UPDATE Pagos 
		SET importe_total = importe_total + @importe
		WHERE id_pago = @id_pago;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50003, 'No se pudo actualizar el monto', 1;
	END CATCH

	-- modificar el saldo en la tabla compra
	BEGIN TRY 
		UPDATE Compras
		SET saldo_compra = saldo_compra - @importe
		WHERE id_compra = @id_compra;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 1;
	END CATCH

	-- modificar el saldo en la tabla proveedores
	BEGIN TRY
		UPDATE Proveedores 
		SET saldo = saldo - @importe
		WHERE @id_proveedor = @id_proveedor;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 1;
	END CATCH

END;

GO

-- DELETE
CREATE TRIGGER tda_detalle_pago
ON Detalles_Pagos
AFTER DELETE
AS 
BEGIN 
	DECLARE @id_pago INT;
	DECLARE @id_compra INT;
	DECLARE @id_proveedor INT;
	DECLARE @id_detalle_forma_pago INT;
	DECLARE @importe NUMERIC(12);

	-- inicializar variables con valores del detalle
	SET @importe= (SELECT importe_pagado FROM deleted);
	SET @id_pago = (SELECT id_pago FROM deleted);
	SET @id_compra = (SELECT id_compra FROM deleted);

	-- recuperar proveedor e importe actual de la cabecera
	SELECT @id_proveedor = P.id_proveedor
	FROM Pagos p
	INNER JOIN inserted i ON i.id_pago = p.id_pago;

	-- restar al importe actual el importe del detalle borrado
	BEGIN TRY 
		UPDATE Pagos 
		SET importe_total = importe_total - @importe
		WHERE id_pago = @id_pago;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50003, 'No se pudo actualizar el monto', 1;
	END CATCH

	-- modificar el saldo en la tabla compra
	BEGIN TRY 
		UPDATE Compras
		SET saldo_compra = saldo_compra + @importe
		WHERE id_compra = @id_compra;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 1;
	END CATCH

	-- modificar el saldo en la tabla proveedores
	BEGIN TRY
		UPDATE Proveedores 
		SET saldo = saldo + @importe
		WHERE @id_proveedor = @id_proveedor;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 1;
	END CATCH

END;

GO

-- UPDATE
CREATE TRIGGER tiu_detalles_pagos
ON Detalles_Pagos
AFTER UPDATE
AS 
BEGIN
DECLARE @id_pago INT;
	DECLARE @id_compra_nuevo INT;
	DECLARE @id_compra_viejo INT;
	DECLARE @id_proveedor INT;
	DECLARE @id_detalle_forma_pago INT;
	DECLARE @importe_nuevo NUMERIC(12);
	DECLARE @importe_viejo NUMERIC(12);

	-- inicializar variables con valores del detalle
	SET @importe_nuevo= (SELECT importe_pagado FROM inserted);
	SET @importe_viejo= (SELECT importe_pagado FROM deleted);
	SET @id_pago = (SELECT id_pago FROM inserted);
	SET @id_compra_nuevo = (SELECT id_compra FROM inserted);
	SET @id_compra_viejo = (SELECT id_compra FROM inserted);

	-- recuperar proveedor e importe actual de la cabecera
	SELECT @id_proveedor = P.id_proveedor
	FROM Pagos p
	INNER JOIN inserted i ON i.id_pago = p.id_pago;

	-- si se actualiza el monto
	IF UPDATE(importe_pagado)
	BEGIN
		-- actualizar el importe de la cabecera
		BEGIN TRY 
			UPDATE Pagos
			SET importe_total = importe_total - @importe_viejo + @importe_nuevo
			WHERE id_pago = @id_pago;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50003, 'No se pudo actualizar el monto', 1;
		END CATCH

		-- actualizar el saldo de la compra
		BEGIN TRY 
			UPDATE Compras
			SET saldo_compra = saldo_compra + @importe_viejo - @importe_nuevo
			WHERE id_compra = @id_compra_nuevo;
		END TRY
		BEGIN CATCH 
			ROLLBACK TRANSACTION;
			THROW 50004, 'No se pudo actualizar el saldo', 1;
		END CATCH

		-- modificar el saldo en la tabla proveedores
		BEGIN TRY
			UPDATE Proveedores 
			SET saldo = saldo + @importe_viejo - @importe_nuevo
			WHERE @id_proveedor = @id_proveedor;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50004, 'No se pudo actualizar el saldo', 1;
		END CATCH
	END

		-- si se actualiza el id_compra
	IF UPDATE(id_compra)
	BEGIN

		-- volver a aumentar el saldo a la compra anterior
		BEGIN TRY 
			UPDATE Compras
			SET saldo_compra = saldo_compra + @importe_nuevo
			WHERE id_compra = @id_compra_viejo;
		END TRY
		BEGIN CATCH 
			ROLLBACK TRANSACTION;
			THROW 50004, 'No se pudo actualizar el saldo', 1;
		END CATCH

		-- descontar el saldo de la nueva compra
		BEGIN TRY 
			UPDATE Compras
			SET saldo_compra = saldo_compra - @importe_nuevo
			WHERE id_compra = @id_compra_nuevo;
		END TRY
		BEGIN CATCH 
			ROLLBACK TRANSACTION;
			THROW 50004, 'No se pudo actualizar el saldo', 1;
		END CATCH
	END

	
END;