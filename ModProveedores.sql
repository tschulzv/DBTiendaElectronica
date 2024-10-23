/* SCRIPT MODIFICACIÓN DE TABLA PROVEEDORES 
Destinado a hacer cumplir la política de la empresa 
*/

USE TiendaElectronica;

 -- MODIFICACIONES PARA AGREGAR LA COLUMNA 'SALDO' A PROVEEDORES
ALTER TABLE Proveedores
ADD saldo numeric(12);

UPDATE Proveedores
SET saldo = 0
WHERE saldo IS NULL;

ALTER TABLE Proveedores
ALTER COLUMN saldo numeric(12) NOT NULL;

-- CONSTRAINT PARA VERIFICAR QUE EL SALDO NO SUPERE A LA LINEA DE CRÉDITO
ALTER TABLE Proveedores
ADD CONSTRAINT chk_saldo_vs_credito CHECK (saldo <= linea_credito);

-- Agregar los saldos existentes
UPDATE Proveedores
SET saldo = 2500000
WHERE id_proveedor = 1;

UPDATE Proveedores
SET saldo = 900000
WHERE id_proveedor = 5;

UPDATE Proveedores
SET saldo = 10000000
WHERE id_proveedor = 2;