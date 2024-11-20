USE DBTienda;

-- PROCEDIMIENTOS
-- PROVEEDOR ------------------------------------------------------------
-- Agregar un Proveedor
EXEC sp_ManageProveedor
	@accion = 'A', -- 'A' para alta, 'M' para modificación, 'B' para baja
    @nombre = 'Compusoft',
	@id_proveedor = 11,
    @direccion = 'Juan Leon Mallorquin',
    @telefono = '+595992111111',
    @correo_electronico = 'compu@gmail.com',
    @linea_credito = 10000000,
	@saldo = 0;

SELECT * FROM Proveedores;

-- MODIFICAR EL PROVEEDOR RECIÉN CREADO
EXEC sp_ManageProveedor
	@accion = 'M', --  'M' para modificación
    @nombre = 'Compusoft S.R.L',
	@id_proveedor = 11,
	@linea_credito = 30000000

SELECT * FROM Proveedores;

-- BORRAR EL PROVEEDOR RECIÉN CREADO
EXEC sp_ManageProveedor
	@accion = 'B', --  'B' para dar de baja
	@id_proveedor = 11

SELECT * FROM Proveedores;

-- PAGO -----------------------------------------------------------