# DEV 0.1.12 — El objeto detectado debe llenar la fotografía

**Fecha:** 2026-10-26, 11:50 (Tenerife)
**Motivación:** tras ensayar la detección automática DEV 0.1.11, el creador indica que ya resulta relativamente fácil y que el sistema detecta mejor la superficie, **pero el JPEG final incluye mucha mesa/fondo en vez de únicamente el objeto**.
**Estado:** implementado en GitHub main. La compilación y tests finales y, sobre todo, la corrección visual en un iPhone **aún no están confirmados**.

## Qué resuelve

La detección y el contorno en el vídeo no recortaban el JPEG real. El disparador `AVCapturePhotoOutput` fotografiaba todo el campo de visión y `PhotoExportService` reducía píxeles pero conservaba el fondo. Ni seleccionar un contorno ni el nivel digital modificaban la imagen.

DEV 0.1.12 añade el **reencuadre automático al objeto en la imagen que se visualiza y comparte**, solo cuando se encuentra un contorno rectangular fiable **en la fotografía capturada**. Usa `VNDetectRectanglesRequest` para localizar las cuatro esquinas y Core Image `CIFilter.perspectiveCorrection()` para obtener el plano rectificado, normalmente sin la mesa que lo rodea. No se basa en reutilizar las coordenadas de la preview porque vídeo y foto pueden tener encuadres, resolución u orientación diferentes.

Por defecto el ajuste del objeto está **activado** para los perfiles Ligera/Compartir/Detalle. La revisión dispone de «Ajustar automáticamente al objeto» por si la detección no interpreta bien una escena. Si falla el algoritmo o no se cumple confianza/tamaño mínimos, **se conserva la foto completa** y se muestra un aviso honesto. El perfil **Original** siempre entrega el JPEG exacto y completo devuelto por la cámara, sin recortes ni reescrituras ni modificación de EXIF.

## Implementación

- `SurfacePhotoProcessor.swift`: escoge un cuadrilátero de la **captura actual**, descarta detecciones inválidas, demasiado pequeñas o demasiado amplias; aplica corrección perspectiva de cuatro puntos; impide resultados colapsados y controla límites máximos del JPEG exportado.
- `PhotoExportService.swift`: obtiene primero raster reducido/orientado con ImageIO. Para perfiles derivados, corrige la perspectiva cuando `frameObject` está habilitado y hay detección fiable. Devuelve `PreparedPhoto.didFrameObject`, con resolución y peso leídos del JPEG final. El archivo original nunca cambia.
- `ContentView.swift`: previsualiza el resultado ajustado, muestra «Objeto ajustado y enderezado» solo cuando ocurrió, o «No hubo contorno fiable · Imagen completa» si no. Toggle de ajuste para comparar con foto sin tocar. `reviewKey` incluye valor del toggle, para recalcular al cambiar.
- `SurfacePhotoProcessorTests.swift`: pruebas sobre imagen sintética para reducir dimensiones al corregir perspectiva, limitar lado mayor, rechazar cuadriláteros degenerados y preservar byte a byte el original incluso cuando se solicita el ajuste.
- DEV 0.1.12, build 13.

## Límites conocidos / próximos problemas que debemos resolver

1. **Primera versión heurística:** si hay varios rectángulos en la fotografía final, escoge un candidato según tamaño, centrado y confianza. Podría elegir un borde equivocado respecto al objeto destacado durante el vídeo; está pendiente asociar de forma calibrada el objetivo elegido en preview con el rectángulo de la captura completa.
2. **No confundir corrección de perspectiva con perpendicularidad real:** una foto enderezada digitalmente no recupera nitidez perdida, no equivale a orientar la cámara perpendicularmente ni permite rectificar objetos 3D.
3. Requiere cuatro esquinas identificables. Para objetos irregulares, pegatinas o fotografías sin bordes contrastados se estudiarán segmentación y recorte por máscara después.
4. **Optimización añadida:** cuando el recorte está activado, el análisis parte de un raster de trabajo de hasta **4800 píxeles de lado mayor** (sin cargar los 48 MP completos); se endereza primero y solo entonces se limita a 1600/2400/4000 píxeles según el perfil. Si falla detección, se genera una nueva copia de toda la escena con el tamaño de salida elegido. Aún puede perder resolución óptica si el objeto ocupa una parte pequeña del fotograma y no garantiza todos los megapíxeles del preset.
5. No recortar ciegamente: al no hallar contorno seguro, el usuario conserva el fotograma completo y puede intentar otro encuadre. No hay promesa de resultado automático para todas las escenas.
6. Todo local. No se suben fotos de usuarios ni un DNI real a GitHub.

## Protocolo de prueba obligatorio

- [ ] Xcode 26.6 GitHub Actions del SHA final en verde y tests Swift en simulador correctos.
- [ ] En Mac, `git status --short` y `git pull --ff-only` con cambios locales limpios, abrir Xcode, `⌘B` y `⌘R`.
- [ ] Fotografía de una hoja A4 con fondo distinto: selecciona Compartir 2400 px, deja el ajuste automático activado y dispara. La revisión debe mostrar **casi solo el papel**, sin toda la mesa.
- [ ] Comparar desactivando y reactivando «Ajustar automáticamente al objeto» en revisión **sin repetir foto**: debe alternar foto completa/foto corregida. La vista previa y el peso/resolución corresponden al archivo que se compartirá.
- [ ] Con Detalle (4000) y Ligera (1600) verificar máximos y legibilidad del texto de prueba; comprobar que la corrección geométrica no distorsiona texto, caras ni ilustraciones.
- [ ] Con Original comprobar que imagen sigue completa y que JPEG y metadatos se conservan sin convertir. Original debe permitir recuperar una foto mal detectada.
- [ ] Probar hoja algo inclinada en perspectiva: el resultado debería rectificar sus cuatro lados; examinar si corta esquinas o agrega zonas negras.
- [ ] Probar varios rectángulos, DNI de prueba ficticio sobre una hoja grande, foto dentro de un marco, mesa de color similar, baja luz. Anotar **qué objeto recorta** y errores sin publicar imágenes personales.
- [ ] Si no encuentra contorno, comprobar que no recorta falsamente y muestra mensaje de ausencia de detección fiable.
- [ ] Verificar que la vista de cámara automática de 0.1.11 sigue fluida, Core Motion funciona, las fotos se realizan a resolución completa como fuente y Repetir/Guardar en Archivos operan.
- [ ] Registrar tiempos de procesamiento en iPhone y memoria/temperatura para perfiles y escenas. CI en simulador no sustituye esta prueba.

**Puerta para cerrar el hito:** captura real en iPhone con un único documento rectangular, corrección que llena el resultado sin mutilar esquinas, alternancia de ajuste, original intacto y sin caída notable del rendimiento.
