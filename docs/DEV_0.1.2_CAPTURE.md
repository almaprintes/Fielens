# DEV 0.1.2 — Captura fotográfica original y revisión

**Estado:** primera fotografía y lectura de resolución confirmadas por el creador en iPhone (25/10/2026 23:17); QA y exportación pendientes.
**Fecha:** 2026-10-25.
**Ámbito:** captura manual de una sola foto. La vista previa de DEV 0.1.1 ya se ha confirmado en iPhone, y ya se ha reportado una primera fotografía real de la DEV 0.1.2.

## Implementación prevista y decisiones

- `CameraSession.swift`: salida `AVCapturePhotoOutput`, una captura cada vez, petición de JPEG y priorización de calidad, dimensiones máximas válidas del formato activo cuando la API las comunica.
- `CapturedPhoto.swift`: conserva exactamente `AVCapturePhoto.fileDataRepresentation()` (incluidos metadatos asociados) y extrae ancho/alto y tamaño real para la interfaz. No realiza escala, recorte ni recompresión.
- `CameraViewModel.swift`: gestiona captura, errores, revisión y repetir. Detiene sesión mientras se revisa la foto.
- `ContentView.swift`: botón disparador accesible, revisión y compartir el JPEG original con la hoja de compartir del sistema.
- `project.pbxproj`: `MARKETING_VERSION 0.1.2`, build 3.
- Directorio temporal privado `Fielens-Capture-Preview`: descartar borra el archivo, una nueva ejecución limpia las imágenes temporales de sesiones anteriores. **No equivale a guardado duradero**. El usuario debe guardar/exportar explícitamente desde Compartir. En caso de cierre inesperado podrían quedar archivos temporales hasta el próximo inicio o limpieza del sistema; esta limitación debe verificarse.
- Solo se requiere permiso de cámara. Fotos, Internet, cuenta y servidor quedan fuera de alcance.

## Pruebas obligatorias en iPhone

- [ ] `git pull --ff-only` en `~/Developer/Fielens` y `git status -sb`.
- [ ] Abrir Xcode, seleccionar iPhone físico, `⌘B` — anotar `Build Succeeded` o error exacto.
- [x] `⌘R` — ejecución de la versión con cámara y disparo inferida de la foto reportada; queda pendiente prueba específica de permiso.
- [ ] Capturar un patrón A4 con cuadrícula y letras, sin datos privados.
- [x] Capturar y registrar las dimensiones reportadas en la pantalla de revisión: **8064 × 6048 px, 48,77 MP, 11,5 MB**. Falta revisar encuadre y orientación.
- [x] Compartir → Guardar en Archivos **funciona según usuario**; archivo en Archivos indicado como **11,7 MB**. **Pendiente** confirmar dimensiones/formato e identidad de bytes (la app mostró ~11,5 MB). Los servicios de terceros pueden alterar los ficheros; comparar el original en Archivos, no la copia subida al chat.
- [x] Pulsar Repetir: el creador confirma funcionalidad (23:28); eliminación exacta del fichero temporal y múltiples ciclos todavía sin medir.
- [ ] Hacer varios ciclos foto→repetir→foto para localizar bloqueos o consumo excesivo de memoria.
- [ ] Bloquear/desbloquear y salir/volver antes y después de foto; registrar cualquier cámara congelada o error.
- [ ] Comprobar que el permiso de Fotos no se solicita.
- [ ] Confirmar visualmente si la vista previa recorta respecto al archivo final; `.resizeAspectFill` puede hacerlo.
- [ ] Comprobar que el modo paisaje y vertical no giran ni recortan inadecuadamente la imagen final; la orientación EXIF debe preservarse.
- [ ] Ejecutar las pruebas automáticas de `OriginalPhotoTests` y registrar resultados.
- [ ] Registrar modelo, iOS, fecha, hora, commit y observaciones. No subir las fotos personales ni documentos al repositorio público.

## Advertencias a comprobar

- La resolución máxima *solicitada* no garantiza la resolución entregada; registrar los píxeles reales. Se escogerá más adelante la mejor política de captura tras ensayos de calidad y rendimiento.
- El archivo conserva metadatos EXIF de cámara; la limpieza opcional de metadatos en copias compartidas será trabajo posterior. No declarar «sin metadatos».
- Al compartir, el usuario controla la exportación; Fielens no envía el archivo automáticamente.
- Todavía no existe nivel, perpendicularidad, detección de bordes, corrección de perspectiva, OCR ni filtros.
- No publicar públicamente la app hasta verificar las normas de Shipaton 2027.

## Criterio de aceptación

La función se da por validada solo si iPhone completa un ciclo `abrir cámara → disparar → revisar → repetir → compartir`, guardando un archivo JPEG íntegro y obteniendo datos de resolución verificables. Un fallo de compilación o ejecución mantiene el hito abierto.

## Primer resultado de campo — 2026-10-25 23:17

- **Origen del dato:** mediciones mostradas en Fielens según informe directo del creador. No hay archivo JPEG adjunto ni logs de Build; no se han inspeccionado los bytes del fichero exportado.
- **Imagen:** 8064 × 6048 = 48.771.072 píxeles (48,77 MP); relación 4:3; tamaño JPEG indicado: ~11,5 MB.
- **Aprobado provisionalmente:** dispositivo produce fotografía, y la app presenta los metadatos de resolución y peso al usuario.
- **Pendiente de aprobar:** Guardar en Archivos y verificar integridad del JPEG, repetir/discard y múltiples capturas, rotaciones, claridad de la imagen, tests automáticos y comportamiento al suspender/reactivar.
- **Resultado:** H-008 en curso con evidencia real parcial, no terminado.

## Imagen de ensayo recibida — 2026-10-25, 23:22

Se recibió una imagen de ratón/teclado, apta para observación visual cualitativa: contraste de iluminación, sombras e irregularidad aparente de nitidez. La copia recibida fue inspeccionada como **JPEG 1536 × 2048, 503.960 bytes, sin EXIF**. No se puede tratar como el original de **8064 × 6048, ~11,5 MB** reportado anteriormente.

**Consecuencia de QA:** mantener pendientes la integridad de exportación y los ciclos repetir→repetir. No subir imagen de prueba al repositorio. Solicitar confirmación del usuario de las operaciones e inspección de un archivo guardado directamente desde Fielens en Archivos sin intermediación de servicios que puedan recomprimir.

## Confirmación del creador — 2026-10-25, 23:25

El fichero se guardó desde Fielens mediante «Compartir original → Guardar en Archivos» y ocupa **11,7 MB** según Archivos. El chat recibió una copia más pequeña; atribuirlo a ChatGPT es una hipótesis plausible, no prueba. En concreto, **guardar y encontrar el archivo original está verificado funcionalmente**, mientras que la preservación bit a bit y dimensiones de ese archivo guardado **aún no se han medido**. Falta asimismo la prueba de Repetir.

## Confirmación adicional — 2026-10-25 23:28

El creador responde «funciona» tras probar **Repetir**. Se da por confirmado el comportamiento funcional de repetir fotografía. No se equipara a una prueba automatizada de borrado, múltiples ciclos o comparación de hash. Se continúa con el nivel en DEV 0.1.3 sin cerrar estas tareas de QA.
