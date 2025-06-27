-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

---------------------------- CREACION DE TABLAS ----------------------------

--------- DIMENSIONES ---------

CREATE TABLE DATA_DEALERS.BI_Dimension_Tiempo (
    Tiempo_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Anio SMALLINT,
    Cuatrimestre TINYINT,
    Mes TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Ubicacion (
    Ubicacion_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Provincia NVARCHAR(255),
    Localidad NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes (
    Rango_Etario_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Edad_Minima TINYINT, -- Justificacion
    Edad_Maxima TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Turno_Ventas (
    Turno_Ventas_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Horario_Minimo TINYINT,
    Horario_Maximo TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Tipo_Material (
    Tipo_Material_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Tipo_Material NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Modelo_Sillon (
    Modelo_Sillon_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Nombre_Modelo NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Estado_Pedido (
    Estado_Pedido_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Estado_Pedido NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Sucursal (
    Sucursal_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Sucursal_NroSucursal BIGINT
)

--------- HECHOS ---------

CREATE TABLE DATA_DEALERS.BI_Hechos_Facturas (
    Modelo_Sillon_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Modelo_Sillon,
    Rango_Etario_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT NOT NULL REFERENCES  DATA_DEALERS.BI_Dimension_Sucursal,
    Ingresos_Por_Modelo DECIMAL(38,2) NOT NULL,
    Cantidad_Sillones BIGINT NOT NULL,
    Tiempo_Fabricacion_Dias DECIMAL(6,2) NOT NULL,
    Peso_Factura DECIMAL(10,6) NOT NULL,
    PRIMARY KEY (Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Sucursal_Id, Sucursal_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Compras (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Tipo_Material_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tipo_Material,
    Egresos DECIMAL(38,2) NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Tipo_Material_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Pedidos (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Estado_Pedido_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Estado_Pedido,
    Turno_Ventas_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Turno_Ventas,
    Cantidad_Pedidos BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Estado_Pedido_Id, Turno_Ventas_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Envios (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Cliente_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Ubicacion_Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Cantidad_Envios BIGINT NOT NULL,
    Cantidad_Envios_Cumplidos_En_Fecha BIGINT NOT NULL,
    Costo_Envios BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Ubicacion_Cliente_Id, Ubicacion_Sucursal_Id, Sucursal_Id)
)

---------------------------- PROCEDURES DE MIGRACION ----------------------------

--------- CREACION ---------

--------- DIMENSIONES ---------

GO
CREATE PROCEDURE DATA_DEALERS.migrate_dimension_tiempo
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Tiempo(Anio, Cuatrimestre, Mes)
    (
    SELECT DISTINCT 
        YEAR(Factura_Fecha) AS Anio,
        DATEPART(QUARTER, Factura_Fecha) AS Cuatrimestre,
        MONTH(Factura_Fecha) AS Mes
    FROM DATA_DEALERS.Factura
    UNION 
    SELECT DISTINCT 
        YEAR(Pedido_Fecha) AS Anio,
        DATEPART(QUARTER, Pedido_Fecha) AS Cuatrimestre,
        MONTH(Pedido_Fecha) AS Mes
    FROM DATA_DEALERS.Pedido
    UNION
    SELECT DISTINCT 
        YEAR(Compra_Fecha) AS Anio,
        DATEPART(QUARTER, Compra_Fecha) AS Cuatrimestre,
        MONTH(Compra_Fecha) AS Mes
    FROM DATA_DEALERS.Compra
    UNION
    SELECT DISTINCT 
        YEAR(Envio_Fecha_Programada) AS Anio,
        DATEPART(QUARTER, Envio_Fecha_Programada) AS Cuatrimestre,
        MONTH(Envio_Fecha_Programada) AS Mes
    FROM DATA_DEALERS.Envio
    UNION
    SELECT DISTINCT 
        YEAR(Envio_Fecha) AS Anio,
        DATEPART(QUARTER, Envio_Fecha) AS Cuatrimestre,
        MONTH(Envio_Fecha) AS Mes
    FROM DATA_DEALERS.Envio
    )
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_ubicacion
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Ubicacion(Provincia, Localidad)
    (
    SELECT DISTINCT 
        p.Provincia_Nombre, 
        l.Localidad_Nombre
    FROM DATA_DEALERS.Cliente c
        JOIN DATA_DEALERS.Direccion d ON c.Cliente_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia p ON l.Provincia_Codigo = p.Provincia_Codigo
    UNION
    SELECT DISTINCT 
        p.Provincia_Nombre, 
        l.Localidad_Nombre
    FROM DATA_DEALERS.Sucursal s
        JOIN DATA_DEALERS.Direccion d ON s.Sucursal_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia p ON l.Provincia_Codigo = p.Provincia_Codigo
    )
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_rango_etario_clientes
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes(Edad_Minima, Edad_Maxima)
    VALUES 
        (0, 24),
        (25, 34),
        (35, 49),
        (50, 255)
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_turno_ventas
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Turno_Ventas(Horario_Minimo, Horario_Maximo)
    VALUES 
        (8, 13),
        (14, 20)
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_tipo_material
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Tipo_Material(Tipo_Material)
    VALUES 
        ('Madera'), 
        ('Relleno'), 
        ('Tela')
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_modelo_sillon
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Modelo_Sillon(Nombre_Modelo)
    SELECT Sillon_Modelo
    FROM DATA_DEALERS.Sillon_Modelo
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_estado_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Estado_Pedido(Estado_Pedido)
    VALUES 
        ('PENDIENTE'),
        ('CANCELADO'),
        ('ENTREGADO')
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_sucursal
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Sucursal(Sucursal_NroSucursal)
    SELECT Sucursal_NroSucursal
    FROM DATA_DEALERS.Sucursal
END
GO

--------- HECHOS ---------

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_facturas
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Facturas(Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Sucursal_Id, Sucursal_Id, Ingresos_Por_Modelo, Cantidad_Sillones, Tiempo_Fabricacion_Dias, Peso_Factura)
    SELECT 
        -- PKs
        dm.Modelo_Sillon_Id, 
        r.Rango_Etario_Id, 
        t.Tiempo_Id, 
        u.Ubicacion_Id, 
        ds.Sucursal_Id, 
        -- Atributos propios
        SUM(df.Detalle_Factura_SubTotal),
        SUM(df.Detalle_Factura_Cantidad),
        MAX(DATEDIFF(DAY, p.Pedido_Fecha, f.Factura_Fecha)), -- Mismo valor por factura, por eso agrupamos por MAX
        SUM(1.0 / mf.Modelos_Por_Factura) -- Le asignamos un peso a cada fila, para calcular la cantidad de facturas
        
    FROM DATA_DEALERS.Detalle_Factura df
        JOIN DATA_DEALERS.Factura f ON f.Factura_Numero = df.Factura_Numero
        JOIN DATA_DEALERS.Pedido p ON df.Pedido_Numero = p.Pedido_Numero
        JOIN (
                SELECT 
                    df2.Factura_Numero,
                    COUNT(DISTINCT dp2.Detalle_Sillon) AS Modelos_Por_Factura
                FROM DATA_DEALERS.Detalle_Factura df2
                    JOIN DATA_DEALERS.Detalle_Pedido dp2 ON 
                        dp2.Pedido_Numero = df2.Pedido_Numero AND
                        dp2.Detalle_Pedido_Numero = df2.Detalle_Factura_Numero
                GROUP BY Factura_Numero
            ) AS mf ON mf.Factura_Numero = f.Factura_Numero

        -- Para obtener el id de la dimension modelo sillon
        JOIN DATA_DEALERS.Detalle_Pedido dp ON 
            dp.Pedido_Numero = df.Pedido_Numero AND 
            dp.Detalle_Pedido_Numero = df.Detalle_Factura_Numero
        JOIN DATA_DEALERS.Sillon s ON s.Sillon_Codigo = dp.Detalle_Sillon
        JOIN DATA_DEALERS.Sillon_Modelo m ON m.Sillon_Modelo_Codigo = s.Sillon_Modelo   
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON m.Sillon_Modelo = dm.Nombre_Modelo
        
        -- Para obtener los el id de la dimension rango etario
        JOIN DATA_DEALERS.Cliente c ON f.Factura_Cliente = c.Cliente_Id
        JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r ON 
            DATEDIFF(YEAR, c.Cliente_FechaNacimiento, f.Factura_Fecha) BETWEEN r.Edad_Minima AND r.Edad_Maxima

        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(f.Factura_Fecha) = t.Anio AND 
            DATEPART(QUARTER, f.Factura_Fecha) = t.Cuatrimestre AND 
            MONTH(f.Factura_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension ubicacion
        JOIN DATA_DEALERS.Sucursal su ON f.Factura_Sucursal = su.Sucursal_NroSucursal
        JOIN DATA_DEALERS.Direccion d ON su.Sucursal_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia pr ON l.Provincia_Codigo = pr.Provincia_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON
            u.Localidad = l.Localidad_Nombre AND 
            u.Provincia = pr.Provincia_Nombre

        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal ds ON f.Factura_Sucursal = ds.Sucursal_NroSucursal
    GROUP BY
        dm.Modelo_Sillon_Id,
        r.Rango_Etario_Id,
        t.Tiempo_Id,
        u.Ubicacion_Id,
        ds.Sucursal_Id
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_compras
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Compras(Tiempo_Id, Sucursal_Id, Tipo_Material_Id, Egresos)
    SELECT
        -- PKs
        t.Tiempo_Id,
        s.Sucursal_Id,
        tm.Tipo_Material_Id,
        -- Atributos propios
        SUM(dc.Detalle_Compra_Subtotal)
    FROM DATA_DEALERS.Detalle_Compra dc
        JOIN DATA_DEALERS.Compra c ON dc.Compra_Numero = c.Compra_Numero
        
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(c.Compra_Fecha) = t.Anio AND 
            DATEPART(QUARTER, c.Compra_Fecha) = t.Cuatrimestre AND 
            MONTH(c.Compra_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON c.Compra_Sucursal = s.Sucursal_NroSucursal
        
        -- Para obtener el id de la dimension tipo material
        JOIN DATA_DEALERS.Material m ON dc.Detalle_Compra_Material = m.Material_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Tipo_Material tm ON m.Material_Tipo = tm.Tipo_Material
    GROUP BY
        t.Tiempo_Id,
        s.Sucursal_Id,
        tm.Tipo_Material_Id
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_pedidos
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Pedidos(Tiempo_Id, Sucursal_Id, Estado_Pedido_Id, Turno_Ventas_Id, Cantidad_Pedidos)
    SELECT 
        -- PKs
        t.Tiempo_Id,
        s.Sucursal_Id,
        e.Estado_Pedido_Id,
        tv.Turno_Ventas_Id,
        -- Atributos propios
        COUNT(DISTINCT p.Pedido_Numero)
    FROM DATA_DEALERS.Pedido p
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(p.Pedido_Fecha) = t.Anio AND 
            DATEPART(QUARTER, p.Pedido_Fecha) = t.Cuatrimestre AND 
            MONTH(p.Pedido_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON p.Pedido_Sucursal = s.Sucursal_NroSucursal
        
        -- Para obtener el id de la dimension estado pedido
        JOIN DATA_DEALERS.BI_Dimension_Estado_Pedido e ON p.Pedido_Estado = e.Estado_Pedido
        
        -- Para obtener el id de la dimension turno ventas
        JOIN DATA_DEALERS.BI_Dimension_Turno_Ventas tv ON 
            DATEPART(HOUR, p.Pedido_Fecha) BETWEEN tv.Horario_Minimo AND tv.Horario_Maximo
    GROUP BY
        t.Tiempo_Id,
        s.Sucursal_Id,
        e.Estado_Pedido_Id,
        tv.Turno_Ventas_Id
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_envios
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Envios(
        Tiempo_Id, 
        Ubicacion_Cliente_Id,
        Ubicacion_Sucursal_Id,
        Sucursal_Id, 
        Cantidad_Envios, 
        Cantidad_Envios_Cumplidos_En_Fecha, 
        Costo_Envios
    )
    SELECT 
        -- PKs
        t.Tiempo_Id,    
        uc.Ubicacion_Id,
        us.Ubicacion_Id,
        dis.Sucursal_Id,
        -- Atributos propios
        COUNT(DISTINCT e.Envio_Numero),
        COUNT(DISTINCT CASE 
                WHEN 
                    e.Envio_Fecha IS NOT NULL AND 
                    e.Envio_Fecha <= e.Envio_Fecha_Programada 
                THEN e.Envio_Numero 
                ELSE NULL 
                END
            ), -- Cuenta los envíos cumplidos en fecha para el grupo actual
        SUM(e.Envio_Total)
    FROM DATA_DEALERS.Envio e
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(e.Envio_Fecha_Programada) = t.Anio AND 
            DATEPART(QUARTER, e.Envio_Fecha_Programada) = t.Cuatrimestre AND 
            MONTH(e.Envio_Fecha_Programada) = t.Mes

        -- Para obtener el id de la dimension ubicacion del cliente
        JOIN DATA_DEALERS.Factura f ON e.Envio_Factura = f.Factura_Numero
        JOIN DATA_DEALERS.Cliente c ON f.Factura_Cliente = c.Cliente_Id
        JOIN DATA_DEALERS.Direccion dc ON c.Cliente_Direccion = dc.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad lc ON dc.Localidad_Codigo = lc.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia pc ON lc.Provincia_Codigo = pc.Provincia_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion uc ON 
            uc.Localidad = lc.Localidad_Nombre AND 
            uc.Provincia = pc.Provincia_Nombre

        -- Para obtener el id de la dimension ubicacion de la sucursal
        JOIN DATA_DEALERS.Sucursal s ON f.Factura_Sucursal = s.Sucursal_NroSucursal
        JOIN DATA_DEALERS.Direccion ds ON s.Sucursal_Direccion = ds.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad ls ON ds.Localidad_Codigo = ls.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia ps ON ls.Provincia_Codigo = ps.Provincia_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion us ON 
            us.Localidad = ls.Localidad_Nombre AND 
            us.Provincia = ps.Provincia_Nombre

        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal dis ON f.Factura_Sucursal = dis.Sucursal_NroSucursal
    GROUP BY
        t.Tiempo_Id,
        uc.Ubicacion_Id,
        us.Ubicacion_Id,
        dis.Sucursal_Id
END
GO

--------- EXEC ---------

EXEC DATA_DEALERS.migrate_dimension_tiempo
EXEC DATA_DEALERS.migrate_dimension_ubicacion
EXEC DATA_DEALERS.migrate_dimension_rango_etario_clientes
EXEC DATA_DEALERS.migrate_dimension_turno_ventas
EXEC DATA_DEALERS.migrate_dimension_tipo_material
EXEC DATA_DEALERS.migrate_dimension_modelo_sillon
EXEC DATA_DEALERS.migrate_dimension_estado_pedido
EXEC DATA_DEALERS.migrate_dimension_sucursal
EXEC DATA_DEALERS.migrate_hechos_facturas
EXEC DATA_DEALERS.migrate_hechos_compras
EXEC DATA_DEALERS.migrate_hechos_pedidos
EXEC DATA_DEALERS.migrate_hechos_envios
GO

---------------------------- VISTAS ----------------------------

-- VISTA 1

CREATE VIEW DATA_DEALERS.Ganancias AS
SELECT
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal,
    SUM(ISNULL(f.Total_Ingresos,0) + ISNULL(e.Total_Costo_Envios, 0) - ISNULL(c.Total_Egresos,0)) AS Ganancia
FROM
    (
        SELECT
            Tiempo_Id,
            Sucursal_Id,
            SUM(Ingresos_Por_Modelo) AS Total_Ingresos
        FROM DATA_DEALERS.BI_Hechos_Facturas
        GROUP BY Tiempo_Id, Sucursal_Id
    ) AS f
    LEFT JOIN
    (
        SELECT 
            Tiempo_Id,
            Sucursal_Id,
            SUM(Costo_Envios) AS Total_Costo_Envios
        FROM DATA_DEALERS.BI_Hechos_Envios
        GROUP BY 
            Tiempo_Id, 
            Sucursal_Id
    ) e ON e.Tiempo_Id = f.Tiempo_Id AND e.Sucursal_Id = f.Sucursal_Id
    FULL JOIN
    (
        SELECT
            Tiempo_Id,
            Sucursal_Id,
            SUM(Egresos) AS Total_Egresos
        FROM DATA_DEALERS.BI_Hechos_Compras
        GROUP BY Tiempo_Id, Sucursal_Id
    ) AS c ON 
            c.Tiempo_Id = f.Tiempo_Id AND 
            c.Sucursal_Id = f.Sucursal_Id

  JOIN DATA_DEALERS.BI_Dimension_Tiempo t
    ON t.Tiempo_Id = ISNULL(f.Tiempo_Id, c.Tiempo_Id)
  JOIN DATA_DEALERS.BI_Dimension_Sucursal s
    ON s.Sucursal_Id = ISNULL(f.Sucursal_Id, c.Sucursal_Id)
GROUP BY
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal
GO

-- VISTA 2

CREATE VIEW DATA_DEALERS.Factura_Promedio_Mensual AS
SELECT
    t.Anio,
    t.Cuatrimestre,
    u.Provincia,
    (SUM(f.Total_Ingresos + ISNULL(e.Total_Costo_Envios, 0)) / NULLIF(SUM(f.Total_Peso), 0)) / 4 AS Factura_Promedio_Mensual
FROM (
    SELECT
        Tiempo_Id,
        Ubicacion_Sucursal_Id,
        SUM(Ingresos_Por_Modelo) Total_Ingresos,
        SUM(Peso_Factura) Total_Peso
    FROM DATA_DEALERS.BI_Hechos_Facturas
    GROUP BY
        Tiempo_Id,
        Ubicacion_Sucursal_Id
    ) AS f
    LEFT JOIN (
        SELECT
            Tiempo_Id,
            Ubicacion_Sucursal_Id,
            SUM(Costo_Envios) Total_Costo_Envios
        FROM DATA_DEALERS.BI_Hechos_Envios
        GROUP BY
            Tiempo_Id,
            Ubicacion_Sucursal_Id
    ) AS e
        ON e.Tiempo_Id = f.Tiempo_Id AND 
        e.Ubicacion_Sucursal_Id = f.Ubicacion_Sucursal_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Tiempo AS t
        ON t.Tiempo_Id = f.Tiempo_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Ubicacion AS u
        ON u.Ubicacion_Id = f.Ubicacion_Sucursal_Id
GROUP BY
    t.Anio,
    t.Cuatrimestre,
    u.Provincia
GO

-- VISTA 3

CREATE VIEW DATA_DEALERS.Rendimiento_De_Modelos AS
SELECT
    t.Anio,
    t.Cuatrimestre,
    u.Provincia,
    u.Localidad,
    r.Edad_Minima,
    r.Edad_Maxima,
    dm.Nombre_Modelo,
    SUM(f.Ingresos_Por_Modelo) AS Total_Ventas
FROM DATA_DEALERS.BI_Hechos_Facturas f
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON f.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON f.Ubicacion_Sucursal_Id = u.Ubicacion_Id
    JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r ON f.Rango_Etario_Id = r.Rango_Etario_Id
    JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON f.Modelo_Sillon_Id = dm.Modelo_Sillon_Id
GROUP BY
    t.Anio,
    t.Cuatrimestre,
    u.Localidad,
    u.Provincia,
    r.Edad_Minima,
    r.Edad_Maxima,
    dm.Nombre_Modelo
HAVING (
    SELECT COUNT(*)
    FROM (
        SELECT
            dm2.Nombre_Modelo,
            SUM(f2.Ingresos_Por_Modelo) AS Total_Ventas
        FROM DATA_DEALERS.BI_Hechos_Facturas f2
            JOIN DATA_DEALERS.BI_Dimension_Tiempo t2 ON f2.Tiempo_Id = t2.Tiempo_Id
            JOIN DATA_DEALERS.BI_Dimension_Ubicacion u2 ON f2.Ubicacion_Sucursal_Id = u2.Ubicacion_Id
            JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r2 ON f2.Rango_Etario_Id = r2.Rango_Etario_Id
            JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm2 ON f2.Modelo_Sillon_Id = dm2.Modelo_Sillon_Id
        WHERE
            t2.Anio = t.Anio AND
            t2.Cuatrimestre = t.Cuatrimestre AND
            u2.Localidad = u.Localidad AND
            u2.Provincia = u.Provincia AND
            r2.Edad_Minima = r.Edad_Minima AND
            r2.Edad_Maxima = r.Edad_Maxima
        GROUP BY dm2.Nombre_Modelo
        HAVING SUM(f2.Ingresos_Por_Modelo) > SUM(f.Ingresos_Por_Modelo)
    ) AS superiores
) < 3
GO

-- VISTA 4


CREATE VIEW DATA_DEALERS.Volumen_De_Pedidos AS
SELECT 
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal,
    tv.Turno_Ventas_Id,
    SUM(p.Cantidad_Pedidos) AS Total_Pedidos
FROM DATA_DEALERS.BI_Hechos_Pedidos p
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON p.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON p.Sucursal_Id = s.Sucursal_Id
    JOIN DATA_DEALERS.BI_Dimension_Turno_Ventas tv ON p.Turno_Ventas_Id = tv.Turno_Ventas_Id
GROUP BY
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal,
    tv.Turno_Ventas_Id
GO

-- VISTA 5

CREATE VIEW DATA_DEALERS.Conversion_De_Pedidos AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    s.Sucursal_NroSucursal,
    e.Estado_Pedido,
    SUM(p.Cantidad_Pedidos) * 100.0 /
        (SELECT SUM(p2.Cantidad_Pedidos)
            FROM DATA_DEALERS.BI_Hechos_Pedidos p2
                JOIN DATA_DEALERS.BI_Dimension_Tiempo t2 ON p2.Tiempo_Id = t2.Tiempo_Id
                JOIN DATA_DEALERS.BI_Dimension_Sucursal s2 ON p2.Sucursal_Id = s2.Sucursal_Id
            WHERE t2.Anio = t.Anio
                AND t2.Cuatrimestre = t.Cuatrimestre
                AND s2.Sucursal_NroSucursal = s.Sucursal_NroSucursal
        )
        Porcentaje_Pedidos
FROM DATA_DEALERS.BI_Hechos_Pedidos p
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON p.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON p.Sucursal_Id = s.Sucursal_Id
    JOIN DATA_DEALERS.BI_Dimension_Estado_Pedido e ON p.Estado_Pedido_Id = e.Estado_Pedido_Id
GROUP BY
    t.Anio,
    t.Cuatrimestre,
    s.Sucursal_NroSucursal,
    e.Estado_Pedido
GO

-- VISTA 6

CREATE VIEW DATA_DEALERS.Tiempo_Promedio_De_Fabricacion AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    s.Sucursal_NroSucursal,
    SUM(Tiempo_Fabricacion_Dias * Peso_Factura) / SUM(Peso_Factura) AS Tiempo_Promedio_Fabricacion
    FROM DATA_DEALERS.BI_Hechos_Facturas f
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON f.Tiempo_Id = t.Tiempo_Id
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON f.Sucursal_Id = s.Sucursal_Id
    GROUP BY
        t.Anio,
        t.Cuatrimestre,
        s.Sucursal_NroSucursal
GO

-- VISTA 7

CREATE VIEW DATA_DEALERS.Promedio_De_Compras AS
SELECT
    t.Anio,
    t.Mes,
    AVG(c.Egresos) Promedio_Compras
FROM DATA_DEALERS.BI_Hechos_Compras c
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON c.Tiempo_Id = t.Tiempo_Id
GROUP BY
    t.Anio,
    t.Mes
GO

-- VISTA 8

CREATE VIEW DATA_DEALERS.Compras_Por_Tipo_De_Material AS
SELECT
    t.Anio,
    t.Cuatrimestre,
    s.Sucursal_NroSucursal,
    tm.Tipo_Material,
    SUM(c.Egresos) AS Total_Compras
FROM DATA_DEALERS.BI_Hechos_Compras c
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON c.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON c.Sucursal_Id = s.Sucursal_Id
    JOIN DATA_DEALERS.BI_Dimension_Tipo_Material tm ON c.Tipo_Material_Id = tm.Tipo_Material_Id
GROUP BY
    t.Anio,
    t.Cuatrimestre,
    s.Sucursal_NroSucursal,
    tm.Tipo_Material
GO


-- VISTA 9

CREATE VIEW DATA_DEALERS.Porcentaje_De_Cumplimiento_De_Envios AS
SELECT
    t.Anio,
    t.Mes,
    SUM(e.Cantidad_Envios_Cumplidos_En_Fecha) * 100.0 / SUM(e.Cantidad_Envios) AS Porcentaje_Cumplimiento
    FROM DATA_DEALERS.BI_Hechos_Envios e
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON e.Tiempo_Id = t.Tiempo_Id
GROUP BY
    t.Anio,
    t.Mes
GO

-- VISTA 10

CREATE VIEW DATA_DEALERS.Localidades_Que_Pagan_Mayor_Costo_De_Envio AS
SELECT TOP 3
    u.Provincia,
    u.Localidad,
    AVG(e.Costo_Envios) AS Promedio_Costo_Envio
FROM DATA_DEALERS.BI_Hechos_Envios e
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON e.Ubicacion_Cliente_Id = u.Ubicacion_Id
GROUP BY
    u.Provincia,
    u.Localidad
ORDER BY AVG(e.Costo_Envios) DESC
GO

------------------------------- ELIMINACION DE ESTRUCTURAS 

DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tiempo
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_ubicacion
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_rango_etario_clientes
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_turno_ventas
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tipo_material
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_modelo_sillon
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_estado_pedido
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_sucursal
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_facturas
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_compras
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_envios
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_pedidos