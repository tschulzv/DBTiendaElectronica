--Para dar alta/baja/modificación de una tabla simple (proveedores, productos, etc) (1)

CREATE PROCEDURE sp_ManageProveedor
    @accion CHAR(1), -- 'A' para alta, 'M' para modificación, 'B' para baja
    @id_proveedor INT = NULL,
    @nombre VARCHAR(50) = NULL OUTPUT,
    @direccion VARCHAR(150) = NULL OUTPUT,
    @telefono VARCHAR(15) = NULL OUTPUT,
    @correo_electronico VARCHAR(100) = NULL OUTPUT,
    @linea_credito NUMERIC(12) = NULL OUTPUT
AS
BEGIN
    IF @accion = 'A'
    BEGIN
        INSERT INTO Proveedores (id_proveedor, nombre, direccion, telefono, correo_electronico, linea_credito)
        VALUES (@id_proveedor, @nombre, @direccion, @telefono, @correo_electronico, @linea_credito);
    END
    ELSE IF @accion = 'M'
    BEGIN
        UPDATE Proveedores
        SET nombre = ISNULL(@nombre, nombre),
            direccion = ISNULL(@direccion, direccion),
            telefono = ISNULL(@telefono, telefono),
            correo_electronico = ISNULL(@correo_electronico, correo_electronico),
            linea_credito = ISNULL(@linea_credito, linea_credito)
        WHERE id_proveedor = @id_proveedor;
    END
    ELSE IF @accion = 'B'
    BEGIN
        DELETE FROM Proveedores
        WHERE id_proveedor = @id_proveedor;
    END
END;

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

CREATE PROCEDURE sp_ManagePagosYDetalles
    @tabla CHAR(1),                 -- 'P' para operaciones en Pagos, 'D' para Detalles_Forma_Pago
    @accion CHAR(1),                -- 'A' para alta, 'M' para modificación, 'B' para baja
    @id_pago INT = NULL,
    @id_proveedor INT = NULL,
    @fecha DATE = NULL,
    @importe_total NUMERIC(12) = NULL,
    @id_detalle_forma_pago INT = NULL,
    @id_medio_de_pago INT = NULL,
    @monto NUMERIC(12) = NULL
AS
BEGIN
    IF @tabla = 'P'
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
            -- Elimina primero los detalles asociados en Detalles_Forma_Pago
            DELETE FROM Detalles_Forma_Pago
            WHERE id_pago = @id_pago;
            -- Elimina el registro en Pagos
            DELETE FROM Pagos
            WHERE id_pago = @id_pago;
        END
    END
    ELSE IF @tabla = 'D'
    BEGIN
        IF @accion = 'A'
        BEGIN
            IF EXISTS (SELECT 1 FROM Pagos WHERE id_pago = @id_pago) AND 
               EXISTS (SELECT 1 FROM Medios_de_Pago WHERE id_medio_de_pago = @id_medio_de_pago)
            BEGIN
                INSERT INTO Detalles_Forma_Pago (id_detalle_forma_pago, id_pago, id_medio_de_pago, monto)
                VALUES (@id_detalle_forma_pago, @id_pago, @id_medio_de_pago, @monto);
            END
            ELSE
            BEGIN
                RAISERROR ('El id_pago o el id_medio_de_pago especificado no existe.', 16, 1);
            END
        END
        ELSE IF @accion = 'M'
        BEGIN
            UPDATE Detalles_Forma_Pago
            SET id_pago = ISNULL(@id_pago, id_pago),
                id_medio_de_pago = ISNULL(@id_medio_de_pago, id_medio_de_pago),
                monto = ISNULL(@monto, monto)
            WHERE id_detalle_forma_pago = @id_detalle_forma_pago;
        END
        ELSE IF @accion = 'B'
        BEGIN
            DELETE FROM Detalles_Forma_Pago
            WHERE id_detalle_forma_pago = @id_detalle_forma_pago;
        END
    END
END;

-- Ejemplos de ejecución

EXEC sp_ManagePagosYDetalles 
    @tabla = 'P', 
    @accion = 'A', 
    @id_pago = 1,
    @id_proveedor = 11,
    @fecha = '2024-10-29',
    @importe_total = 500000;

EXEC sp_ManagePagosYDetalles 
    @tabla = 'D', 
    @accion = 'A', 
    @id_detalle_forma_pago = 1,
    @id_pago = 1,
    @id_medio_de_pago = 2,
    @monto = 200000;
