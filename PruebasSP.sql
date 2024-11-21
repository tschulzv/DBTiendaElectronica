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
--Agregar nuevo pago
EXEC sp_ManagePagos
    @accion = 'A', --Alta
    @id_pago = 10,
    @id_proveedor = 1,
    @fecha = '2024-04-01',
    @importe_total = 1000000;

--Modificar el pago
EXEC sp_ManagePagos
    @accion = 'M', --modificar
    @id_pago = 10,
    @fecha = '2024-04-02', 
    @importe_total = 1200000; 

--Dar de baja un pago
EXEC sp_ManagePagos
    @accion = 'B',--baja
    @id_pago = 10;

SELECT * FROM Pagos
	
-- DATALLES PAGOS -----------------------------------------------------------
--Dar de alta un detallePago
EXEC sp_ManageDetallesPago
    @accion = 'A',--alta
    @id_detalle_pago = 10,
    @id_pago = 1,
    @id_compra = 1,
    @importe_pagado = 500000;
--Modificar un detalle pago
EXEC sp_ManageDetallesPago
    @accion = 'M', --modificar
    @id_detalle_pago = 10,
    @id_compra = 2, 
    @importe_pagado = 600000;
--Dar de Baja un detallePago
EXEC sp_ManageDetallesPago
    @accion = 'B',--baja
    @id_detalle_pago = 10;

SELECT * FROM Detalles_Pagos
