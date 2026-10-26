# Fielens DEV 0.1.9 — Corrección de proyección Vision a cámara

**Fecha:** 2026-10-26, tras pruebas reales de 10:15–10:16.
**Estado:** implementación en rama `main`, build 10. Compilación, pruebas de simulador y precisión en iPhone se registran por separado; no se declara resuelto solo por subir código.

## Evidencia observada

El creador envió dos capturas de pantalla reales de DEV 0.1.8, con una hoja manuscrita sobre una superficie estampada y un teclado encima. En cámara, el cuadrilátero seleccionado en verde menta aparece **muy desplazado respecto a la hoja física**, incluyendo parte importante del fondo, a pesar de que el toque se prueba sobre el mismo polígono dibujado desde 0.1.8.

En la pantalla de revisión, **Compartir 2400 px** genera **1800 × 2400 píxeles (4,32 MP), aprox. 1,2 MB**, tal como se esperaba. Nivel gravitatorio compacto: X −1,1°, Y −3,1°, naranja. La captura continúa mostrando el entorno porque todavía **no hay recorte del objeto**; eso no es un fallo nuevo de exportación, sino funcionalidad futura pendiente de decisión. **NO subir capturas con texto/datos reales a GitHub público.**

### Causa probable localizada por auditoría de fuentes

- La `SurfaceFrameSampler` invoca `VNImageRequestHandler(cvPixelBuffer:orientation: .right)`: Vision orienta un buffer que normalmente es horizontal a vertical, rotándolo **90° en sentido horario**.
- La conversión de `SurfaceCoordinateMapper.capturePoint(fromVision:)` hacía solo `(x, 1-y)`, como si el análisis no hubiera rotado la imagen.
- `AVCaptureVideoPreviewLayer.layerPointConverted(fromCaptureDevicePoint:)` espera coordenadas normalizadas del **sensor sin rotar**, origen superior izquierdo, y aplica por su cuenta el recorte y rotación de la vista. Al pasar directamente el X de Vision, el contorno puede aparecer desplazado/rotado respecto a la escena. Fuente: documentación oficial de Apple del método.
- Incluso con hit testing en el polígono *visible* (arreglo DEV 0.1.8), si la **proyección del polígono es errónea** tanto el dibujo como el toque permanecen asociados al lugar equivocado.

### Cambios DEV 0.1.9

1. `SurfaceCoordinateMapper`: para imagen Vision `.right` con origen abajo-izquierda, transformar al espacio RAW arriba-izquierda como **`(xRaw, yRaw) = (1 - yVision, 1 - xVision)`**, no solo invertir Y.
2. `SurfaceGeometryTests`: validar ida/vuelta con tolerancia y las cuatro esquinas de una imagen rotada, además de puntos asimétricos. No basta un test invertible: una transformación incorrecta también puede ser su propia inversa.
3. `CameraSession`: para videoDataOutput fijar explícitamente `videoRotationAngle = 0`, **si está soportado**, antes de iniciar cámara. Evitar rotación física de fotogramas y separar de la orientación del preview. Si no está soportado, no afirmar que la detección es compatible.
4. `SurfaceFrameSampler`: rechazar fotogramas que no tengan ancho mayor que alto pese a rotación 0; en lugar de dibujar un contorno geométricamente inválido, mostrar mensaje de orientación incompatible y mantener disponible la fotografía.
5. Mantener `SurfaceScreenSelector` (hit testing en contorno renderizado) y los perfiles de resolución como estaban.
6. Versión DEV 0.1.9, build 10.

**Hipótesis aún por verificar:** Preview y videoDataOutput deben compartir posición/FOV compatible, además de la orientación nativa; la lente estabilizada o el formato de vídeo podrían usar una región ligeramente distinta. Se necesita una prueba física para saber si la transformación matemática corregida hace coincidir la hoja. No desplazar la línea por píxeles fijos «a ojo».

## Pruebas en iPhone (obligatorias)

- [ ] Confirmar CI verde (compilación y tests) para el SHA exacto de DEV 0.1.9.
- [ ] `git status --short` antes de actualizar; `git pull --ff-only` si el proyecto está limpio; `⌘B` y `⌘R`.
- [ ] En **retrato**, colocar **hoja A4 sin datos personales** sobre fondo contrastado, iluminada y sin cables por encima. Estar quieto. Pulsar Buscar contorno.
- [ ] Fotografiar pantalla de cámara (sin documento privado): comparar visualmente las **cuatro esquinas dibujadas** con las cuatro esquinas físicas. Si la línea sigue desplazada, anotar dirección, escala y rotación; distinguir error de reconocimiento Vision de error de mapeo.
- [ ] Tocar centro de hoja, tercio superior y tercio inferior; cada toque debe seleccionar el mismo rectángulo visible. Probar fondo fuera de la hoja, botón Otro y toque directo antes de pulsar Buscar.
- [ ] Mover el móvil tras escanear: el trazo antiguo no sigue físicamente la hoja; la búsqueda manual debe actualizarlo. No considerar esa limitación un algoritmo de seguimiento.
- [ ] Capturar con perfil Compartir: verificar ~1800 × 2400 y 4,32 MP de salida, sin regresión; cambiar a Original y comprobar dimensiones/peso según captura.
- [ ] Repetir, cambiar resolución, compartir, nivel gravitatorio, suspensión y vuelta a primer plano. Comprobar si el vídeo se sigue entregando en ancho > alto.
- [ ] Probar retrato con hoja horizontal sobre mesa y hoja vertical: el cálculo de perpendicularidad **todavía no existe**. No afirmar nivelado respecto a documento.
- [ ] No publicar ni subir imágenes con nombres, números o texto personal en GitHub público.

### Después de estabilizar cuatro esquinas

- Evaluar **recorte opcional del documento seleccionado**, dejando siempre intacto JPEG original y ofreciendo la versión de encuadre completo. La selección de contorno todavía no modifica ni recorta el JPEG resultante.
- Diseñar seguimiento de contorno para evitar que su posición quede obsoleta al desplazar el dispositivo.
- Solo después estudiar estimación calibrada de la normal del plano y perpendicularidad.

## Referencias

- https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/layerpointconverted(fromcapturedevicepoint:)
- https://developer.apple.com/documentation/avfoundation/avcaptureconnection/videorotationangle
- https://developer.apple.com/documentation/vision/vnimagerequesthandler


## Verificación cloud

- [GitHub Actions run 40306740823](https://github.com/almaprintes/Fielens/actions/runs/40306740823), SHA `31c06ce433c145fd255107fb6d88ddc4d0a58754`: **Compile iOS without signing = SUCCESS** con Xcode 26.6.
- **Swift unit tests on iOS simulator: queued** en la última comprobación; no afirmar tests verdes mientras no terminen.
- **Dispositivo físico: todavía sin prueba DEV 0.1.9**. Validar visualmente cuatro esquinas antes de dar por corregido el problema.
