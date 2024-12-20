
USE TiendaElectronica;

/*
-- para probando insert
INSERT INTO Detalles_Transferencia VALUES (
4, 1, 1, 2);

-- probando update
UPDATE Detalles_Transferencia
SET id_producto = 2
WHERE id_detalle_transferencia = 4;

DELETE FROM Detalles_Transferencia
WHERE id_detalle_transferencia = 4;

*/
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

CREATE TRIGGER tbu_detalles_transferencia
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

/** ------------------------------------------------------------
PAGOS A PROVEEDORES
**/

Select * from Pagos;
select * from Detalles_Pagos;
select * from Compras;
select * from Proveedores;

-- INSERT 

/* PROBAR 
insert into Detalles_Pagos 
VALUES (10, 1, 1, 1000000);

delete from detalles_pagos
where id_detalle_pago = 10;

update Detalles_Pagos
set importe_pagado = 1500000
where id_detalle_pago = 10;
*/

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
		WHERE id_proveedor = @id_proveedor;
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
	INNER JOIN deleted i ON i.id_pago = p.id_pago;

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
		WHERE id_proveedor = @id_proveedor;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 1;
	END CATCH

END;

GO

-- UPDATE
CREATE TRIGGER tub_detalles_pagos
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
	SET @id_compra_viejo = (SELECT id_compra FROM deleted);

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
			WHERE id_proveedor = @id_proveedor;
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
go
--Triggers Detalle_Compra
-- INSERT
CREATE TRIGGER tia_Detalle_Compras
ON Detalle_Compras
AFTER INSERT
AS
BEGIN
	DECLARE @id_compra INT;
    DECLARE @id_proveedor INT;
    DECLARE @id_producto INT;
    DECLARE @cantidad NUMERIC(6);
    DECLARE @costo_unitario NUMERIC(9);
    DECLARE @id_deposito INT;
    DECLARE @subtotal NUMERIC(12, 2);
	DECLARE @ult_costo_unitario NUMERIC(9);

	-- Obtener valores del registro insertado
    SELECT 
        @id_compra = i.id_compra,
        @id_proveedor = c.id_proveedor,
        @id_producto = i.id_producto,
        @cantidad = i.cantidad,
        @costo_unitario = i.costo_unitario
    FROM inserted i
    JOIN Compras c ON i.id_compra = c.id_compra;

	-- obtener el subtotal
	SET @subtotal = @cantidad * @costo_unitario;

	-- obtener ult precio unitario
	SELECT @ult_costo_unitario = p.ultimo_costo_unitario
    FROM Productos p
    WHERE p.id_producto = @id_producto;
	
	  -- Obtener id_deposito desde Compras
    SELECT @id_deposito = c.id_deposito
    FROM Compras c
    WHERE c.id_compra = @id_compra;
	
	-- verificar que el saldo del proveedor no exceda la linea de credito
	IF EXISTS (
        SELECT 1
        FROM Proveedores p
        WHERE p.id_proveedor = @id_proveedor
        AND (p.saldo + @subtotal) > p.linea_credito
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50006, 'El saldo no puede superar la línea de crédito asignada al proveedor', 1;
        RETURN;
    END;

	-- aumentar el total de la cabecera
	BEGIN TRY 
		UPDATE Compras
		SET total_compra = total_compra + @subtotal
		WHERE id_compra = @id_compra
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50003, 'No se pudo actualizar el monto', 1;
	END CATCH
	
	-- aumentar el stock del deposito
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad + @cantidad,
			ultima_actualizacion = CAST(GETDATE() AS DATE)
		WHERE id_producto = @id_producto AND id_deposito = @id_deposito;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH

	-- cambiar el últ precio unitario si es necesario
	IF @costo_unitario <> @ult_costo_unitario
	BEGIN 
		BEGIN TRY
			UPDATE Productos
			SET ultimo_costo_unitario = @costo_unitario
			WHERE id_producto = @id_producto;
		END TRY
		BEGIN CATCH 
			ROLLBACK TRANSACTION;
			THROW 50005, 'No se pudo actualizar el producto', 2;
		END CATCH
	END

	-- aumentar el saldo del proveedor y de la compra
	BEGIN TRY
		UPDATE Compras
		SET saldo_compra = saldo_compra + @subtotal
		WHERE id_compra = @id_compra;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 2;
	END CATCH

	-- aumentar el saldo de la compra
	BEGIN TRY
		UPDATE Proveedores
		SET saldo = saldo + @subtotal
		WHERE id_proveedor = @id_proveedor;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 2;
	END CATCH
END;
 
GO
--UPDATE
-- solo anda para update costo y update id producto

CREATE TRIGGER tau_Detalle_Compras
ON Detalle_Compras
AFTER UPDATE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar la cabecera de la compra: total_compra y saldo_compra
        UPDATE Compras
        SET total_compra = (
            SELECT SUM(cantidad * costo_unitario)
            FROM Detalle_Compras
            WHERE Detalle_Compras.id_compra = Compras.id_compra
        ),
        saldo_compra = (
            SELECT SUM(cantidad * costo_unitario)
            FROM Detalle_Compras
            WHERE Detalle_Compras.id_compra = Compras.id_compra
        )
        FROM Compras
        INNER JOIN inserted i ON Compras.id_compra = i.id_compra;

        -- Actualizar el ultimo_costo_unitario si el costo_unitario ha cambiado
        UPDATE Productos
        SET ultimo_costo_unitario = i.costo_unitario
        FROM Productos p
        INNER JOIN inserted i ON p.id_producto = i.id_producto
        WHERE i.costo_unitario <> p.ultimo_costo_unitario;

        -- Detectar si el id_producto ha cambiado
        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON i.id_detalle = d.id_detalle
            WHERE i.id_producto <> d.id_producto
        )
        BEGIN
            -- Caso: Cambio de id_producto

            -- Reducir el stock del producto anterior
            UPDATE Stock
            SET Stock.cantidad = Stock.cantidad - d.cantidad
            FROM Stock
            INNER JOIN deleted d ON Stock.id_producto = d.id_producto
            INNER JOIN Compras c ON d.id_compra = c.id_compra
            WHERE Stock.id_deposito = c.id_deposito;

            -- Incrementar el stock del nuevo producto
            UPDATE Stock
            SET Stock.cantidad = Stock.cantidad + i.cantidad
            FROM Stock
            INNER JOIN inserted i ON Stock.id_producto = i.id_producto
            INNER JOIN Compras c ON i.id_compra = c.id_compra
            WHERE Stock.id_deposito = c.id_deposito;
        END
        ELSE
        BEGIN
            -- Caso: No hubo cambio de id_producto, solo se actualiza costo

            UPDATE Stock
            SET Stock.cantidad = Stock.cantidad + (i.cantidad - d.cantidad)
            FROM Stock
            INNER JOIN inserted i ON Stock.id_producto = i.id_producto
            INNER JOIN deleted d ON i.id_detalle = d.id_detalle
            INNER JOIN Compras c ON i.id_compra = c.id_compra
            WHERE Stock.id_deposito = c.id_deposito;
        END;

        -- Calcular la diferencia en el saldo del proveedor
        UPDATE Proveedores
        SET saldo = saldo + (
            SELECT SUM((i.cantidad * i.costo_unitario) - (d.cantidad * d.costo_unitario))
            FROM inserted i
            INNER JOIN deleted d ON i.id_detalle = d.id_detalle
            INNER JOIN Compras c ON i.id_compra = c.id_compra
            WHERE Proveedores.id_proveedor = c.id_proveedor
        )
        FROM Proveedores
        INNER JOIN inserted i ON Proveedores.id_proveedor = (
            SELECT c.id_proveedor
            FROM Compras c
            WHERE c.id_compra = i.id_compra
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        THROW 50010, 'Error al actualizar el detalle de la compra y sus dependencias.', 1;
    END CATCH
END;
GO
-- DELETE
CREATE TRIGGER tda_Detalle_Compras
ON Detalle_Compras
AFTER DELETE
AS
BEGIN

	DECLARE @id_compra INT;
    DECLARE @id_proveedor INT;
    DECLARE @id_producto INT;
    DECLARE @cantidad NUMERIC(6);
    DECLARE @costo_unitario NUMERIC(9);
    DECLARE @id_deposito INT;
    DECLARE @subtotal NUMERIC(12, 2);
	DECLARE @ult_costo_unitario NUMERIC(9);

	-- Obtener valores del registro borrado
     SELECT 
        @id_compra = d.id_compra,
        @id_proveedor = c.id_proveedor,
		@id_deposito = c.id_deposito,
        @id_producto = d.id_producto,
        @cantidad = d.cantidad,
        @costo_unitario = d.costo_unitario
    FROM deleted d
    JOIN Compras c ON d.id_compra = c.id_compra;

	-- obtener el subtotal
	SET @subtotal = @cantidad * @costo_unitario;

	-- descontar el total de la cabecera
	BEGIN TRY 
		UPDATE Compras
		SET total_compra = total_compra - @subtotal
		WHERE id_compra = @id_compra
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50003, 'No se pudo actualizar el monto', 1;
	END CATCH
	
	-- disminuir el stock del deposito
	BEGIN TRY
		UPDATE Stock
		SET cantidad = cantidad - @cantidad,
			ultima_actualizacion = CAST(GETDATE() AS DATE)
		WHERE id_producto = @id_producto AND id_deposito = @id_deposito;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50002, 'No se pudo actualizar el stock', 2;
	END CATCH

	-- descontar el saldo del proveedor 
	BEGIN TRY
		UPDATE Compras
		SET saldo_compra = saldo_compra - @subtotal
		WHERE id_compra = @id_compra;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 2;
	END CATCH

	-- descontar el saldo de la compra
	BEGIN TRY
		UPDATE Proveedores
		SET saldo = saldo - @subtotal
		WHERE id_proveedor = @id_proveedor;
	END TRY
	BEGIN CATCH 
		ROLLBACK TRANSACTION;
		THROW 50004, 'No se pudo actualizar el saldo', 2;
	END CATCH
END;
