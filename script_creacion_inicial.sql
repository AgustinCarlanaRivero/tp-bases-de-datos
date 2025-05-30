-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

----------------------------- CREACION DE ESTRUCTURAS -----------------------------

--------- TABLAS ---------

-- Materiales

CREATE TABLE DATA_DEALERS.Material(
    Material_Codigo BIGINT PRIMARY KEY IDENTITY(0, 1),
    Material_Nombre NVARCHAR(255) NOT NULL,
    Material_Tipo NVARCHAR(255) NOT NULL CHECK (Material_Tipo IN ('Madera', 'Relleno', 'Tela')),
    Material_Precio DECIMAL(38, 2) NOT NULL CHECK (Material_Precio > 0),
    Material_Descripcion NVARCHAR(255)
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
    Sucursal_Mail NVARCHAR(255) NOT NULL,
    Sucursal_telefono NVARCHAR(255) NOT NULL
)

-- Cliente

CREATE TABLE DATA_DEALERS.Cliente(
    Cliente_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Cliente_Direccion BIGINT REFERENCES DATA_DEALERS.Direccion,
    Cliente_Dni BIGINT NOT NULL,
    Cliente_Nombre NVARCHAR(255) NOT NULL,
    Cliente_Apellido NVARCHAR(255) NOT NULL,
    Cliente_FechaNacimiento DATETIME2(6) NOT NULL,
    Cliente_mail NVARCHAR(255) NOT NULL,
    Cliente_telefono NVARCHAR(255) NOT NULL
)

-- Pedidos

CREATE TABLE DATA_DEALERS.Pedido(
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY IDENTITY(56360503, 1),
    Pedido_Sucursal BIGINT NOT NULL REFERENCES DATA_DEALERS.Sucursal,
    Pedido_Cliente BIGINT NOT NULL REFERENCES DATA_DEALERS.Cliente,
    Pedido_Estado NVARCHAR(255) NOT NULL CHECK (Pedido_Estado IN ('ENTREGADO', 'CANCELADO', 'PENDIENTE')),
    Pedido_Fecha DATETIME2(6) DEFAULT SYSDATETIME(),
    Pedido_Total DECIMAL(18,2) NOT NULL
)

CREATE TABLE DATA_DEALERS.Pedido_Cancelacion(
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY REFERENCES DATA_DEALERS.Pedido,
    Pedido_Cancelacion_Fecha DATETIME2(6) DEFAULT SYSDATETIME(),
    Pedido_Cancelacion_Motivo VARCHAR(255) DEFAULT 'Sin Motivo'
)

CREATE TABLE DATA_DEALERS.Detalle_Pedido(
    Detalle_Pedido_Numero BIGINT,
    Pedido_Numero DECIMAL(18,0) REFERENCES DATA_DEALERS.Pedido,
    Detalle_Sillon BIGINT REFERENCES DATA_DEALERS.Sillon NOT NULL,
    Detalle_Pedido_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Pedido_Precio > 0),
    Detalle_Pedido_Cantidad BIGINT NOT NULL CHECK (Detalle_Pedido_Cantidad > 0),
    Detalle_Pedido_Subtotal DECIMAL(18,2),
    PRIMARY KEY (Detalle_Pedido_Numero, Pedido_Numero)
)

-- Facturas

CREATE TABLE DATA_DEALERS.Factura(
    Factura_Numero BIGINT PRIMARY KEY IDENTITY(46118858, 1),
    Factura_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Factura_Cliente BIGINT REFERENCES DATA_DEALERS.Cliente NOT NULL,
    Factura_Fecha DATETIME2(6) DEFAULT SYSDATETIME(),
    Factura_Total DECIMAL(38,2) NOT NULL
)

CREATE TABLE DATA_DEALERS.Detalle_Factura(
    Factura_Numero BIGINT REFERENCES DATA_DEALERS.Factura,
    Detalle_Factura_Numero BIGINT,
    Pedido_Numero DECIMAL(18, 0) NOT NULL,
    Detalle_Factura_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Factura_Precio > 0),
    Detalle_Factura_Cantidad DECIMAL(18, 0) NOT NULL CHECK (Detalle_Factura_Cantidad > 0),
    Detalle_Factura_Subtotal DECIMAL(18, 2),
    PRIMARY KEY (Detalle_Factura_Numero, Factura_Numero),
    FOREIGN KEY (Detalle_Factura_Numero, Pedido_Numero) REFERENCES DATA_DEALERS.Detalle_Pedido
)

CREATE TABLE DATA_DEALERS.Envio(
    Envio_Numero DECIMAL(18,0) PRIMARY KEY IDENTITY(90664928,1),
    Envio_Factura BIGINT REFERENCES DATA_DEALERS.Factura NOT NULL,
    Envio_ImporteTraslado DECIMAL(18,2) NOT NULL CHECK (Envio_ImporteTraslado > 0),
    Envio_ImporteSubida DECIMAL(18,2) DEFAULT 0 CHECK (Envio_ImporteSubida > 0),
    Envio_Total DECIMAL(18, 2),
    Envio_Fecha_Programada DATETIME2(0) NOT NULL,
    Envio_Fecha DATETIME2(0)
)

-- Compras

CREATE TABLE DATA_DEALERS.Proveedor(
    Proveedor_Cuit NVARCHAR(255) PRIMARY KEY,
    Proveedor_Direccion BIGINT REFERENCES DATA_DEALERS.Direccion NOT NULL,
    Proveedor_RazonSocial NVARCHAR(255) NOT NULL,
    Proveedor_Telefono NVARCHAR(255) NOT NULL,
    Proveedor_Mail NVARCHAR(255) NOT NULL
)

CREATE TABLE DATA_DEALERS.Compra(
    Compra_Numero DECIMAL(18, 0) PRIMARY KEY IDENTITY(12242153, 1), 
    Compra_Proveedor NVARCHAR(255) REFERENCES DATA_DEALERS.Proveedor NOT NULL,
    Compra_Sucursal BIGINT REFERENCES DATA_DEALERS.Sucursal NOT NULL,
    Compra_Fecha DATETIME2(6) DEFAULT SYSDATETIME(),
    Compra_Total DECIMAL(18, 2) NOT NULL
)

CREATE TABLE DATA_DEALERS.Detalle_Compra(
    Detalle_Compra_Codigo BIGINT,
    Compra_Numero DECIMAL(18, 0) REFERENCES DATA_DEALERS.Compra,
    Detalle_Compra_Material BIGINT REFERENCES DATA_DEALERS.Material NOT NULL,
    Detalle_Compra_Precio DECIMAL(18,2) NOT NULL CHECK (Detalle_Compra_Precio > 0),
    Detalle_Compra_Cantidad DECIMAL(18, 0) NOT NULL CHECK (Detalle_Compra_Cantidad > 0),
    Detalle_Compra_Subtotal DECIMAL(18, 2),
    PRIMARY KEY (Detalle_Compra_Codigo, Compra_Numero)
)
GO

--------- TRIGGERS ---------

-- Asignar un numero incremental al Detalle_Compra_Codigo y calcular subtotal si es que no fue calculado
CREATE TRIGGER Insertar_Detalle_Compra
ON DATA_DEALERS.Detalle_Compra
INSTEAD OF INSERT
AS
BEGIN
    -- Declaracion de variables para almacenar los valores de cada fila a insertar
    DECLARE @Compra_Numero DECIMAL(18,0), @Detalle_Compra_Material BIGINT, @Detalle_Compra_Precio DECIMAL(18,2), @Detalle_Compra_Cantidad DECIMAL(18,0), @Detalle_Compra_Subtotal DECIMAL(18,2), @Detalle_Compra_Codigo BIGINT

    -- Cursor para recorrer todas las filas a insertar
    DECLARE Cursor_Detalle CURSOR FOR
        SELECT 
            i.Compra_Numero,
            i.Detalle_Compra_Material,
            i.Detalle_Compra_Precio,
            i.Detalle_Compra_Cantidad,
            ISNULL(i.Detalle_Compra_Subtotal, i.Detalle_Compra_Precio * i.Detalle_Compra_Cantidad) -- Si el subtotal es NULL, se calcula
        FROM inserted i

    OPEN Cursor_Detalle

    FETCH Cursor_Detalle INTO @Compra_Numero, @Detalle_Compra_Material, @Detalle_Compra_Precio, @Detalle_Compra_Cantidad, @Detalle_Compra_Subtotal

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcula el siguiente numero de detalle para la compra (incremental por compra)
        SELECT @Detalle_Compra_Codigo = COUNT(*) 
        FROM DATA_DEALERS.Detalle_Compra
        WHERE Compra_Numero = @Compra_Numero

        -- Inserta la fila en la tabla con el codigo incremental y el subtotal
        INSERT INTO DATA_DEALERS.Detalle_Compra (Detalle_Compra_Codigo, Compra_Numero, Detalle_Compra_Material, Detalle_Compra_Precio, Detalle_Compra_Cantidad, Detalle_Compra_Subtotal)
        VALUES (@Detalle_Compra_Codigo, @Compra_Numero, @Detalle_Compra_Material, @Detalle_Compra_Precio, @Detalle_Compra_Cantidad, @Detalle_Compra_Subtotal)

        FETCH Cursor_Detalle INTO @Compra_Numero, @Detalle_Compra_Material, @Detalle_Compra_Precio, @Detalle_Compra_Cantidad, @Detalle_Compra_Subtotal
    END

    CLOSE Cursor_Detalle
    DEALLOCATE Cursor_Detalle
END
GO

-- Asignar un numero incremental al Detalle_Pedido_Numero y calcular subtotal si es que no fue calculado
CREATE TRIGGER Insertar_Detalle_Pedido
ON DATA_DEALERS.Detalle_Pedido
INSTEAD OF INSERT
AS
BEGIN
    -- Declaracion de variables para almacenar los valores de cada fila a insertar
    DECLARE @Pedido_Numero DECIMAL(18,0), @Detalle_Sillon BIGINT, @Detalle_Pedido_Precio DECIMAL(18,2), @Detalle_Pedido_Cantidad BIGINT, @Detalle_Pedido_Subtotal DECIMAL(18,2), @Detalle_Pedido_Numero BIGINT

    -- Cursor para recorrer todas las filas a insertar
    DECLARE Cursor_Detalle CURSOR FOR
        SELECT 
            i.Pedido_Numero,
            i.Detalle_Sillon,
            i.Detalle_Pedido_Precio,
            i.Detalle_Pedido_Cantidad,
            ISNULL(i.Detalle_Pedido_Subtotal, i.Detalle_Pedido_Precio * i.Detalle_Pedido_Cantidad) -- Si el subtotal es NULL, se calcula
        FROM inserted i

    OPEN Cursor_Detalle

    FETCH Cursor_Detalle INTO @Pedido_Numero, @Detalle_Sillon, @Detalle_Pedido_Precio, @Detalle_Pedido_Cantidad, @Detalle_Pedido_Subtotal

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Buscar el siguiente numero de detalle para el pedido (incremental por pedido)
        SELECT @Detalle_Pedido_Numero = COUNT(*) 
        FROM DATA_DEALERS.Detalle_Pedido
        WHERE Pedido_Numero = @Pedido_Numero

        -- Inserta la fila en la tabla con el numero incremental y el subtotal
        INSERT INTO DATA_DEALERS.Detalle_Pedido (Detalle_Pedido_Numero, Pedido_Numero, Detalle_Sillon, Detalle_Pedido_Precio, Detalle_Pedido_Cantidad, Detalle_Pedido_Subtotal)
        VALUES (@Detalle_Pedido_Numero, @Pedido_Numero, @Detalle_Sillon, @Detalle_Pedido_Precio, @Detalle_Pedido_Cantidad, @Detalle_Pedido_Subtotal)

        FETCH Cursor_Detalle INTO @Pedido_Numero, @Detalle_Sillon, @Detalle_Pedido_Precio, @Detalle_Pedido_Cantidad, @Detalle_Pedido_Subtotal
    END

    CLOSE Cursor_Detalle
    DEALLOCATE Cursor_Detalle
END
GO

-- Asignar un numero incremental al Detalle_Factura_Numero y calcular subtotal si es que no fue calculado
CREATE TRIGGER Insertar_Detalle_Factura
ON DATA_DEALERS.Detalle_Factura
INSTEAD OF INSERT
AS
BEGIN
    -- Declaracion de variables para almacenar los valores de cada fila a insertar
    DECLARE @Factura_Numero BIGINT, @Pedido_Numero DECIMAL(18,0), @Detalle_Factura_Precio DECIMAL(18,2), @Detalle_Factura_Cantidad DECIMAL(18,0), @Detalle_Factura_Subtotal DECIMAL(18,2), @Detalle_Factura_Numero BIGINT

    -- Cursor para recorrer todas las filas a insertar
    DECLARE Cursor_Detalle CURSOR FOR
        SELECT 
            i.Factura_Numero,
            i.Pedido_Numero,
            i.Detalle_Factura_Precio,
            i.Detalle_Factura_Cantidad,
            ISNULL(i.Detalle_Factura_Subtotal, i.Detalle_Factura_Precio * i.Detalle_Factura_Cantidad) -- Si el subtotal es NULL, se calcula
        FROM inserted i

    OPEN Cursor_Detalle

    FETCH Cursor_Detalle INTO @Factura_Numero, @Pedido_Numero, @Detalle_Factura_Precio, @Detalle_Factura_Cantidad, @Detalle_Factura_Subtotal

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Buscar el siguiente numero de detalle para la factura (incremental por factura)
        SELECT @Detalle_Factura_Numero = COUNT(*) 
        FROM DATA_DEALERS.Detalle_Factura
        WHERE Factura_Numero = @Factura_Numero

        -- Inserta la fila en la tabla con el numero incremental y el subtotal
        INSERT INTO DATA_DEALERS.Detalle_Factura (Factura_Numero, Detalle_Factura_Numero, Pedido_Numero, Detalle_Factura_Precio, Detalle_Factura_Cantidad, Detalle_Factura_Subtotal)
        VALUES (@Factura_Numero, @Detalle_Factura_Numero, @Pedido_Numero, @Detalle_Factura_Precio, @Detalle_Factura_Cantidad, @Detalle_Factura_Subtotal)

        FETCH Cursor_Detalle INTO @Factura_Numero, @Pedido_Numero, @Detalle_Factura_Precio, @Detalle_Factura_Cantidad, @Detalle_Factura_Subtotal
    END

    CLOSE Cursor_Detalle
    DEALLOCATE Cursor_Detalle
END
GO

-- Calcular el total del envio si no se especifico
CREATE TRIGGER Calcular_Envio_Total
ON DATA_DEALERS.Envio
AFTER INSERT
AS
BEGIN
    UPDATE e
    SET Envio_Total = i.Envio_ImporteTraslado + i.Envio_ImporteSubida -- El total es la suma de los importes
    FROM DATA_DEALERS.Envio e
        JOIN inserted i ON e.Envio_Numero = i.Envio_Numero
    WHERE i.Envio_Total IS NULL
END
GO

-- Verificar que cada sillon tenga exactamente 3 materiales y de tipos distintos
CREATE TRIGGER Verificar_Material_Por_Sillon
ON DATA_DEALERS.Material_Por_Sillon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Primer verificacion: El sillon tiene exactamente 3 materiales_por_sillon
    IF EXISTS (
        SELECT 1
        FROM DATA_DEALERS.Material_Por_Sillon
        GROUP BY Sillon_Codigo
        HAVING COUNT(*) <> 3
    )
    BEGIN
        THROW 50000, 'Error: Cada sillon debe tener unicamente 3 materiales.', 1
    END
    
    -- Segunda verificacion: Todos sus materiales son distintos entre si
    IF EXISTS (
        SELECT 1
        FROM DATA_DEALERS.Material_Por_Sillon mps
        JOIN DATA_DEALERS.Material mat ON mps.Material_Codigo = mat.Material_Codigo
        GROUP BY mps.Sillon_Codigo
        HAVING COUNT(DISTINCT mat.Material_Tipo) <> COUNT(*)
    )
    BEGIN
        THROW 50001, 'Error: Los materiales de cada sillon deben ser de tipos distintos: Madera, Tela y Relleno.', 1
    END
END 
GO

----------- INDICES ------------

CREATE INDEX ix_detalle_pedido ON DATA_DEALERS.Detalle_Pedido (Pedido_Numero, Detalle_Sillon)
CREATE INDEX ix_detalle_compra ON DATA_DEALERS.Detalle_Compra (Compra_Numero, Detalle_Compra_Material)
CREATE INDEX ix_detalle_factura ON DATA_DEALERS.Detalle_Factura (Factura_Numero, Pedido_Numero)
CREATE INDEX ix_direccion ON DATA_DEALERS.Direccion (Localidad_Codigo)
CREATE INDEX ix_localidad ON DATA_DEALERS.Localidad (Provincia_Codigo)
CREATE INDEX ix_cliente ON DATA_DEALERS.Cliente (Cliente_Dni)
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
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre
    WHERE m.Tela_Color IS NOT NULL
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
        Cliente_Provincia
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
        JOIN DATA_DEALERS.Provincia p ON m.Cliente_Provincia = p.Provincia_Nombre
        JOIN DATA_DEALERS.Localidad l ON m.Cliente_Localidad = l.Localidad_Nombre AND p.Provincia_Codigo = l.Provincia_Codigo 
        JOIN DATA_DEALERS.Direccion d ON m.Cliente_Direccion = d.Direccion_Nombre AND l.Localidad_Codigo = d.Localidad_Codigo
    WHERE m.Cliente_Dni IS NOT NULL
END
GO

-- Pedidos

CREATE PROCEDURE DATA_DEALERS.migrate_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Pedido (Pedido_Sucursal, Pedido_Cliente, Pedido_Estado, Pedido_Fecha, Pedido_Total)
    SELECT  
        m.Sucursal_NroSucursal, 
        c.Cliente_Id, 
        m.Pedido_Estado, 
        m.Pedido_Fecha, 
        m.Pedido_Total
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Cliente c ON m.Cliente_Dni = c.Cliente_Dni
        AND m.Cliente_Nombre = c.Cliente_Nombre
        AND m.Cliente_Apellido = c.Cliente_Apellido
    WHERE m.Pedido_Numero IS NOT NULL
    GROUP BY
        m.Pedido_Numero,
        m.Sucursal_NroSucursal, 
        c.Cliente_Id, 
        m.Pedido_Estado, 
        m.Pedido_Fecha, 
        m.Pedido_Total
    ORDER BY m.Pedido_Numero
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
    WHERE Pedido_Cancelacion_Fecha IS NOT NULL
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Pedido (Pedido_Numero, Detalle_Sillon, Detalle_Pedido_Precio, Detalle_Pedido_Cantidad, Detalle_Pedido_Subtotal)
    SELECT DISTINCT 
        Pedido_Numero, 
        Sillon_Codigo, 
        Detalle_Pedido_Precio, 
        Detalle_Pedido_Cantidad,
        Detalle_Pedido_Subtotal
    FROM gd_esquema.Maestra
    WHERE Sillon_Codigo IS NOT NULL
END 
GO

-- Facturas

CREATE PROCEDURE DATA_DEALERS.migrate_factura
AS
BEGIN
    INSERT INTO DATA_DEALERS.Factura (Factura_Sucursal, Factura_Cliente, Factura_Fecha, Factura_Total)
    SELECT 
        m.Sucursal_NroSucursal,
        c.Cliente_Id,
        m.Factura_Fecha, 
        m.Factura_Total
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Cliente c ON m.Cliente_Dni = c.Cliente_Dni
        AND m.Cliente_Nombre = c.Cliente_Nombre
        AND m.Cliente_Apellido = c.Cliente_Apellido
    WHERE m.Factura_Numero IS NOT NULL
    GROUP BY
        m.Factura_Numero,
        m.Sucursal_NroSucursal, 
        c.Cliente_Id, 
        m.Factura_Fecha, 
        m.Factura_Total
    ORDER BY m.Factura_Numero
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_factura
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Factura (Factura_Numero, Pedido_Numero, Detalle_Factura_Precio, Detalle_Factura_Cantidad, Detalle_Factura_Subtotal)
    SELECT DISTINCT 
        Factura_Numero,
        Pedido_Numero,
        Detalle_Factura_Precio, 
        Detalle_Factura_Cantidad,
        Detalle_Factura_Subtotal
    FROM gd_esquema.Maestra
    WHERE Factura_Numero IS NOT NULL
    AND Pedido_Numero IS NOT NULL
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_envio
AS
BEGIN
    INSERT INTO DATA_DEALERS.Envio (Envio_Factura, Envio_ImporteTraslado, Envio_ImporteSubida, Envio_Fecha_Programada, Envio_Fecha)
    SELECT 
        m.Factura_Numero, 
        m.Envio_ImporteTraslado, 
        m.Envio_ImporteSubida, 
        m.Envio_Fecha_Programada, 
        m.Envio_Fecha
    FROM gd_esquema.Maestra m
    WHERE m.Envio_Numero IS NOT NULL 
    GROUP BY
        m.Envio_Numero,
        m.Factura_Numero, 
        m.Envio_ImporteTraslado, 
        m.Envio_ImporteSubida, 
        m.Envio_Fecha_Programada, 
        m.Envio_Fecha
    ORDER BY m.Envio_Numero
END 
GO

-- Compras

CREATE PROCEDURE DATA_DEALERS.migrate_proveedor
AS
BEGIN
    INSERT INTO DATA_DEALERS.Proveedor (Proveedor_Cuit, Proveedor_Direccion, Proveedor_RazonSocial, Proveedor_Telefono, Proveedor_Mail)
    SELECT DISTINCT 
        m.Proveedor_Cuit, 
        d.Direccion_Codigo, 
        m.Proveedor_RazonSocial, 
        m.Proveedor_Telefono, 
        m.Proveedor_Mail
    FROM gd_esquema.Maestra m
    JOIN DATA_DEALERS.Provincia p ON m.Proveedor_Provincia = p.Provincia_Nombre
    JOIN DATA_DEALERS.Localidad l ON m.Proveedor_Localidad = l.Localidad_Nombre AND p.Provincia_Codigo = l.Provincia_Codigo 
    JOIN DATA_DEALERS.Direccion d ON m.Proveedor_Direccion = d.Direccion_Nombre AND l.Localidad_Codigo = d.Localidad_Codigo
    WHERE Proveedor_Cuit IS NOT NULL
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_compra
AS
BEGIN
    INSERT INTO DATA_DEALERS.Compra (Compra_Proveedor, Compra_Sucursal, Compra_Fecha, Compra_Total)
    SELECT 
        m.Proveedor_Cuit, 
        m.Sucursal_NroSucursal, 
        m.Compra_Fecha, 
        m.Compra_Total
    FROM gd_esquema.Maestra m
    WHERE m.Compra_Numero IS NOT NULL
    GROUP BY
        m.Compra_Numero,
        m.Proveedor_Cuit, 
        m.Sucursal_NroSucursal, 
        m.Compra_Fecha, 
        m.Compra_Total
    ORDER BY m.Compra_Numero
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_detalle_compra
AS
BEGIN
    INSERT INTO DATA_DEALERS.Detalle_Compra (Compra_Numero, Detalle_Compra_Material, Detalle_Compra_Precio, Detalle_Compra_Cantidad, Detalle_Compra_Subtotal)
    SELECT DISTINCT 
        m.Compra_Numero, 
        mat.Material_Codigo, 
        m.Detalle_Compra_Precio, 
        m.Detalle_Compra_Cantidad,
        m.Detalle_Compra_Subtotal
    FROM gd_esquema.Maestra m
        JOIN DATA_DEALERS.Material mat ON m.Material_Nombre = mat.Material_Nombre
    WHERE m.Compra_Numero IS NOT NULL
END 
GO

--------- EXECUTES ---------

-- Ejecuta los procedimientos de migracion para migrar los datos al nuevo esquema

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

--------- BORRAR PROCEDURES ---------

-- Elimina los procedimientos de migracion luego de ser utilizados

DROP PROCEDURE DATA_DEALERS.migrate_material
DROP PROCEDURE DATA_DEALERS.migrate_tela
DROP PROCEDURE DATA_DEALERS.migrate_madera
DROP PROCEDURE DATA_DEALERS.migrate_relleno
DROP PROCEDURE DATA_DEALERS.migrate_sillon_modelo
DROP PROCEDURE DATA_DEALERS.migrate_sillon_medida
DROP PROCEDURE DATA_DEALERS.migrate_sillon
DROP PROCEDURE DATA_DEALERS.migrate_material_por_sillon
DROP PROCEDURE DATA_DEALERS.migrate_provincia
DROP PROCEDURE DATA_DEALERS.migrate_localidad
DROP PROCEDURE DATA_DEALERS.migrate_direccion
DROP PROCEDURE DATA_DEALERS.migrate_sucursal
DROP PROCEDURE DATA_DEALERS.migrate_cliente
DROP PROCEDURE DATA_DEALERS.migrate_pedido
DROP PROCEDURE DATA_DEALERS.migrate_pedido_cancelacion
DROP PROCEDURE DATA_DEALERS.migrate_detalle_pedido
DROP PROCEDURE DATA_DEALERS.migrate_factura
DROP PROCEDURE DATA_DEALERS.migrate_detalle_factura
DROP PROCEDURE DATA_DEALERS.migrate_envio
DROP PROCEDURE DATA_DEALERS.migrate_proveedor
DROP PROCEDURE DATA_DEALERS.migrate_compra
DROP PROCEDURE DATA_DEALERS.migrate_detalle_compra

--------- EXTRA: CORRECCION DE ERRORES ---------

-- Corrige nombres de provincias mal cargadas

UPDATE DATA_DEALERS.Provincia
SET Provincia_Nombre = 'Tierra Del Fuego'
WHERE Provincia_Nombre = 'Tierra Del Fue;'

UPDATE DATA_DEALERS.Provincia
SET Provincia_Nombre = 'Santiago Del Estero'
WHERE Provincia_Nombre = 'Santia; Del Estero'