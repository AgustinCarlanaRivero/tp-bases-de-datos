USE GD1C2025

-- Materiales
CREATE TABLE DATA_DEALERS.Material(
    Material_Codigo BIGINT PRIMARY KEY,
    Material_Nombre NVARCHAR(255) NOT NULL,
    Material_Tipo NVARCHAR(255) NOT NULL CHECK (Material_Tipo IN ('Madera', 'Relleno', 'Tela')),
    Material_Precio DECIMAL(38, 2) NOT NULL,
    Material_Descripcion NVARCHAR(255) -- Justificacion de Diseño
)

CREATE TABLE DATA_DEALERS.Tela(
   Material_Codigo BIGINT PRIMARY KEY REFERENCES DATA_DEALERS.Material,
   Tela_Color NVARCHAR(255) NOT NULL,
   Tela_Textura NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Madera(
    Material_Codigo BIGINT PRIMARY KEY REFERENCES DATA_DEALERS.Material,
    Madera_Color NVARCHAR(255) NOT NULL,
    Madera_Dureza NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Relleno(
    Material_Codigo BIGINT PRIMARY KEY REFERENCES DATA_DEALERS.Material,
    Relleno_Densidad DECIMAL(38, 2) NOT NULL
)

-- Sillones
CREATE TABLE DATA_DEALERS.Sillon_Modelo(
    Sillon_Modelo_Codigo BIGINT PRIMARY KEY,
    Sillon_Modelo NVARCHAR(255) NOT NULL,
    Sillon_Modelo_Descripcion NVARCHAR(255),
    Sillon_Modelo_Precio DECIMAL(18,2) NOT NULL
)

CREATE TABLE DATA_DEALERS.Sillon_Medida(
    Sillon_Medida_Codigo BIGINT PRIMARY KEY,
    Sillon_Medida_Alto DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Ancho DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Profundidad DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Precio DECIMAL(18, 2) NOT NULL
)

CREATE TABLE DATA_DEALERS.Sillon(
    Sillon_Codigo BIGINT PRIMARY KEY,
    Sillon_Modelo BIGINT REFERENCES DATA_DEALERS.Sillon_Modelo NOT NULL, 
    Sillon_Medida BIGINT REFERENCES DATA_DEALERS.Sillon_Medida NOT NULL
)

CREATE TABLE DATA_DEALERS.Material_Por_Sillon(
    Sillon_Codigo BIGINT REFERENCES DATA_DEALERS.Sillon,
    Material_Codigo BIGINT REFERENCES DATA_DEALERS.Material,
    PRIMARY KEY(Sillon_Codigo, Material_Codigo) 
)

-- Ubicacion

CREATE TABLE DATA_DEALERS.Provincia(
    Provincia_Codigo BIGINT PRIMARY KEY,
    Provincia_Nombre NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Localidad(
    Localidad_Codigo BIGINT PRIMARY KEY,
    Localidad_Nombre NVARCHAR(255) NOT NULL,
    Provincia_Codigo BIGINT REFERENCES DATA_DEALERS.Provincia NOT NULL
)

CREATE TABLE DATA_DEALERS.Direccion(
    Direccion_Codigo BIGINT PRIMARY KEY,
    Direccion_Nombre NVARCHAR(255) NOT NULL,
    Localidad_Codigo BIGINT REFERENCES DATA_DEALERS.Localidad NOT NULL
)

-- Sucursal

CREATE TABLE DATA_DEALERS.Sucursal(
    Sucursal_NroSucursal BIGINT PRIMARY KEY,
    Sucursal_Direccion BIGINT REFERENCES DATA_DEALERS.Direccion NOT NULL,
    Sucursal_Mail NVARCHAR(255) NOT NULL, -- Decision de diseño
    Sucursal_telefono NVARCHAR(255) NOT NULL
)

-- Cliente

CREATE TABLE DATA_DEALERS.Cliente(
    Cliente_Id BIGINT PRIMARY KEY,
    Cliente_Direccion BIGINT REFERENCES DATA_DEALERS.Direccion,
    Cliente_Dni BIGINT, -- Decision de Diseño CONSULTAR
    Cliente_Nombre NVARCHAR(255), -- Decision de Diseño
    Cliente_Apellido NVARCHAR(255), -- Decision de Diseño
    Cliente_FechaNacimiento DATETIME2(6), -- Decision de Diseño
    Cliente_mail NVARCHAR(255), -- Decision de Diseño
    Cliente_telefono NVARCHAR(255) -- Decision de Diseño
)

-- Pedidos

CREATE TABLE DATA_DEALERS.Pedido(
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY,
    Pedido_Sucursal BIGINT NOT NULL REFERENCES DATA_DEALERS.Sucursal,
    Pedido_Cliente BIGINT NOT NULL REFERENCES DATA_DEALERS.Cliente,
    Pedido_Estado NVARCHAR(255) NOT NULL CHECK (Pedido_Estado IN ('ENTREGADO', 'CANCELADO', 'PENDIENTE')),
    Pedido_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Pedido_Total BIGINT NOT NULL -- Trigger
)

CREATE TABLE DATA_DEALERS.Pedido_Cancelacion(
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY REFERENCES DATA_DEALERS.Pedido,
    Pedido_Cancelacion_Fecha DATETIME2(6) DEFAULT SYSDATETIME(),
    Pedido_Cancelacion_Motivo VARCHAR(255) DEFAULT 'Sin Motivo' -- Decision de Diseño   
)

CREATE TABLE DATA_DEALERS.Detalle_Pedido(
    Detalle_Pedido_Numero BIGINT,
    Pedido_Numero DECIMAL(18,0) REFERENCES DATA_DEALERS.Pedido,
    Detalle_Sillon BIGINT REFERENCES DATA_DEALERS.Sillon NOT NULL,
    Detalle_Pedido_Precio DECIMAL(18,2) NOT NULL,
    Detalle_Pedido_Cantidad BIGINT NOT NULL,
    Detalle_Pedido_Subtotal AS (Detalle_Pedido_Precio * Detalle_Pedido_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Pedido_Numero, Pedido_Numero)
)

-- Facturas

CREATE TABLE DATA_DEALERS.Factura(
    Factura_Numero BIGINT PRIMARY KEY,
    Factura_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Factura_Cliente BIGINT REFERENCES DATA_DEALERS.Cliente NOT NULL,
    Factura_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Factura_Total DECIMAL(38,2) NOT NULL -- Trigger
)

CREATE TABLE DATA_DEALERS.Detalle_Factura(
    Factura_Numero BIGINT REFERENCES DATA_DEALERS.Factura,
    Detalle_Factura_Numero BIGINT,
    Pedido_Numero DECIMAL(18, 0) NOT NULL,
    Detalle_Factura_Precio DECIMAL(18,2) NOT NULL,
    Detalle_Factura_Cantidad DECIMAL(18, 0) NOT NULL,
    Detalle_Factura_Subtotal AS (Detalle_Factura_Precio * Detalle_Factura_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Factura_Numero, Factura_Numero),
    FOREIGN KEY (Detalle_Factura_Numero, Pedido_Numero) REFERENCES DATA_DEALERS.Detalle_Pedido
)

CREATE TABLE DATA_DEALERS.Envio(
    Envio_Numero DECIMAL(18,2) PRIMARY KEY,
    Envio_Factura BIGINT REFERENCES DATA_DEALERS.Factura NOT NULL,
    Envio_ImporteTraslado DECIMAL(18,2) NOT NULL,
    Envio_ImporteSubida DECIMAL(18,2) DEFAULT 0, -- Decision de diseño
    Envio_Total AS (Envio_ImporteTraslado + Envio_ImporteSubida) PERSISTED, -- CHECK o ALIAS o TRIGGER: CONSULTAR
    Envio_Fecha_Programada DATETIME2(0) NOT NULL,
    Envio_Fecha_Entrega DATETIME2(0) -- Decision de diseño
)

-- Compras
CREATE TABLE DATA_DEALERS.Proveedor(
    Proveedor_Cuit NVARCHAR(255) PRIMARY KEY,
    Proveedor_Direccion BIGINT REFERENCES DATA_DEALERS.Direccion NOT NULL,
    Proveedor_RazonSocial NVARCHAR(255) NOT NULL,
    Proveedor_Telefono NVARCHAR(255) NOT NULL, -- Decision de diseño
    Proveedor_Mail NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Compra( -- Consulta (asi como esta, podes crear compra sin detalles, igual que pedido)
    Compra_Numero DECIMAL(18, 0) PRIMARY KEY,
    Compra_Proveedor NVARCHAR(255) REFERENCES DATA_DEALERS.Proveedor NOT NULL,
    Compra_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Compra_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Compra_Total DECIMAL(18, 2) NOT NULL -- Trigger
)

CREATE TABLE DATA_DEALERS.Detalle_Compra(
    Detalle_Compra_Codigo BIGINT,
    Compra_Numero DECIMAL(18, 0) REFERENCES DATA_DEALERS.Compra,
    Detalle_Compra_Material BIGINT REFERENCES DATA_DEALERS.Material NOT NULL,
    Detalle_Compra_Precio DECIMAL(18,2) NOT NULL,
    Detalle_Compra_Cantidad DECIMAL(18, 0) NOT NULL,
    Detalle_Compra_Subtotal AS (Detalle_Compra_Precio * Detalle_Compra_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Compra_Codigo, Compra_Numero)
)

-- Triggers

CREATE TRIGGER Actualizar_Compra_Total
ON DATA_DEALERS.Detalle_Compra
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE C
    SET Compra_Total = (
        SELECT SUM(Detalle_Compra_Subtotal)
        FROM DATA_DEALERS.Detalle_Compra DC
        WHERE DC.Compra_Numero = C.Compra_Numero
    )
    FROM DATA_DEALERS.Compra C
    WHERE C.Compra_Numero IN (
        SELECT DISTINCT Compra_Numero FROM inserted
        UNION
        SELECT DISTINCT Compra_Numero FROM deleted
    )
END

CREATE TRIGGER Actualizar_Pedido_Total
ON DATA_DEALERS.Detalle_Pedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE P
    SET Pedido_Total = (
        SELECT SUM(Detalle_Pedido_Subtotal)
        FROM DATA_DEALERS.Detalle_Pedido DP
        WHERE DP.Pedido_Numero = P.Pedido_Numero
    )
    FROM DATA_DEALERS.Pedido P
    WHERE P.Pedido_Numero IN (
        SELECT DISTINCT Pedido_Numero FROM inserted
        UNION
        SELECT DISTINCT Pedido_Numero FROM deleted
    )
END

CREATE TRIGGER Actualizar_Factura_Total
ON DATA_DEALERS.Detalle_Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE F
    SET Factura_Total = (
        SELECT SUM(Detalle_Factura_Subtotal) + ISNULL(E.Envio_Total, 0)
        FROM DATA_DEALERS.Detalle_Factura DF
            LEFT JOIN Envio E ON (E.Envio_Factura = F.Factura_Numero)
        WHERE DF.Factura_Numero = F.Factura_Numero
    )
    FROM DATA_DEALERS.Factura F
    WHERE F.Factura_Numero IN (
        SELECT DISTINCT Factura_Numero FROM inserted
        UNION
        SELECT DISTINCT Factura_Numero FROM deleted
    )
END