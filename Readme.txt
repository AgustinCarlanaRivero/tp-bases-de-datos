Grupo: DATA_DEALERS
Número de Grupo: 13
Integrantes:
Carlana Rivero, Agustín - 212.953-0
Sagrada, Tomas Alejandro - 214.097-4
Gutman, Facundo Martín - 212.989-9
Scarlato, Alejo Agustin - 214.124-3
Email del integrante responsable del grupo: acarlanarivero@frba.utn.edu.ar


- Hacer migracion (usar GROUP BY en vez de SELECT DISTINCT para los identity que no arrancan en 0 (da error))
- Anotar justificaciones de disenio
- Actualizar DER (PNG y en el doc)

- Debatir donde podriamos usar indices?
- Aplicar respuestas consultas?

Falopeada:
- Se pueden crear procedures que encapsulen la logica de crear compras y sus detalles en una transaccion, para que no ocurra que haya una compra sin detalle? (Lo mismo aplica a pedido y sillon)
LA IDEA SERIA OBLIGAR AL USUARIO A USAR ESOS PROCEDURES

Explicación ROW_NUMBER() OVER (PARTITION BY m.Pedido_Numero ORDER BY m.Pedido_Numero, m.Sillon_Codigo) - 1 AS Detalle_Pedido_Numero:

1. ROW_NUMBER() OVER (...)
Esta función de ventana asigna un número secuencial a cada fila dentro de un grupo de filas.

2. El número empieza en 1 para cada grupo.
PARTITION BY m.Pedido_Numero
Esto indica que la numeración se reinicia para cada valor distinto de Pedido_Numero.

3. Es decir, para cada pedido, la numeración de los detalles empieza desde 1.
ORDER BY m.Pedido_Numero, m.Sillon_Codigo ||||||||| AGUS CHEQUEATE ESTO |||||||||
Dentro de cada pedido, las filas se ordenan por el número de pedido y luego por el código de sillón.

4. Así, el primer detalle de cada pedido será el que tenga el menor Sillon_Codigo.
ROW_NUMBER() ... - 1
Se le resta 1 al resultado de ROW_NUMBER().

5. Así, el primer detalle de cada pedido tendrá el número 0, el segundo el 1, y así sucesivamente.