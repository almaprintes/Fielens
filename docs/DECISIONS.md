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
