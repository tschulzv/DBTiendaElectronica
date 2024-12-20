-- voa chi pegao nessa a galera da aviao

--Para dar alta/baja/modificación de una tabla simple (proveedores, productos, etc) (1)

------------------ MANAGE PROVEEDOR CON TRY CATCH (no quiero borrar el otro pq me da amsiedad que este al final no ande) ------------------

CREATE PROCEDURE sp_ManageProveedor
    @accion CHAR(1), -- 'A' para alta, 'M' para modificación, 'B' para baja
    @id_proveedor INT = NULL,
    @nombre VARCHAR(50) = NULL OUTPUT,
    @direccion VARCHAR(150) = NULL OUTPUT,
    @telefono VARCHAR(15) = NULL OUTPUT,
    @correo_electronico VARCHAR(100) = NULL OUTPUT,
    @linea_credito NUMERIC(12) = NULL OUTPUT,
    @saldo NUMERIC(12) = NULL OUTPUT
AS
BEGIN
    BEGIN TRY
        IF @accion = 'A'
        BEGIN
            INSERT INTO Proveedores (id_proveedor, nombre, direccion, telefono, correo_electronico, linea_credito, saldo)
            VALUES (@id_proveedor, @nombre, @direccion, @telefono, @correo_electronico, @linea_credito, @saldo);
        END
        ELSE IF @accion = 'M'
        BEGIN
            UPDATE Proveedores
            SET nombre = ISNULL(@nombre, nombre),
                direccion = ISNULL(@direccion, direccion),
                telefono = ISNULL(@telefono, telefono),
                correo_electronico = ISNULL(@correo_electronico, correo_electronico),
                linea_credito = ISNULL(@linea_credito, linea_credito),
		saldo = ISNULL(@saldo, saldo)
            WHERE id_proveedor = @id_proveedor;
        END
        ELSE IF @accion = 'B'
        BEGIN
            DELETE FROM Proveedores
            WHERE id_proveedor = @id_proveedor;
        END
        ELSE
        BEGIN
            THROW 50007, 'Acción no válida. Use ''A'', ''M'' o ''B''.', 1;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Ejemplos de ejecución

EXEC sp_ManageProveedor 
    @accion = 'A', 
	@id_proveedor = 11,
    @nombre = 'Local Prueba',
    @direccion = 'Direccion Prueba',
    @telefono = '1234567890',
    @correo_electronico = 'correo_prueba@gmail.com',
    @linea_credito = 1000000;

EXEC sp_ManageProveedor 
    @accion = 'M', 
	@id_proveedor = 11,
    @telefono = '+595991973864';

EXEC sp_ManageProveedor 
    @accion = 'B', 
    @id_proveedor = 11;

Select * from Proveedores;
GO

--Para dar alta/baja/modificación de una tabla cabecera-detalle (facturas compras u ordenes de pago) (2)



----------------------------- ManagePagos y ManageDetallesPagos -----------------------------

--Para dar alta/baja/modificación de una tabla cabecera-detalle (facturas compras u ordenes de pago) (2)


CREATE PROCEDURE sp_ManagePagos
    @accion CHAR(1), -- 'A' para alta, 'M' para modificación, 'B' para baja
    @id_pago INT = NULL,
    @id_proveedor INT = NULL,
    @fecha DATE = NULL,
    @importe_total NUMERIC(12) = NULL
AS
BEGIN
    IF @accion = 'A'
    BEGIN
        IF EXISTS (SELECT 1 FROM Proveedores WHERE id_proveedor = @id_proveedor)
        BEGIN
            INSERT INTO Pagos (id_pago, id_proveedor, fecha, importe_total)
            VALUES (@id_pago, @id_proveedor, @fecha, @importe_total);
        END
        ELSE
        BEGIN
            RAISERROR ('El id_proveedor especificado no existe en la tabla Proveedores.', 16, 1);
        END
    END
    ELSE IF @accion = 'M'
    BEGIN
        UPDATE Pagos
        SET id_proveedor = ISNULL(@id_proveedor, id_proveedor),
            fecha = ISNULL(@fecha, fecha),
            importe_total = ISNULL(@importe_total, importe_total)
        WHERE id_pago = @id_pago;
    END
    ELSE IF @accion = 'B'
    BEGIN
		-- Elimina los detalles asociados en Detalles_Forma_Pago
		DELETE FROM Detalles_Forma_Pago
        WHERE id_pago = @id_pago;
        -- Elimina los detalles asociados en Detalles_Pagos
        DELETE FROM Detalles_Pagos
        WHERE id_pago = @id_pago;
        -- Elimina el registro en Pagos
        DELETE FROM Pagos
        WHERE id_pago = @id_pago;
    END
END;
GO

CREATE PROCEDURE sp_ManageDetallesPago
    @accion CHAR(1), -- 'A' para alta, 'M' para modificación, 'B' para baja
    @id_detalle_pago INT = NULL,
    @id_pago INT = NULL,
    @id_compra INT = NULL,
    @importe_pagado NUMERIC(12) = NULL
AS
BEGIN
    IF @accion = 'A'
    BEGIN
        IF EXISTS (SELECT 1 FROM Pagos WHERE id_pago = @id_pago) AND 
           EXISTS (SELECT 1 FROM Compras WHERE id_compra = @id_compra)
        BEGIN
            INSERT INTO Detalles_Pagos (id_detalle_pago, id_pago, id_compra, importe_pagado)
            VALUES (@id_detalle_pago, @id_pago, @id_compra, @importe_pagado);
        END
        ELSE
        BEGIN
            RAISERROR ('El id_pago o el id_medio_de_pago especificado no existe.', 16, 1);
        END
    END
    ELSE IF @accion = 'M'
    BEGIN
        UPDATE Detalles_Pagos
        SET id_pago = ISNULL(@id_pago, id_pago),
            id_compra = ISNULL(@id_compra, id_compra),
            importe_pagado = ISNULL(@importe_pagado, importe_pagado)
        WHERE id_detalle_pago = @id_detalle_pago;
    END
    ELSE IF @accion = 'B'
    BEGIN
        DELETE FROM Detalles_Pagos
        WHERE id_detalle_pago = @id_detalle_pago;
    END
END;
GO

---- Ejemplos de ejecución ----
	
EXEC sp_ManagePagos 
    @accion = 'A', 
    @id_pago = 1,
    @id_proveedor = 11,
    @fecha = '2024-10-29',
    @importe_total = 500000;

EXEC sp_ManageDetallesPago 
    @accion = 'B', 
    @id_detalle_pago = 1,
    @id_pago = 1,
    @id_compra = 2,
    @importe_pagado = 200000;

EXEC sp_ManagePagos 
    @accion = 'A', 
    @id_pago = 100,
    @id_proveedor = 10,
    @fecha = '2024-10-29',
    @importe_total = 500000;

EXEC sp_ManageDetallesPago 
    @accion = 'B', 
    @id_detalle_pago = 1;


EXEC sp_ManagePagos
    @accion = 'B', 
    @id_pago = 1;


select * from Detalles_Pagos
select * from pagos

