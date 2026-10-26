# Registro de decisiones

Formato: ID, fecha, estado, decisión, justificación y consecuencias.

## D-001 — 2026-10-23 — Aceptada — Alcance universal

La cámara cubrirá soportes físicos para conservar/compartir, no solo documentos; inicialmente se evaluarán superficies planas.

## D-002 — 2026-10-23 — Aceptada — Asistencia previa a la captura

El producto guiará en tiempo real encuadre, orientación, iluminación y enfoque, en lugar de depender de reparar malas capturas.

## D-003 — 2026-10-23 — Aceptada — Privacidad y fidelidad

Procesamiento local por defecto. Mantener original y no inventar texto, color ni detalle.

## D-004 — 2026-10-23 — Aceptada — Nombre Fielens

El creador elige «Fielens», por «fiel» + «lens». Todavía se debe verificar viabilidad de registro de marca, dominios y disponibilidad en tiendas. Nombre de proyecto decidido; exclusividad comercial no verificada.

## D-005 — 2026-10-23 — Aceptada — Objetivo Shipaton 2027

Preparar el mejor producto posible a lo largo de 10-11 meses, con objetivo orientativo agosto/septiembre 2027. Comprobar bases de 2027 antes de primera publicación pública.

## D-006 — 2026-10-23 — Pendiente — Tecnología

No decidir aún el framework. Probar cámara, sensores y visión en iPhone real; analizar coste futuro de Android.

## D-007 — 2026-10-23 — Observación — Visibilidad del repositorio

GitHub informa que almaprintes/Fielens es público. No confundir publicación del código con lanzamiento público de la app. Decidir visibilidad final antes de incluir materiales reservados.

## D-008 — 2026-10-25 — Aceptada provisionalmente — Captura JPEG temporal en DEV 0.1.2

La primera captura utiliza `AVCapturePhotoOutput`; se solicita JPEG a máxima resolución disponible y se preservan los bytes devueltos por `fileDataRepresentation()` sin tratamientos propios. El archivo se conserva temporalmente en espacio privado para revisión y compartir. No se crea una biblioteca permanente ni se pide permiso para Fotos. Esto **no** garantiza que Apple no aplique procesamiento propio de cámara; la fidelidad real requerirá medición. No implica que se haya validado todavía la implementación en dispositivo.

## D-009 — 2026-10-25 — Aceptada — Evidencias e hitos por versión

Mantener `docs/MILESTONES.md` y `docs/DEVELOPMENT_LOG.md`, con estados separados (implementado, compilado, probado, validado), errores reproducibles, dispositivo utilizado y pruebas pendientes. Cada DEV debe tener protocolo verificable. La publicación de código no equivale a validación.

## D-010 — 2026-10-25 — Provisional para experimento — Nivel digital de dos ejes

Se adopta Core Motion (`CMMotionManager`) y `CMDeviceMotion.gravity` en el prototipo iOS; muestreo objetivo 20 Hz, suavizado de gravedad (alfa 0,25), bloqueo de falsas lecturas en pose invertida y tolerancia inicial ±2°. La tolerancia está **sin calibrar** y no certifica precisión. La lectura es relativa al horizonte, jamás prueba perpendicularidad respecto a una hoja o cuadro inclinado. Detener sensores fuera de la vista de cámara. Evaluar el rendimiento, orientación horizontal y errores en hardware real antes de dar la decisión por definitiva.

## D-011 — 2026-10-25 — Aceptada para prototipo — Selección por toque del soporte

Permitir que el usuario elija el soporte que quiere capturar tocando la imagen; detector de cuadriláteros para primeras superficies rectangulares con Apple Vision. Debe mostrarse contorno y confirmarse, con corrección manual en iteración posterior. El toque no equivale a prueba de planitud, normal del plano o perpendicularidad. Priorizar experiencia local, accesible y sin subida de fotos.

## D-012 — 2026-10-25 — Decisión experimental — Nivel relativo al plano, no un falso «perfecto»

Mantener Core Motion de gravedad como modo independiente y auxiliar; estudiar estimación de normal del plano mediante cámara calibrada, geometría de cuadrilátero/líneas de fuga y fusión de movimiento. En objetos planos irregulares o volumétricos, ofrecer métodos dependientes de capacidades (ARKit/otras observaciones) y mostrar incertidumbre. Nunca marcar verde por un rectángulo detectado sin pose validada. Ver `docs/SURFACE_TARGETING_DESIGN.md`.

## D-013 — 2026-10-26 — Aceptada para DEV 0.1.4 — Resolución de envío independiente de captura

Priorizar legibilidad y ligereza en mensajería; permitir al usuario seleccionar una de cuatro resoluciones antes del disparo o en revisión, generando **una copia temporal reducida únicamente al compartir**. Preservar el JPEG original de captura para compartirlo sin transformación si lo elige. No confundir resolución con calidad; medir nitidez, tamaño, tiempo, orientación y formato reales. Usar 2400 px lado mayor como predeterminado experimental y limitar ampliación. Evitar copiar EXIF a los derivados; advertir de metadatos en Original. La captura nativa a menor resolución se evaluará tras comparar rendimiento y texto pequeño.

## D-014 — 2026-10-26 — Aceptada DEV 0.1.5 — La resolución elegida define el resultado visible

La calidad elegida por el usuario antes de disparar o después debe corresponder a **la imagen que Fielens presenta y comparte**. No mostrar el número de megapíxeles del JPEG maestro cuando el usuario ha elegido Ligera. Para el prototipo, mantener solo temporalmente el JPEG de máxima resolución como fuente editable y preparar archivo reducido de salida con metadatos reales; compartir ese archivo exacto. A futuro experimentar con adquisición directamente a menor resolución y medir coste, sin destruir la fuente por defecto ni prometer mejoras no probadas.

## D-015 — 2026-10-26 — Provisional DEV 0.1.6 — Detección bajo demanda

No iniciar Vision continuamente hasta medir latencia, geometría y consumo. El prototipo analiza un único frame cuando el usuario pulsa Buscar contorno o toca el objeto; dibuja cuadriláteros y permite seleccionar uno, manteniendo la fotografía original y el nivel de gravedad independientes. El contorno seleccionado no certifica ángulo ni planitud; confirmar alineación de coordenadas en iPhone y advertir que la superposición queda obsoleta tras mover el móvil. Si la salida secundaria de vídeo afecta a la captura 48 MP, priorizar preservar la calidad fotográfica y replanificar la arquitectura.

## D-016 — 2026-10-26 — Experimental DEV 0.1.9 — Alinear Vision con sensor sin rotar

No compensar visualmente por píxeles arbitrarios el desplazamiento de contornos. Corregir el marco de referencia: `VNImageRequestHandler` con orientación `.right` sobre buffer no rotado requiere deshacer 90° para pasar los puntos a `AVCaptureVideoPreviewLayer.layerPointConverted(fromCaptureDevicePoint:)`; transformar `(x,y) → (1-y,1-x)`. Fijar `videoRotationAngle=0` en VideoDataOutput, comprobar ancho > alto y bloquear únicamente detección (no la cámara) cuando no se cumpla la suposición. Estado sujeto a prueba física en iPhone y recalibración de cualquier zoom/crop diferente entre salidas.
