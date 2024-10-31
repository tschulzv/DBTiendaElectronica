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
select * from Stock;
--select * from Transferencias_Productos;
select * from Detalles_Transferencia;

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





