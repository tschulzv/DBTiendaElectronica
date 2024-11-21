USE DBTienda;
select * from detalle_compras;
select * from compras;

-- PRUEBAS DE TRIGGERS
-----------------------------------------------------------------------
-- CREAR UNA NUEVA COMPRA 
INSERT INTO Compras
VALUES (10, 3, '2024-11-20', 'Crédito', '2024-12-20', 2, 0, 0);

-- INSERT Nuevo detalle
-- Compra de 3 unidades de Teclado Mecanico
INSERT INTO Detalle_Compras
VALUES (10, 10, 3, 3, 350000, 5);

-- UPDATE: Actualizar costo unitario
UPDATE Detalle_Compras
SET costo_unitario = 360000
WHERE id_detalle = 10;

--UPDATE: actualizar id_producto
UPDATE Detalle_Compras
SET id_producto = 2
WHERE id_detalle = 10;

select * from compras;
select * from Proveedores;
select * from Detalle_Compras;
select * from stock;
select * from Productos;


-- DELETE: Borrar el detalle
delete from Detalle_Compras
where id_detalle = 10;

select * from compras;
select * from Proveedores;
select * from stock;


-- DETALLES DE PAGOS ------------------------------------------
select * from Productos;
SELECT * FROM Pagos;
SELECT * FROM Detalles_Pagos;
SELECT * FROM Proveedores;
SELECT * FROM Compras;
SELECT * FROM Stock;

-- INSERT: Insertar un millón al pago 1
INSERT INTO Detalles_Pagos 
VALUES (10, 1, 1, 1000000);

-- UPDATE: Actualizar a 500.000
UPDATE Detalles_Pagos
SET importe_pagado = 500000
WHERE id_detalle_pago = 10;

-- UPDATE: Actualizar a compra con id 9
UPDATE Detalles_Pagos
SET id_compra = 9
WHERE id_detalle_pago = 10;

SELECT * FROM Proveedores;
SELECT * FROM Compras;

-- DELETE: Borrar el detalle
DELETE FROM Detalles_Pagos
WHERE id_detalle_pago = 10;

-- DETALLES DE TRANSFERENCIAS ---------------------------------

-- INSERT 
SELECT * FROM Transferencias_Productos; 
SELECT * FROM Detalles_Transferencia;
SELECT * FROM view_stock_productos
ORDER BY Producto, Deposito;

-- INSERT FALLIDO (Stock negativo)
-- Transferencia de 1 Laptop HP 
INSERT INTO Detalles_Transferencia 
VALUES (4, 1, 1, 2);

-- INSERT EXITOSO
-- Transferencia de 1 Monitor Dell
INSERT INTO Detalles_Transferencia 
VALUES (4, 1, 2, 1);

-- UPDATE DE LA CANTIDAD (FALLIDO)
-- Modificar a 4 Laptops 
UPDATE Detalles_Transferencia
SET cantidad = 4
WHERE id_detalle_transferencia = 4;

-- UPDATE DE LA CANTIDAD (EXITOSO)
-- Modificar a 2 Laptops 
UPDATE Detalles_Transferencia
SET cantidad = 2
WHERE id_detalle_transferencia = 4;

-- UPDATE DEL PRODUCTO (FALLIDO)
-- Modificar a Laptop HP 
UPDATE Detalles_Transferencia
SET id_producto = 1
WHERE id_detalle_transferencia = 4;

-- UPDATE DEL PRODUCTO (EXITOSO)
-- Modificar a Teclado Lenovo 
UPDATE Detalles_Transferencia
SET id_producto = 3
WHERE id_detalle_transferencia = 4;

-- DELETE: BORRAR EL DETALLE
DELETE FROM Detalles_Transferencia
WHERE id_detalle_transferencia = 4;

SELECT * FROM Transferencias_Productos; 
SELECT * FROM Detalles_Transferencia;
SELECT * FROM view_stock_productos
ORDER BY Producto, Deposito;
