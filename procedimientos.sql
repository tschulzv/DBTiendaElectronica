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
