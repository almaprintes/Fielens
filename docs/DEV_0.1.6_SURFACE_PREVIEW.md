# DEV 0.1.6 — Detectar y elegir superficies en la cámara

**Fecha:** 2026-10-26.
**Estado:** implementación en rama `main`; compilación, tests y comportamiento real en iPhone pendientes de registro.

## Alcance de esta iteración

Primer flujo para la idea del creador: señalar una superficie física en la cámara, detectar su contorno y seleccionar el objeto con un toque. Se comienza deliberadamente con **cuadriláteros** (hojas, fotografías impresas, cuadros, azulejos, carteles rectangulares). Esto no promete segmentación universal de todos los objetos, ni la normal 3D de un plano, ni perpendicularidad.

### Comportamiento

- Cámara sigue activa con nivel gravitatorio y selector de resolución de fotografía.
- Pulsar **«Buscar contorno»** analiza un único fotograma de vídeo mediante Vision. Se dibujan candidatos con **línea blanca discontinua**.
- Tocar dentro de un candidato selecciona el más pequeño que contenga el toque; se destaca **en verde menta**. No interpretar el color como «perpendicular».
- Tocar la escena antes de buscar dispara el análisis de un fotograma e intenta seleccionar el cuadrilátero que contiene el toque.
- La instrucción aclara «Contorno seleccionado · No mide perpendicularidad» y recuerda **volver a buscar si se mueve el móvil**. No hay seguimiento continuo; una superposición de un análisis anterior puede quedar desalineada al mover el teléfono.
- Sin candidato, informa de la ausencia y permite volver a buscar. El disparador sigue utilizable; no se bloquea la fotografía por fallar Vision.
- Salir de la cámara o fotografiar cancela scans pendientes y quita candidatos; al volver con Repetir se restaura el flujo de captura normal. Los sensores Core Motion siguen su propio ciclo de vida.

### Arquitectura técnica

- `SurfaceFrameSampler.swift`: `AVCaptureVideoDataOutputSampleBufferDelegate` con `alwaysDiscardsLateVideoFrames = true`. Acepta **solo un escaneo solicitado** y procesa en cola serial. La petición caduca tras 4 segundos si no llega frame; el timeout está vinculado a un identificador para no cancelar escaneos nuevos. No guarda frames, no llama red y no analiza en cada fotograma.
- `CameraSession.swift`: salida secundaria de vídeo **opcional**. Si la sesión no puede añadirla, la cámara fotográfica debe continuar funcionando y el escaneo comunicará no disponible.
- `RectangularSurfaceDetector.swift`: Vision `VNDetectRectanglesRequest` sobre `CVPixelBuffer` (orientación experimental `.right` para cámara trasera en modo retrato).
- `CameraViewModel.swift`: estados `surfaceCandidates`, selección, error/mensaje, invalidación por generación al salir/volver y al capturar.
- `SurfaceCoordinateMapper`: transforma Vision normalizado origen inferior izquierdo a dispositivo origen superior izquierdo.
- `CameraPreview.swift`: overlay `CAShapeLayer` y evento táctil. `AVCaptureVideoPreviewLayer.layerPointConverted(fromCaptureDevicePoint:)` y `captureDevicePointConverted(fromLayerPoint:)` transforman escala, recorte `.resizeAspectFill` y espacio del dispositivo.
- `ContentView.swift`: botón Buscar contorno, estado de búsqueda y toque directo. Se mantienen cámara, nivel y las resoluciones de DEV 0.1.5.
- `SurfaceGeometryTests.swift`: casos de cuadriláteros convexos inclinados, transformación de coordenadas y selección.

**Punto crítico:** la conversión Vision→CaptureDevice está simplificada bajo la hipótesis retrato/cámara trasera sin rotación personalizada de la conexión. Debe validarse físicamente con un patrón que tenga esquinas marcadas; si el contorno aparece rotado, reflejado o desplazado NO corregirlo a ojo: inspeccionar `CMSampleBuffer` y el `AVCaptureVideoPreviewLayer.connection` en el dispositivo, calibrar la orientación y escribir test de transformación.

## Riesgos y limitaciones

1. El añadido de `AVCaptureVideoDataOutput` puede afectar a formatos/fps/resolución máxima de cámara. **Comparar con DEV 0.1.5**, especialmente resolución 48,77 MP, enfoque, velocidad y preview. No darlo por seguro sin prueba.
2. El delegado recibe callbacks de video aunque Vision solo se ejecute bajo petición; medir uso de CPU/batería y evaluar desconexión de salida cuando no se use.
3. No hay seguimiento: las líneas pueden quedar «congeladas» sobre la escena al mover el dispositivo. Se avisa al usuario y «Buscar contorno» renueva.
4. El contorno reconoce bordes rectangulares, no reconoce semánticamente «DNI», «documento» o «cuadro». Puede seleccionar bordes incorrectos; un toque reduce ambigüedad, no resuelve todas las escenas.
5. **No existe nivel relativo al objeto.** El nivel verde de Core Motion solo mide gravedad; contorno menta solo indica selección.
6. La aplicación no guarda ni transmite fotogramas de detección. No incluir fotos personales en GitHub público.

## QA en iPhone antes de cerrar hito

- [ ] `git pull --ff-only`, Xcode `⌘B`, `⌘R`; verificar cámara en directo y nivel sin regresión.
- [ ] App indica DEV 0.1.6; pantalla inicial con «Buscar contorno» y texto accesible.
- [ ] Encuadrar hoja A4 sobre fondo contrastado, luz uniforme y orientación **retrato**. Pulsar Buscar contorno. Verificar que la línea blanca recorre las **cuatro esquinas correctas** y no queda desplazada por recorte.
- [ ] Tocar dentro de la hoja: contorno menta seleccionado. Tocar otra superficie rectangular y comprobar selección. Tocar antes de buscar en sesión nueva también inicia análisis.
- [ ] Colocar foto pequeña encima de hoja A4 y tocar la foto: debe preferir el contorno menor si Vision detecta ambos.
- [ ] Mover el móvil: pulsar Buscar contorno de nuevo; no confiar en overlay anterior. Medir latencia de búsqueda y fluidez perceptible.
- [ ] Probar luz desigual/sombra, papel sin contraste, ausencia de rectángulos: el botón Fotografía nunca debe bloquearse.
- [ ] Probar dispositivo apaisado: **registrar orientación/distorsión sin considerar el modo validado todavía**.
- [ ] Elegir «Ligera» antes de disparar y fotografiar: en revisión debe seguir mostrando ~1,92 MP, y «Original» debe mostrar 48,77 MP según la captura real del teléfono; compartir ambas.
- [ ] Confirmar foto original y nivel Core Motion con y sin escaneo. Comprobar calentamiento y bloqueo del iPhone después de varios intentos.
- [ ] Volver a cámara con Repetir y entrar/salir de segundo plano; limpiar candidatos y evitar quedarse con «Analizando» eternamente.
- [ ] Ejecutar tests Swift de `SurfaceGeometryTests` y `PhotoExportTests` y documentar SHA/run completo de CI.
- [ ] Guardar un registro anónimo de resultados en `docs/DEVELOPMENT_LOG.md` con commit, iOS, dispositivo y fallos; **sin fotografías personales**.

## Siguiente hito

Después de conseguir detección confiable y selección por toque, pasar a seguimiento controlado y estimación del plano 3D con intrínsecos calibrados y condiciones de confianza. No marcar «perpendicularidad perfecta» sin un experimento geométrico reproducible.

Referencias Apple: `VNDetectRectanglesRequest`, `VNImageRequestHandler(cvPixelBuffer:orientation:options:)`, `AVCaptureVideoDataOutput`, `AVCaptureVideoPreviewLayer`.
