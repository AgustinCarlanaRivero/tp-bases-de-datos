USE GD1C2025

-- Decision de disenio: NO TENDRAN IDENTITY Sucursal, Sillon_Codigo ni Sillon_Modelo (pq van dando saltos)

-- Materiales
CREATE TABLE DATA_DEALERS.Material(
    Material_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
    Material_Nombre NVARCHAR(255) NOT NULL,
    Material_Tipo NVARCHAR(255) NOT NULL CHECK (Material_Tipo IN ('Madera', 'Relleno', 'Tela')),
    Material_Precio DECIMAL(38, 2) NOT NULL CHECK (Material_Precio > 0), -- Justificacion de Diseño: Precios y Cantidades > 0
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
    Sillon_Modelo_Precio DECIMAL(18,2) NOT NULL CHECK (Sillon_Modelo_Precio > 0)
)

CREATE TABLE DATA_DEALERS.Sillon_Medida(
    Sillon_Medida_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
    Sillon_Medida_Alto DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Ancho DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Profundidad DECIMAL(18, 2) NOT NULL,
    Sillon_Medida_Precio DECIMAL(18, 2) NOT NULL CHECK (Sillon_Medida_Precio > 0)
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
    Provincia_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
    Provincia_Nombre NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Localidad(
    Localidad_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
    Localidad_Nombre NVARCHAR(255) NOT NULL,
    Provincia_Codigo BIGINT REFERENCES DATA_DEALERS.Provincia NOT NULL
)

CREATE TABLE DATA_DEALERS.Direccion(
    Direccion_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
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
    Cliente_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
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
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY IDENTITY(56771553, 1),
    Pedido_Sucursal BIGINT NOT NULL REFERENCES DATA_DEALERS.Sucursal,
    Pedido_Cliente BIGINT NOT NULL REFERENCES DATA_DEALERS.Cliente,
    Pedido_Estado NVARCHAR(255) NOT NULL CHECK (Pedido_Estado IN ('ENTREGADO', 'CANCELADO', 'PENDIENTE')),
    Pedido_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Pedido_Total DECIMAL(18,2) NOT NULL -- Trigger
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
    Detalle_Pedido_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Pedido_Precio > 0),
    Detalle_Pedido_Cantidad BIGINT NOT NULL CHECK (Detalle_Pedido_Cantidad > 0),
    Detalle_Pedido_Subtotal AS (Detalle_Pedido_Precio * Detalle_Pedido_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Pedido_Numero, Pedido_Numero)
)

-- Facturas

CREATE TABLE DATA_DEALERS.Factura(
    Factura_Numero BIGINT PRIMARY KEY IDENTITY(78694631, 1),
    Factura_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Factura_Cliente BIGINT REFERENCES DATA_DEALERS.Cliente NOT NULL,
    Factura_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Factura_Total DECIMAL(38,2) NOT NULL -- Trigger
)

CREATE TABLE DATA_DEALERS.Detalle_Factura(
    Factura_Numero BIGINT REFERENCES DATA_DEALERS.Factura,
    Detalle_Factura_Numero BIGINT,
    Pedido_Numero DECIMAL(18, 0) NOT NULL,
    Detalle_Factura_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Factura_Precio > 0),
    Detalle_Factura_Cantidad DECIMAL(18, 0) NOT NULL CHECK (Detalle_Factura_Cantidad > 0),
    Detalle_Factura_Subtotal AS (Detalle_Factura_Precio * Detalle_Factura_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Factura_Numero, Factura_Numero),
    FOREIGN KEY (Detalle_Factura_Numero, Pedido_Numero) REFERENCES DATA_DEALERS.Detalle_Pedido
)

CREATE TABLE DATA_DEALERS.Envio(
    Envio_Numero DECIMAL(18,0) PRIMARY KEY IDENTITY(45613002,1),
    Envio_Factura BIGINT REFERENCES DATA_DEALERS.Factura NOT NULL,
    Envio_ImporteTraslado DECIMAL(18,2) NOT NULL CHECK (Envio_ImporteTraslado > 0),
    Envio_ImporteSubida DECIMAL(18,2) DEFAULT 0  CHECK (Envio_ImporteSubida > 0), -- Decision de diseño el default 0
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

CREATE TABLE DATA_DEALERS.Compra( -- Consulta (asi como esta, podes crear compra sin detalles, igual que pedido, y analogo a silones sin material_por_sillon)
    Compra_Numero DECIMAL(18, 0) PRIMARY KEY IDENTITY(81264239, 1), 
    Compra_Proveedor NVARCHAR(255) REFERENCES DATA_DEALERS.Proveedor NOT NULL,
    Compra_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Compra_Fecha DATETIME2(6) DEFAULT SYSDATETIME(), -- Decision de Diseño
    Compra_Total DECIMAL(18, 2) NOT NULL -- Trigger
)

CREATE TABLE DATA_DEALERS.Detalle_Compra(
    Detalle_Compra_Codigo BIGINT,
    Compra_Numero DECIMAL(18, 0) REFERENCES DATA_DEALERS.Compra,
    Detalle_Compra_Material BIGINT REFERENCES DATA_DEALERS.Material NOT NULL,
    Detalle_Compra_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Compra_Precio > 0),
    Detalle_Compra_Cantidad DECIMAL(18, 0) NOT NULL CHECK (Detalle_Compra_Cantidad > 0),
    Detalle_Compra_Subtotal AS (Detalle_Compra_Precio * Detalle_Compra_Cantidad) PERSISTED,
    PRIMARY KEY (Detalle_Compra_Codigo, Compra_Numero)
)
GO

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
GO

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
GO

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
GO

CREATE TRIGGER Verificar_Material_Por_Sillon -- Decision de disenio los materiales se ponen los 3 a la vez
ON DATA_DEALERS.Material_Por_Sillon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DATA_DEALERS.Material_Por_Sillon
        GROUP BY Sillon_Codigo
        HAVING COUNT(*) <> 3
    )
    BEGIN
        THROW 50000, 'Error: Cada sillon debe tener unicamente 3 materiales.', 1
    END
    
    IF EXISTS (
        SELECT 1
        FROM DATA_DEALERS.Material_Por_Sillon mps
        JOIN DATA_DEALERS.Material mat ON mps.Material_Codigo = mat.Material_Codigo
        GROUP BY mps.Sillon_Codigo
        HAVING COUNT(DISTINCT mat.Material_Tipo) <> COUNT(*)
    )
    BEGIN
        THROW 50001, 'Error: Los materiales de cada sillon deben ser de tipos distintos: Madera, Tela y Relleno.', 1;
    END
END 
GO

--------------------------------- MIGRACION ---------------------------------


--------- PROCEDURES ---------


-- Materiales
CREATE PROCEDURE DATA_DEALERS.migrate_material
AS BEGIN
    INSERT DATA_DEALERS.Material (Material_Nombre, Material_Tipo, Material_Precio, Material_Descripcion)
    SELECT DISTINCT 
        Material_Nombre, 
        Material_Tipo, 
        Material_Precio, 
        Material_Descripcion
    FROM gd_esquema.Maestra
    WHERE Material_Nombre IS NOT NULL
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_tela
AS
BEGIN
    INSERT INTO DATA_DEALERS.Tela (Material_Codigo, Tela_Color, Tela_Textura)
    SELECT DISTINCT
        mat.Material_Codigo,
        m.Tela_Color, 
        m.Tela_Textura
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre -- Justificacion de disenio: En la tabla maestra, no hay 2 materiales de mismo nombre y distintas caracteristicas
    WHERE m.Tela_Color IS NOT NULL -- Justificacion de Disenio: Si uno es NULL, el otro tmb
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_madera
AS
BEGIN
    INSERT INTO DATA_DEALERS.Madera (Material_Codigo, Madera_Color, Madera_Dureza)
    SELECT DISTINCT
        mat.Material_Codigo, 
        m.Madera_Color, 
        m.Madera_Dureza
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre
    WHERE m.Madera_Color IS NOT NULL
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_relleno
AS
BEGIN
    INSERT INTO DATA_DEALERS.Relleno (Material_Codigo, Relleno_Densidad)
    SELECT DISTINCT 
        mat.Material_Codigo, 
        m.Relleno_Densidad
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre
    WHERE m.Relleno_Densidad IS NOT NULL 
END
GO

-- Sillones
CREATE PROCEDURE DATA_DEALERS.migrate_sillon_modelo
AS
BEGIN
    INSERT INTO DATA_DEALERS.Sillon_Modelo (Sillon_Modelo_Codigo, Sillon_Modelo, Sillon_Modelo_Descripcion, Sillon_Modelo_Precio)
    SELECT DISTINCT 
        Sillon_Modelo_Codigo,
        Sillon_Modelo, 
        Sillon_Modelo_Descripcion, 
        Sillon_Modelo_Precio
    FROM gd_esquema.Maestra
    WHERE Sillon_Modelo_Codigo IS NOT NULL
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_sillon_medida
AS
BEGIN
    INSERT INTO DATA_DEALERS.Sillon_Medida (Sillon_Medida_Alto, Sillon_Medida_Ancho, Sillon_Medida_Profundidad, Sillon_Medida_Precio)
    SELECT DISTINCT 
        Sillon_Medida_Alto, 
        Sillon_Medida_Ancho, 
        Sillon_Medida_Profundidad, 
        Sillon_Medida_Precio
    FROM gd_esquema.Maestra
    WHERE Sillon_Medida_Alto IS NOT NULL
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_sillon
AS
BEGIN
    INSERT INTO DATA_DEALERS.Sillon (Sillon_Codigo, Sillon_Modelo, Sillon_Medida)
    SELECT DISTINCT 
        m.Sillon_Codigo, 
        m.Sillon_Modelo_Codigo, 
        med.Sillon_Medida_Codigo
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Sillon_Medida med ON med.Sillon_Medida_Alto = m.Sillon_Medida_Alto 
        AND med.Sillon_Medida_Ancho = m.Sillon_Medida_Ancho 
        AND med.Sillon_Medida_Profundidad = m.Sillon_Medida_Profundidad
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_material_por_sillon
AS
BEGIN
    INSERT INTO DATA_DEALERS.Material_Por_Sillon (Sillon_Codigo, Material_Codigo)
    SELECT DISTINCT 
        m.Sillon_Codigo, 
        mat.Material_Codigo
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre
    WHERE m.Sillon_Codigo IS NOT NULL AND mat.Material_Codigo IS NOT NULL
END
GO

-- Ubicacion

CREATE PROCEDURE DATA_DEALERS.migrate_provincia
AS
BEGIN
    INSERT INTO DATA_DEALERS.Provincia (Provincia_Nombre)
    SELECT DISTINCT 
        Cliente_Provincia -- Decision de disenio: Los clientes tienen todas las provincias
    FROM gd_esquema.Maestra 
    WHERE Cliente_Provincia IS NOT NULL 
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_localidad 
AS
BEGIN
    INSERT INTO DATA_DEALERS.Localidad (Localidad_Nombre, Provincia_Codigo)
    SELECT DISTINCT 
        l.Localidad_Nombre,
        p.Provincia_Codigo
    FROM (
        SELECT 
            Cliente_Localidad Localidad_Nombre, 
            Cliente_Provincia Provincia_Nombre
        FROM gd_esquema.Maestra 
        WHERE 
            Cliente_Localidad IS NOT NULL 
            AND Cliente_Provincia IS NOT NULL
        UNION
        SELECT 
            Sucursal_Localidad Localidad_Nombre, 
            Sucursal_Provincia Provincia_Nombre
        FROM gd_esquema.Maestra 
        WHERE 
            Sucursal_Localidad IS NOT NULL 
            AND Sucursal_Provincia IS NOT NULL
        UNION
        SELECT 
            Proveedor_Localidad Localidad_Nombre, 
            Proveedor_Provincia Provincia_Nombre
        FROM gd_esquema.Maestra 
        WHERE 
            Proveedor_Localidad IS NOT NULL 
            AND Proveedor_Provincia IS NOT NULL
    ) AS l
        JOIN DATA_DEALERS.Provincia p ON p.Provincia_Nombre = l.Provincia_Nombre
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_direccion AS
BEGIN
    INSERT INTO DATA_DEALERS.Direccion (Direccion_Nombre, Localidad_Codigo)
    SELECT DISTINCT 
        d.Direccion_Nombre,
        l.Localidad_Codigo
    FROM (
        SELECT 
            Cliente_Direccion Direccion_Nombre, 
            Cliente_Localidad Localidad_Nombre
        FROM gd_esquema.Maestra 
        WHERE Cliente_Direccion IS NOT NULL AND Cliente_Localidad IS NOT NULL
        
        UNION
        
        SELECT 
            Sucursal_Direccion Direccion_Nombre, 
            Sucursal_Localidad Localidad_Nombre
        FROM gd_esquema.Maestra 
        WHERE Sucursal_Direccion IS NOT NULL AND Sucursal_Localidad IS NOT NULL

        UNION
        
        SELECT 
            Proveedor_Direccion Direccion_Nombre, 
            Proveedor_Localidad Localidad_Nombre
        FROM gd_esquema.Maestra 
        WHERE Proveedor_Direccion IS NOT NULL AND Proveedor_Localidad IS NOT NULL
    ) AS d
        JOIN DATA_DEALERS.Localidad l ON l.Localidad_Nombre = d.Localidad_Nombre
END
GO

-- Sucursal
CREATE PROCEDURE DATA_DEALERS.migrate_sucursal
AS
BEGIN
    INSERT INTO DATA_DEALERS.Sucursal (Sucursal_NroSucursal, Sucursal_Direccion, Sucursal_Mail, Sucursal_telefono)
    SELECT DISTINCT 
        m.Sucursal_NroSucursal, 
        d.Direccion_Codigo, 
        m.Sucursal_Mail, 
        m.Sucursal_telefono
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Provincia p ON m.Sucursal_Provincia = p.Provincia_Nombre
        JOIN DATA_DEALERS.Localidad l ON m.Sucursal_Localidad = l.Localidad_Nombre AND p.Provincia_Codigo = l.Provincia_Codigo 
        JOIN DATA_DEALERS.Direccion d ON m.Sucursal_Direccion = d.Direccion_Nombre AND l.Localidad_Codigo = d.Localidad_Codigo
    WHERE m.Sucursal_NroSucursal IS NOT NULL
END
GO

-- Cliente
/*CREATE PROCEDURE DATA_DEALERS.migrate_cliente
AS
BEGIN
    INSERT INTO DATA_DEALERS.Cliente (Cliente_Direccion, Cliente_Dni, Cliente_Nombre, Cliente_Apellido, Cliente_FechaNacimiento, Cliente_mail, Cliente_telefono)
    SELECT DISTINCT 
        Cliente_Direccion, 
        Cliente_Dni, 
        Cliente_Nombre, 
        Cliente_Apellido, 
        Cliente_FechaNacimiento, 
        Cliente_mail, 
        Cliente_telefono
    FROM gd_esquema.Maestra
END
GO*/

CREATE PROCEDURE DATA_DEALERS.migrate_cliente
AS
BEGIN
    INSERT INTO DATA_DEALERS.Cliente (Cliente_Direccion, Cliente_Dni, Cliente_Nombre, Cliente_Apellido, Cliente_FechaNacimiento, Cliente_mail, Cliente_telefono)
    SELECT DISTINCT 
        d.Direccion_Codigo, 
        m.Cliente_Dni, 
        m.Cliente_Nombre, 
        m.Cliente_Apellido, 
        m.Cliente_FechaNacimiento, 
        m.Cliente_mail, 
        m.Cliente_telefono
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Direccion d ON m.Cliente_Direccion = d.Direccion_Codigo
    --NOT NULL?
END
GO

-- Pedidos
/*CREATE PROCEDURE DATA_DEALERS.migrate_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Pedido (Pedido_Sucursal, Pedido_Cliente, Pedido_Estado, Pedido_Fecha, Pedido_Total)
    SELECT DISTINCT 
        Pedido_Sucursal, 
        Pedido_Cliente, 
        Pedido_Estado, 
        Pedido_Fecha, 
        Pedido_Total
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_pedido_cancelacion
AS
BEGIN
    INSERT INTO DATA_DEALERS.Pedido_Cancelacion (Pedido_Numero, Pedido_Cancelacion_Fecha, Pedido_Cancelacion_Motivo)
    SELECT DISTINCT 
        Pedido_Numero, 
        Pedido_Cancelacion_Fecha, 
        Pedido_Cancelacion_Motivo
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Pedido (Detalle_Pedido_Numero, Pedido_Numero, Detalle_Sillon, Detalle_Pedido_Precio, Detalle_Pedido_Cantidad)
    SELECT DISTINCT 
        Detalle_Pedido_Numero, 
        Pedido_Numero, 
        Detalle_Sillon, 
        Detalle_Pedido_Precio, 
        Detalle_Pedido_Cantidad
    FROM gd_esquema.Maestra
END 
GO*/

CREATE PROCEDURE DATA_DEALERS.migrate_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Pedido (Pedido_Sucursal, Pedido_Cliente, Pedido_Estado, Pedido_Fecha, Pedido_Total)
    SELECT DISTINCT 
        s.Sucursal_NroSucursal, 
        c.Cliente_Id, 
        m.Pedido_Estado, 
        m.Pedido_Fecha, 
        m.Pedido_Total
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Sucursal s ON m.Pedido_Sucursal = s.Sucursal_NroSucursal
        JOIN DATA_DEALERS.Cliente c ON m.Pedido_Cliente = c.Cliente_Id
    --NOT NULL?
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_pedido_cancelacion
AS
BEGIN
    INSERT INTO DATA_DEALERS.Pedido_Cancelacion (Pedido_Numero, Pedido_Cancelacion_Fecha, Pedido_Cancelacion_Motivo)
    SELECT DISTINCT 
        p.Pedido_Numero, 
        m.Pedido_Cancelacion_Fecha, 
        m.Pedido_Cancelacion_Motivo
    FROM gd_esquema.Maestra
        JOIN DATA_DEALERS.Pedido p ON m.Pedido_Numero = p.Pedido_Numero
    --NOT NULL?
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Pedido (Detalle_Pedido_Numero, Pedido_Numero, Detalle_Sillon, Detalle_Pedido_Precio, Detalle_Pedido_Cantidad)
    SELECT DISTINCT 
        Detalle_Pedido_Numero, 
        Pedido_Numero, 
        Detalle_Sillon, 
        Detalle_Pedido_Precio, 
        Detalle_Pedido_Cantidad
    FROM gd_esquema.Maestra
END 
GO

-- Facturas
/*CREATE PROCEDURE DATA_DEALERS.migrate_factura
AS
BEGIN
    INSERT INTO DATA_DEALERS.Factura (Factura_Sucursal, Factura_Cliente, Factura_Fecha, Factura_Total)
    SELECT DISTINCT 
        Factura_Sucursal, 
        Factura_Cliente, 
        Factura_Fecha, 
        Factura_Total
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_factura
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Factura (Factura_Numero, Detalle_Factura_Numero, Pedido_Numero, Detalle_Factura_Precio, Detalle_Factura_Cantidad)
    SELECT DISTINCT 
        Factura_Numero, 
        Detalle_Factura_Numero, 
        Pedido_Numero, 
        Detalle_Factura_Precio, 
        Detalle_Factura_Cantidad
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_envio
AS
BEGIN
    INSERT INTO DATA_DEALERS.Envio (Envio_Numero, Envio_Factura, Envio_ImporteTraslado, Envio_ImporteSubida, Envio_Fecha_Programada, Envio_Fecha_Entrega)
    SELECT DISTINCT 
        Envio_Numero, 
        Envio_Factura, 
        Envio_ImporteTraslado, 
        Envio_ImporteSubida, 
        Envio_Fecha_Programada, 
        Envio_Fecha_Entrega
    FROM gd_esquema.Maestra
END 
GO*/
CREATE PROCEDURE DATA_DEALERS.migrate_factura
AS
BEGIN
    INSERT INTO DATA_DEALERS.Factura (Factura_Numero, Factura_Sucursal, Factura_Cliente, Factura_Fecha, Factura_Total)
    SELECT DISTINCT 
        s.Sucursal_NroSucursal,
        c.Cliente_Id,
        m.Factura_Numero
        m.Factura_Fecha, 
        m.Factura_Total
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Sucursal s ON s.Sucursal_NroSucursal = m.Factura_Sucursal
        JOIN DATA_DEALERS.Cliente c ON c.Cliente_Id = m.Factura_Cliente
    WHERE m.Factura_Numero IS NOT NULL
END 
GO


-- Compras
CREATE PROCEDURE DATA_DEALERS.migrate_proveedor
AS
BEGIN
    INSERT INTO DATA_DEALERS.Proveedor (Proveedor_Cuit, Proveedor_Direccion, Proveedor_RazonSocial, Proveedor_Telefono, Proveedor_Mail)
    SELECT DISTINCT 
        Proveedor_Cuit, 
        Proveedor_Direccion, 
        Proveedor_RazonSocial, 
        Proveedor_Telefono, 
        Proveedor_Mail
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_compra
AS
BEGIN
    INSERT INTO DATA_DEALERS.Compra (Compra_Proveedor, Compra_Sucursal, Compra_Fecha, Compra_Total)
    SELECT DISTINCT 
        Compra_Proveedor, 
        Compra_Sucursal, 
        Compra_Fecha, 
        Compra_Total
    FROM gd_esquema.Maestra
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_compra
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Compra (Detalle_Compra_Codigo, Compra_Numero, Detalle_Compra_Material, Detalle_Compra_Precio, Detalle_Compra_Cantidad)
    SELECT DISTINCT 
        Detalle_Compra_Codigo, 
        Compra_Numero, 
        Detalle_Compra_Material, 
        Detalle_Compra_Precio, 
        Detalle_Compra_Cantidad
    FROM gd_esquema.Maestra
END 
GO

--------- EXECUTES ---------

-- Materiales
EXEC DATA_DEALERS.migrate_material
EXEC DATA_DEALERS.migrate_tela
EXEC DATA_DEALERS.migrate_madera
EXEC DATA_DEALERS.migrate_relleno

-- Sillones
EXEC DATA_DEALERS.migrate_sillon_modelo
EXEC DATA_DEALERS.migrate_sillon_medida
EXEC DATA_DEALERS.migrate_sillon
EXEC DATA_DEALERS.migrate_material_por_sillon

-- Ubicacion
EXEC DATA_DEALERS.migrate_provincia
EXEC DATA_DEALERS.migrate_localidad
EXEC DATA_DEALERS.migrate_direccion

-- Sucursal
EXEC DATA_DEALERS.migrate_sucursal

-- Cliente
EXEC DATA_DEALERS.migrate_cliente

-- Pedidos
EXEC DATA_DEALERS.migrate_pedido
EXEC DATA_DEALERS.migrate_pedido_cancelacion
EXEC DATA_DEALERS.migrate_detalle_pedido

-- Facturas
EXEC DATA_DEALERS.migrate_factura
EXEC DATA_DEALERS.migrate_detalle_factura
EXEC DATA_DEALERS.migrate_envio

-- Compras
EXEC DATA_DEALERS.migrate_proveedor
EXEC DATA_DEALERS.migrate_compra
EXEC DATA_DEALERS.migrate_detalle_compra

--------- DELETES ---------

DELETE DATA_DEALERS.material
DELETE DATA_DEALERS.tela
DELETE DATA_DEALERS.madera
DELETE DATA_DEALERS.relleno
DELETE DATA_DEALERS.sillon_modelo
DELETE DATA_DEALERS.sillon_medida
DELETE DATA_DEALERS.sillon
DELETE DATA_DEALERS.material_por_sillon
DELETE DATA_DEALERS.migrate_provincia
DELETE DATA_DEALERS.migrate_localidad
DELETE DATA_DEALERS.migrate_direccion
DELETE DATA_DEALERS.migrate_sucursal

--------- IDENT_RESET ---------

DBCC CHECKIDENT ('DATA_DEALERS.Material', RESEED, -1);
DBCC CHECKIDENT ('DATA_DEALERS.sillon_medida', RESEED, -1);
DBCC CHECKIDENT ('DATA_DEALERS.Provincia', RESEED, -1);
DBCC CHECKIDENT ('DATA_DEALERS.Localidad', RESEED, -1);
DBCC CHECKIDENT ('DATA_DEALERS.Direccion', RESEED, -1);