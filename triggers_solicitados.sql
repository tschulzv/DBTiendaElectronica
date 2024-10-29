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

select * from Detalles_Transferencia;
select * from Transferencias_Productos;
select * from stock;
select * from Depositos;

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
	INNER JOIN inserted i ON i.id_transferencia = t.id_transferencia;

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
		-- no se como hacer para volver a la fecha anterior :( -------------------
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto AND id_deposito = @depo_destino;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

END;

GO

-- UPDATE
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

	-- inicializar variables produtco y cantidad
	SET @cantidad_nueva = (SELECT cantidad FROM inserted);
	SET @cantidad_vieja= (SELECT cantidad FROM deleted);
	SET @id_producto_nuevo = (SELECT id_producto FROM inserted);
	SET @id_producto_viejo = (SELECT id_producto FROM deleted);

	-- recuperar depositos origen y destino de la cabecera
	SELECT @depo_origen = id_deposito_origen, @depo_destino = id_deposito_destino
	FROM Transferencias_Productos t
	INNER JOIN inserted i ON i.id_transferencia = t.id_transferencia;

	-- recuperar cantidad actual en deposito de origen
	SELECT @stock_origen = st.cantidad
	FROM Stock st
	WHERE st.id_producto = @id_producto_viejo
	  AND id_deposito = @depo_origen;

	-- codigo cuando se modifica la cantidad
	IF UPDATE(cantidad)
	BEGIN
			-- validar la cantidad 
		IF @cantidad_nueva > @stock_origen
		BEGIN
			ROLLBACK TRANSACTION;
			THROW 50001, 'La cantidad solicitada excede el stock', 1;
		END;

		-- actualizar el stock del deposito de origen
		BEGIN TRY
			UPDATE Stock
			SET cantidad = cantidad + @cantidad_vieja - @cantidad_nueva,
				ultima_actualizacion = CAST(GETDATE() AS DATE) 
			WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_origen;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50002, 'No se pudo actualizar el stock', 2;
		END CATCH;

		-- actualizar el stock del deposito de destino
		BEGIN TRY
			UPDATE Stock
			SET cantidad = cantidad - @cantidad_vieja + @cantidad_nueva,
				ultima_actualizacion = CAST(GETDATE() AS DATE) 
			WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_destino;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50002, 'No se pudo actualizar el stock', 2;
		END CATCH;
	END;

	-- codigo cuando se modifica el producto
	IF UPDATE(id_producto)
	BEGIN
		-- actualizar el stock del producto viejo
		-- actualizar stock del deposito origen
		BEGIN TRY
			UPDATE Stock
			SET cantidad = cantidad + @cantidad_vieja,
			--- modificar para vovler a LA FECHA ANTERIOR----------------------
				ultima_actualizacion = CAST(GETDATE() AS DATE) 
			WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_origen;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50002, 'No se pudo actualizar el stock', 2;
		END CATCH;

		-- actualizar el stock del deposito de destino
		BEGIN TRY
			UPDATE Stock
			SET cantidad = cantidad - @cantidad_vieja,
			--- modificar para vovler a LA FECHA ANTERIOR----------------------
				ultima_actualizacion = CAST(GETDATE() AS DATE) 
			WHERE id_producto = @id_producto_viejo AND id_deposito = @depo_destino;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW 50002, 'No se pudo actualizar el stock', 2;
		END CATCH;
	END;

	-- ACTUALIZAR STOCK DEL NUEVO PRODUCTO
	-- validar la cantidad 
	IF @cantidad_nueva > @stock_origen 
	BEGIN
		ROLLBACK TRANSACTION;
		THROW 50001, 'La cantidad solicitada excede el stock', 1;
	END;

	-- actualizar el stock del deposito de origen
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad - @cantidad_nueva,
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto_nuevo AND id_deposito = @depo_origen;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

	-- actualizar el stock del deposito de destino
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad + @cantidad_nueva,
			ultima_actualizacion = CAST(GETDATE() AS DATE) 
		WHERE id_producto = @id_producto_nuevo AND id_deposito = @depo_destino;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH;

END;
