# DEV 0.1.10 — Corrección de esquinas detectadas

**Fecha:** 2026-10-26 · **Estado:** código subido a `main`, build 11; CI y prueba en iPhone pendientes de confirmación.

## Incidencia que origina la iteración

El creador envió capturas de DEV 0.1.9 sobre una hoja con manuscritos. Las líneas del contorno seleccionado coincidían aproximadamente con los bordes izquierdo, derecho e inferior, pero la **esquina superior derecha se situaba demasiado abajo**, y la línea superior verde atravesaba el documento en diagonal. Esto es compatible con **un vértice mal localizado por Vision** y no con un único desplazamiento global del visor. No se puede garantizar el diagnóstico sin comparar coordenadas originales del fotograma de Vision.

En la captura de revisión, «Compartir» produjo correctamente **1800 × 2400 px, 4,32 MP, alrededor de 1,4 MB**. Fielens **todavía no recorta automáticamente el objeto**: el resultado contiene toda la escena y la fotografía original no se altera.

Las capturas contienen contenido real del usuario: **NO subirlas al repositorio público**.

## Cambios implementados

1. `CameraViewModel` mantiene un diccionario temporal de esquinas **por ID del contorno detectado**. Se limpia al salir de cámara o volver a buscar. La selección sigue siendo local, no se guardan fotografías ni esquinas en el servidor.
2. `CameraPreview` recibe las cuatro esquinas manualmente corregidas. Si existen, dibuja **y evalúa toques** con esos puntos; si no, utiliza Vision. Esto evita que la línea visible y el hit testing diverjan.
3. Modo «Ajustar esquinas» en la cámara. Se ocultan temporalmente nivel, botones de captura/escaneo y paneles superpuestos para que las cuatro esquinas de la hoja sean accesibles. Los cuatro controles circulares menta se pueden **arrastrar uno a uno** y el polígono cambia durante el gesto.
4. `SurfaceScreenPolygon.isConvex`: rechaza auto-intersecciones, concavidad y polígonos degenerados al mover una esquina, evitando guardar un contorno inválido.
5. Botón «Restaurar» vuelve a las esquinas detectadas por Vision; «Listo» regresa a la cámara normal conservando el contorno corregido mientras no se vuelva a escanear.
6. `VNDetectRectanglesRequest` ensaya primero criterios más estrictos (**tolerancia de esquina 22°, confianza 0,45, tamaño mínimo 0,12**) y usa parámetros anteriores más permisivos (35°, 0,35, 0,08) como **respaldo si no obtiene ningún candidato grande** (al menos 6 % del marco). Este cambio experimental puede afectar a documentos muy inclinados; se debe medir la tasa de detección, no asumir mejora universal.
7. Se añaden pruebas de geometría para verificar que cambiar una esquina mantiene el polígono válido y que no se permite arrastrarla hasta crear uno cruzado.
8. App identificada como **DEV 0.1.10, build 11**.

## Limitaciones deliberadas

- El ajuste corrige la superposición durante **la sesión de cámara**, pero **no transforma, recorta ni corrige perspectiva de la fotografía guardada o compartida**.
- El contorno sigue sin proporcionar una estimación calibrada de **perpendicularidad** respecto a la superficie. La señal verde del nivel Core Motion solo indica inclinación respecto a la gravedad.
- Todavía no hay congelación de imagen para editar: si el usuario mueve el móvil mientras ajusta, el contorno puede dejar de coincidir con el objeto. Mantener teléfono quieto o usar apoyo; un modo de edición sobre fotograma congelado será mejora posterior.
- No se puede editar un objeto sin que Vision haya detectado algún cuadrilátero y se haya seleccionado. El modo manual solo corrige un candidato; trazado completamente desde cero queda pendiente.
- El ajuste está normalizado a la vista previa actual; cambiar de orientación/tamaño durante la edición no está validado. Probar primero en **retrato**.
- Las condiciones más estrictas pueden rechazar planos muy escorzados. No aplicar tolerancias como garantía universal.

## Prueba física en iPhone

- [ ] GitHub Actions compila DEV 0.1.10 y `SurfaceGeometryTests` pasa en simulador.
- [ ] En Mac limpio, `git status --short`, `git pull --ff-only`; `⌘B` y `⌘R`. Encabezado «DEV 0.1.10».
- [ ] Sobre una hoja de papel rectangular, pulsar «Buscar contorno», tocar la hoja y ver el contorno menta.
- [ ] Pulsar «Ajustar esquinas»: desaparecen los paneles que tapaban la hoja; aparecen cuatro puntos menta en los vértices.
- [ ] Arrastrar la **esquina superior derecha** hasta coincidir con el borde real. Comprobar que el lado superior deja de cruzar la hoja en diagonal.
- [ ] Arrastrar las otras esquinas y verificar que se pueden situar en sus puntos reales y que el contorno permanece convexo.
- [ ] «Listo» conserva la corrección en la pantalla de cámara; «Ajustar esquinas» vuelve a permitir editarla.
- [ ] «Restaurar» descarta la corrección y recupera el contorno de Vision.
- [ ] Probar «Buscar contorno» de nuevo: borra ajustes anteriores y ofrece candidatos frescos.
- [ ] Probar «Otro», primer toque sin contornos previos, giro retrato/paisaje, fondo/reanudación; registrar comportamientos sin declarar modos no verificados.
- [ ] Confirmar que el nivel compacto sigue actualizándose en la pantalla normal; el modo edición no convierte el nivel gravitatorio en una medición de perpendicularidad al papel.
- [ ] Fotografiar en Ligera y Compartir, comprobar dimensiones/bytes, «Repetir», original y uso de hoja de compartir sin regresiones.
- [ ] Medir rendimiento de búsqueda estricta (si usa respaldo, puede analizar el mismo fotograma dos veces), especialmente retardo perceptible.
- [ ] Nunca poner fotografías personales o documentos reales en el repositorio público.

## Después del hito

Hacer que la detección automática encuentre consistentemente cuatro bordes; congelar el fotograma durante edición y, si el usuario lo elige, **recortar/enderezar una copia** de la fotografía **sin modificar nunca el original**. La perpendicularidad geométrica 3D se abordará aparte con cámara calibrada, incertidumbre y pruebas físicas.

Fuentes Apple:
- https://developer.apple.com/documentation/vision/vndetectrectanglesrequest
- https://developer.apple.com/documentation/vision/vndetectrectanglesrequest/quadraturetolerance
- https://developer.apple.com/documentation/uikit/uipangesturerecognizer
