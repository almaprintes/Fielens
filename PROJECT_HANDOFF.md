# PROJECT_HANDOFF — Fielens

**Actualizado:** 2026-10-25 · DEV 0.1.2

## Contexto

Fielens es una cámara de captura asistida universal (no solo escáner de documentos), privada por defecto y fiel a la imagen original. Objetivo Shipaton 2027 (agosto/septiembre orientativo), sujeto a las bases oficiales. Nombre de proyecto elegido, validación registral pendiente.

- GitHub: `almaprintes/Fielens`, rama `main` (repositorio público).
- Mac del creador: `~/Developer/Fielens`.
- Proyecto: `apps/ios/Fielens/Fielens.xcodeproj`.
- Entorno reportado: Xcode 26.6, macOS 26.5, iOS 26.5 / iPhone físico.
- Documentación histórica: [MILESTONES](docs/MILESTONES.md) y [DEVELOPMENT_LOG](docs/DEVELOPMENT_LOG.md).
- Normas del proyecto: [AGENTS.md](AGENTS.md).

## Estado realmente verificado

- Instalación de plataforma, firma Personal Team y primera ejecución Hello World: **confirmadas** por el creador.
- DEV 0.1.1: AVFoundation cámara y permiso, primera compilación fallida corregida, cámara en directo **confirmada en iPhone** por el creador («funciona!!!», 25/10/2026 ~23:00). No hay mediciones de latencia ni regresiones documentadas.
- DEV 0.1.2: **primera captura funcional reportada por el creador en el iPhone el 25/10/2026 a las 23:17**. Resolución 8064 × 6048 px (48,77 MP), JPEG mostrado como 11,5 MB. El creador confirma también que exportó mediante «Compartir original → Guardar en Archivos» y encuentra un archivo de **11,7 MB**. El usuario confirmó además que **Repetir funciona**. Aún faltan dimensiones y hash del archivo guardado, pruebas prolongadas de ciclo de vida y tests automáticos. Incluye `AVCapturePhotoOutput`, intento de JPEG de máxima resolución admitida, revisión, dimensiones, bytes y hoja nativa de compartir archivo original. Archivos en almacenamiento privado temporal; no guardado permanente.
- DEV 0.1.3 **nivel de dos ejes con Core Motion implementado en main y primera lectura en iPhone confirmada mediante capturas**. Archivos: `LevelMath.swift`, `LevelMotionModel.swift`, `LevelOverlay.swift`, `LevelMathTests.swift`; autorización `NSMotionUsageDescription`; versión 0.1.3 build 4. Protocolo `docs/DEV_0.1.3_LEVEL.md`. Autodetección de bordes y comparación de calidad NO existen.

## Acciones prioritarias

1. `cd ~/Developer/Fielens && git pull --ff-only`.
2. Abrir Xcode, seleccionar iPhone, `⌘B`. Registrar errores exactos o Build Succeeded.
3. La primera fotografía y el guardado en Archivos ya están confirmados; completar prueba de `repetir → nueva foto`, comprobar en Archivos **dimensiones 8064 × 6048 px** y orientación, e idealmente verificar hash/bytes del JPEG sin pasar por el chat.
4. Ejecutar pruebas automáticas `OriginalPhotoTests` en iPhone o destino de pruebas disponible.
5. Documentar cualquier corrección, rendimiento y comportamiento de primer plano/cámara interrumpida.
6. Probar la DEV 0.1.3 desde iPhone: `git pull --ff-only`, `⌘B`, `⌘R`; confirmar que la burbuja se mueve, muestra X/Y y no declara verde en poses erróneas. Ver protocolo `docs/DEV_0.1.3_LEVEL.md`. No confundir gravedad con perpendicularidad respecto a plano inclinado.

## Archivos principales

- `apps/ios/Fielens/Fielens/CameraSession.swift`: sesión AVFoundation y captura JPEG.
- `apps/ios/Fielens/Fielens/CameraViewModel.swift`: permisos, captura y revisión.
- `apps/ios/Fielens/Fielens/CameraPreview.swift`: vista en vivo.
- `apps/ios/Fielens/Fielens/CapturedPhoto.swift`: original en carpeta temporal + metadatos de dimensiones.
- `apps/ios/Fielens/Fielens/ContentView.swift`: disparador, revisión y compartir.
- `apps/ios/Fielens/FielensTests/OriginalPhotoTests.swift`: pruebas escritas, **todavía no ejecutadas**.

## Riesgos y principios

- La previsualización `.resizeAspectFill` recorta según pantalla; la foto final puede tener otro encuadre.
- La foto JPEG contiene metadatos EXIF; no se alteran ni eliminan todavía.
- Los datos temporales no equivalen a guardado duradero; exportar explícitamente para conservar.
- No usar fotos privadas ni claves en GitHub. No publicar app al público hasta verificar elegibilidad Shipaton 2027.
- El registro de QA está en `docs/DEV_0.1.2_CAPTURE.md` y `docs/EXPERIMENT_001.md`.

## Actualización de sesión: 2026-10-25 23:28

- DEV 0.1.2: captura, Repetir y guardado en Archivos confirmados por el creador; QA de integridad y estabilidad pendiente.
- DEV 0.1.3: implementación documental/code review solamente; **no se ha podido ejecutar Xcode desde este entorno** y no hay confirmación Build Succeeded. Solo avanzar después del resultado del iPhone.


## Observación DEV 0.1.3 — 2026-10-25 23:43

El creador compartió dos capturas de nivel funcionando sobre iPhone: X −0,2°/Y −0,2° y X −0,1°/Y −0,4°. Ambos estados verdes. La prueba se hizo al borde de mesa, porque el módulo de cámaras sobresale. Esto prueba la visualización y lectura inicial, **no calibración absoluta**.

Las capturas muestran fondo de cámara negro; aún no sabemos si lente tapada, escena oscura o problema de preview. Próxima prueba: apuntar a hoja iluminada y repetir inclinaciones en ambos ejes usando soporte que deje cámara libre. No cambiar offsets ni tolerancia sin referencia independiente. Pruebas automáticas y regresiones pendientes.

### Aclaración del creador — 2026-10-25 23:45

La pantalla de cámara negra de las dos capturas se debía a que era de noche y no había luz. El creador confirma que no era un fallo. No atribuir una regresión a esas capturas. El nivel digital funciona en la prueba inicial; calibración, pruebas de inclinación y regresiones generales siguen pendientes.

## CI sin Mac — 2026-10-25

- Workflow `.github/workflows/ios-build.yml`: `macos-26` Xcode 26.6, compilación genérica iOS sin firma al modificar `apps/ios/**`; `workflow_dispatch` disponible.
- [Compilación verde](https://github.com/almaprintes/Fielens/actions/runs/40246527085) del commit `adb1b0be`, confirmada en GitHub.
- Se añadió ejecución separada de tests `FielensTests` en simulador iOS 26.5; todavía no se puede afirmar que hayan pasado hasta recibir el resultado.
- Documentación `docs/IOS_CI.md`. GitHub CI no reemplaza QA de cámara, nivel y óptica en dispositivo real.

## EXP-002 / DEV 0.1.4a — motor inicial de selección de superficies

- El creador pidió detectar el objeto al tocarlo, delimitar contorno y luego guiar perpendicularidad relativa a ese objeto. Es la dirección del producto; las limitaciones geométricas se especifican en `docs/SURFACE_TARGETING_DESIGN.md`.
- Código inicial separado de la cámara: `SurfaceGeometry.swift` (puntos normalizados, cuadriláteros convexos, selección por toque), `RectangularSurfaceDetector.swift` (Vision), `SurfaceGeometryTests.swift` (tests de geometría). **No integrado aún en interfaz ni en captura**.
- Pruebas en GitHub Actions pendientes de validar para esos archivos. No existe estimación 3D ni nivel del objeto todavía; solo el nivel gravitatorio de la 0.1.3.
- Próxima iteración: overlay y selección de rectángulos en preview con transformación coordenadas/crop/aspect fill/orientación correcta, muestreo sin bloquear captura. Luego cálculo de pose del plano calibrada con patrones conocidos, siempre con incertidumbre.
- Si CI falla, corregir errores antes de integrar con la UI. No modificar fotos originales, no subir datos personales a GitHub.

### Verificación parcial CI de EXP-002

- Build iOS cloud **succeeded** para `687dc7ff` (incluye `SurfaceGeometry.swift`, `RectangularSurfaceDetector.swift`, `SurfaceGeometryTests.swift`); [run](https://github.com/almaprintes/Fielens/actions/runs/40247295733).
- Resultado del job de pruebas del simulador pendiente al documentar. UI y perpendicularidad real aún sin implementar.

## DEV 0.1.4 — Resoluciones de envío (2026-10-26)

- Pedido: distintas resoluciones para evitar compartir siempre 48,77 MP al enviar DNI u otros documentos.
- Implementado en `main`: `PhotoExportService.swift` y ajustes en `ContentView.swift`, `PhotoExportTests.swift`, versión app `0.1.4` build 5. Opciones Ligera (1600 px), Compartir por defecto (2400 px), Detalle (4000 px), Original (sin recodificar).
- Captura nativa continúa al máximo; el tamaño elegido rige **el archivo para compartir**, no la cámara ni el JPEG original guardado temporalmente. Genera JPEG con ImageIO sin arrastrar EXIF original, en hilo de fondo; descarta copia temporal tras cerrar hoja del sistema.
- **Sin prueba física todavía**. Protocolo `docs/DEV_0.1.4_EXPORT.md`; comprobar CI del último SHA y que las pruebas Swift pasen. Medir dimensiones y bytes exportados/legibilidad sobre documento ficticio.
- El motor de superficies EXP-002 sigue en código sin UI; no existe aún nivel de perpendicularidad de objetos.

## Incidencia CI 0.1.4 y siguiente prueba local — 2026-10-26

- GitHub Actions del SHA `28da3efe`: compilación de iOS superada; falló `PhotoExportTests.aSmallPhotoIsNeverUpscaled()`.
- Se corrigió el fixture UIKit para escala de renderizado 1x, commit `4eb6809e`. Nueva CI: https://github.com/almaprintes/Fielens/actions/runs/40288358518 (resultado pendiente al redactar).
- Usuario ha vuelto al Mac. Primero `cd ~/Developer/Fielens && git status --short`; solo si no hay cambios locales, `git pull --ff-only`. Abrir proyecto Xcode y `⌘B`, `⌘R` con iPhone físico.
- Verificar exportación en Archivos para 1600 / 2400 / 4000 px lado mayor y Original; comparar orientación, dimensiones, peso, legibilidad, JPEG y eliminación de metadatos en derivados con documento ficticio. No enviar documentos reales al repositorio.


## Aclaración y corrección de UX — 2026-10-26 07:56

El creador precisa que el selector **después de tomar la foto funciona correctamente**. La incidencia afecta solo al menú desplegable sobre la vista previa de cámara, antes del disparo. La reparación final **conserva el Picker ya probado de revisión** y cambia exclusivamente el selector previo al disparo por un botón legible que abre una hoja con cuatro filas de tamaño, una selección marcada y cierre inmediato. Ambas pantallas siguen compartiendo la elección de exportación. Commit de ajuste final: `f541d4ae`. Confirmar compilación cloud y probar físicamente el desplegable previo; no cambiar el sistema de captura fotográfica ni afirmar que la elección reduce la resolución del sensor.


## Xcode tras pull — 2026-10-26 08:00

Captura del usuario: Git fast-forward `a96bc9d..6ada2ba` y Xcode con errores de `ExportResolution`/`PhotoExportService`, pero Build Succeeded a las 07:59 (anterior al pull de 08:00). CI compila el commit `6ada2ba` correctamente: [build](https://github.com/almaprintes/Fielens/actions/runs/40289092036). Antes de editar código: Clean Build Folder ⇧⌘K → ⌘B → ⌘R. Solo investigar logs si fallan de nuevo. No asumir error de target ni añadir import sin prueba.

## DEV 0.1.5 — Resolución real tras disparar

- El usuario seleccionó Ligera antes de fotografiar y vio aún 48,77 MP; esto reveló defecto de UX en DEV 0.1.4 (revisión presentaba el JPEG maestro, no derivado).
- DEV 0.1.5 build 6 en main corrige: `PreparedPhoto` identifica el JPEG concreto, sus píxeles/bytes reales; `PhotoReviewView` muestra ese JPEG y envía sus mismos bytes. Cambio de perfil regenera copia en tarea asíncrona; muestra progreso/error y limpia duplicados. La captura máxima queda como fuente temporal.
- QA `docs/DEV_0.1.5_REVIEW_RESOLUTION.md`. **No afirmar compilación/test ni ejecución física hasta comprobar SHA de CI y probar en iPhone**.
- Prueba prioritaria: elegir Ligera antes de fotografiar, revisar que la pantalla muestre alrededor de 1600 × 1200 (1,92 MP) y que Archivos conserve esas dimensiones; cambiar a Original y verificar 48,77 MP, sin repetir foto.

## DEV 0.1.6 — Superficies visibles (2026-10-26 09:01)

- El creador quiere seguir con la detección/tap de superficies y futuro nivel relativo al objeto. Implementado el primer circuito de UI para detectar **rectángulos** y seleccionarlos por toque, sin medir todavía perpendicularidad.
- `SurfaceFrameSampler.swift`: petición de análisis de un solo fotograma desde vídeo; no guardar ni enviar frames; cola de callbacks.
- `CameraSession.swift`: añade `AVCaptureVideoDataOutput` solo si compatible; no bloquear PhotoOutput si falla; `CameraViewModel.swift` estados de candidatos/escaneo/tap e invalidación al salir.
- `RectangularSurfaceDetector.swift` acepta `CVPixelBuffer`; `CameraPreview.swift` dibuja trazos seleccionables sobre preview mediante `AVCaptureVideoPreviewLayer`; `ContentView.swift` añade botón e informa limitaciones.
- Pruebas nuevas de geometría, protocolo `docs/DEV_0.1.6_SURFACE_PREVIEW.md`, Xcode versión 0.1.6 build 7.
- CRÍTICO: comprobar primero CI y luego iPhone. Asegurarse de que el nivel y la calidad del JPEG nativo (antes 48,77 MP) no sufren regresión al añadir videoOutput. Calibrar dibujo de esquinas/orientación en retrato con A4. No afirmar nivel de perpendicularidad.

## DEV 0.1.6→0.1.8 — Resultados de prueba y corrección táctil (2026-10-26 09:55)

- El creador probó DEV 0.1.6 sobre hoja: contorno menta y selección visibles, pero denuncia «La detección al toque no es nada precisa». Nivel X +0,9°, Y −5,1°; revisión con Ligera **1200 × 1600, 1,92 MP, 345 KB** (foto reducida mostrada correctamente). No guardar screenshots con texto del papel en el repo público.
- DEV 0.1.7 (build 8) compacta nivel gravitatorio (no mide perpendicularidad), lo mueve hacia arriba y permite desplegarlo.
- DEV 0.1.8 (build 9) corrige selección táctil: `SurfaceViewPoint`, `SurfaceScreenPolygon`, `SurfaceScreenSelector`, `SurfacePendingTap` en `SurfaceGeometry.swift`; `CameraPreview.swift` dibuja y selecciona con los mismos puntos proyectados a pantalla. `CameraViewModel` sincroniza toque inicial con análisis asíncrono; `ContentView` ofrece botón «Otro» para varios candidatos; nuevas pruebas de geometría.
- Build CI **success** en [run 40304171632](https://github.com/almaprintes/Fielens/actions/runs/40304171632) para commit `13240f46`. Tests Swift siguen pendientes de confirmación, junto a primera prueba física de 0.1.8.
- Procedimiento Mac: comprobar `git status --short` por cambios locales, luego `git pull --ff-only`, Xcode `⌘B`/`⌘R`. Probar centro/cuadrantes de hoja, cuadros interiores, toque directo sin Buscar, botón Otro, salida al fondo, y regresión Ligera 1,92 MP. Ver `docs/DEV_0.1.8_TOUCH_PRECISION.md`.
- Sigue sin haber normal 3D ni perpendicularidad al objeto; el contorno no se recorta automáticamente y podría quedar atrasado al mover el iPhone. No crear nuevos grandes cambios hasta ver precisión real de la selección.

## DEV 0.1.9 — Evidencia campo y corrección geométrica (2026-10-26 10:16)

- Usuario envió dos capturas DEV 0.1.8: contorno verde sobre hoja **evidentemente desplazado**, aunque el hit testing del contorno dibujado funcionara. Foto «Compartir» sale 1800 × 2400, 4,32 MP, ~1,2 MB. Nivel compacto funcionando X −1,1°, Y −3,1°. No copiar pantallazos con texto a repo público.
- Causa probable confirmada en fuente: visión `.right` normalizada rotada vs método `layerPointConverted(fromCaptureDevicePoint:)` en imagen RAW sin rotación. Antes `(x,1-y)` (incompleto), DEV 0.1.9 corrige `(1-y,1-x)`.
- `CameraSession` intenta videoRotationAngle=0 en videoDataOutput (sin forzar preview/photo output), `SurfaceFrameSampler` rechaza frames no apaisados para no mostrar geometría falsa. Tests de conversión incluyen esquinas que habrían fallado con el mapeo anterior.
- DEV 0.1.9 build 10. [Protocolo](docs/DEV_0.1.9_ORIENTATION_MAPPING.md), *pendiente CI y prueba física*, no anunciar como éxito en el iPhone hasta comparar 4 esquinas.
- Foto sin recorte automático del papel sigue siendo comportamiento actual. Recorte opcional con conservación del original es siguiente proyecto, no parte de 0.1.9.

## DEV 0.1.10 — Edición de vértices tras prueba 10:40

- El creador envió dos capturas de DEV 0.1.9: hoja delimitada por tres esquinas aproximadamente correctas pero vértice superior derecho muy bajo (diagonal verde). Pantalla de revisión demuestra Compartir **1800 × 2400, 4,32 MP, 1,4 MB**. Fotos siguen SIN recortar, deliberadamente.
- En `main` está DEV 0.1.10 build 11: `SurfaceScreenPolygon.isConvex`, gestos de arrastre de las 4 esquinas y handles menta sobre PreviewView, correcciones temporales en `CameraViewModel`, estado UI `isAdjustingSurface`, pantalla de ajuste despejada Restaurar/Listo.
- `RectangularSurfaceDetector` aplica primer intento estricto 22°/0,45/0,12 y fallback anterior 35°/0,35/0,08 si no hay rectángulo grande; NO suponer que mejora sin medir.
- [CI](https://github.com/almaprintes/Fielens/actions/runs/40310449733) compilación iOS del commit `eb7628c5` correcta; comprobar tests en simulador para ese mismo SHA. QA física con iPhone PENDIENTE. [Protocolo](docs/DEV_0.1.10_MANUAL_CORNERS.md).
- En el Mac: `git status --short`, si limpio `git pull --ff-only`, `⌘B`, `⌘R`. Elegir hoja → Ajustar esquinas → arrastrar esquina superior derecha a vértice de papel → Listo. Comprobar persiste, Restablecer restaura, Buscar de nuevo reinicia, capturas Ligera/Compartir no regresan.
- No publicar fotos del usuario en GitHub público. Aún no hay rectificación/crop 3D ni modo de congelación de imagen para ajustar.

## DEV 0.1.11 — Detección automática de superficies (26/10/2026 ~11:05)

- El creador rechaza el flujo de múltiples pulsaciones porque sostener el iPhone y seleccionar un objetivo a mano resulta difícil. En consecuencia el funcionamiento normal se cambia a **detección continua limitada de Vision**, selección y mantenimiento del contorno primario automática, sin pulsar Buscar. Corrección mediante toque o menú opcional «…».
- Código en `main`: `AutomaticSurfaceTracker.swift` (asociación estable de IDs, suavizado, heurística de rectángulo principal), `AutomaticSurfaceTrackerTests.swift`, modificaciones `CameraViewModel.swift`, `ContentView.swift`, `CameraPreview.swift`, versión 0.1.11 build 12.
- Muestreo experimental ~550 ms entre detecciones correctas (más tiempo de Vision); 850 ms sin objeto, 1800 ms ante fallos. No superponer peticiones. Se para con revisión, fondo o cámara inactiva. Toque corrector y editor avanzado siguen disponibles pero no necesarios normalmente.
- Corrección de un primer error de compilación del tracker (variable `center` sombreaba función, commit `1d716519`). **Verificar nuevo GitHub Actions verde ANTES de pedir probar en iPhone.** QA `docs/DEV_0.1.11_AUTOMATIC_SURFACES.md`.
- Riesgos: parpadeo/latencia y CPU; si se quiere seguimiento más fluido evaluar `VNTrackRectangleRequest` y detección ocasional; medir FPS, temperatura y si videoOutput altera la fotografía 48.77 MP. No confundir contorno menta con perpendicularidad certificada; disparo continúa manual.


### Verificación CI — 2026-10-26

[GitHub Actions run 40313464522](https://github.com/almaprintes/Fielens/actions/runs/40313464522) para commit `1d716519ddfca19f5d22b47287666ef7ddeda002`: **compilación iOS y todos los tests Swift del job superados** (Xcode 26.6 / simulador iOS). Los cambios posteriores a ese commit son únicamente documentales. **NO existe aún prueba del seguimiento automático en el iPhone físico** ni medición de FPS/temperatura; ese es el próximo paso antes de aceptar H-016.

## DEV 0.1.12 — El objeto debe llenar la foto (26/10/2026 11:50)

- Usuario: «relativamente fácil, mejor detección, pero la foto el encuadre no ocupa solo el objeto, ocupa mucho más». No se ha solicitado más interacción manual; necesita resultado automático final.
- Causa detectada: Vision antes solo dibujaba un overlay; `AVCapturePhotoOutput` guardaba foto completa. DEV 0.1.12 cambia la **revisión y exportación** de Ligera/Compartir/Detalle: detector Vision analiza el still y Core Image `CIFilter.perspectiveCorrection` recorta/endereza el cuadrilátero fiable. Si no existe se conserva imagen entera y se avisa. Toggle para desactivar en revisión. `Original` nunca altera bytes ni recorta.
- Archivos nuevos `SurfacePhotoProcessor.swift`, `SurfacePhotoProcessorTests.swift`; modificados `PhotoExportService.swift`, `ContentView.swift`, project.pbxproj versión 0.1.12 build 13; protocolo `docs/DEV_0.1.12_OBJECT_FRAMING.md`.
- Compilación Xcode 26.6 superada en [run 40318890182](https://github.com/almaprintes/Fielens/actions/runs/40318890182), commit `a71f9003`. Tests del simulador pendientes de conclusión al documentar. No afirmar fotografía física validada.
- **Próximo test iPhone:** apuntar hoja A4 rodeada de mesa, disparar Compartir, revisar que solo aparezca papel; apagar toggle debe mostrar escena completa; Original intacto. Comparar textos/dimensiones/posibles esquinas cortadas, consumo y errores. Documento ficticio, nunca DNI real en GitHub.
- Limitación crítica: el contorno de la foto se redetecta y elige por área/centralidad/confianza; aún no está vinculado al contorno seleccionado en preview; múltiples objetos pueden equivocarse. Segunda fase: asociar objetivo y mejorar precisión/resolución del recorte sin perder píxeles.

## DEV 0.1.13 — Menú de inicio y guardar en Fotos (26/10/2026 12:11)

- Usuario confirmó que el recorte de objeto de 0.1.12 está casi perfecto pese a luz mala, y quiere probar sin conexión al Mac. Solicitó abrir primero un menú y guardar al carrete.
- En `main`: `ContentView.swift` ahora presenta bienvenida antes de arrancar `CameraSession`/CoreMotion; botón Abrir cámara, selector de resolución, navegación hacia inicio desde cámara y revisión. `CameraViewModel.endSession()` cierra y descarta temporal.
- Servicio nuevo `PhotoLibrarySaver.swift`: permisos Photos `.addOnly`, guarda el archivo JPEG exacto de `PreparedPhoto` con `PHAssetCreationRequest` y `addResource`; no requiere acceso a lectura de carrete. UI Guardar en Fotos con progreso/resultado y bloqueos de navegación/cambio de archivo hasta terminar.
- Xcode proyecto: versión 0.1.13, build 14 y `NSPhotoLibraryAddUsageDescription` en Debug/Release.
- **Pendiente** CI SHA `d024229a` y QA físico: la app comienza en bienvenida sin cámara; desde captura se guarda la versión seleccionada/corregida y se ve en Fotos tras autorización add-only; volver de revisión/cámara a inicio no reactiva cámara. [Plan](docs/DEV_0.1.13_HOME_AND_PHOTOS.md).


### Primera verificación CI — 2026-10-26

[GitHub Actions run 40321151785](https://github.com/almaprintes/Fielens/actions/runs/40321151785), commit `d024229a994b965834415401135ce4fae987337a`: **compilación iOS exitosa con Xcode 26.6**. Los cambios posteriores a este SHA fueron únicamente documentales. El job «Swift unit tests on iOS simulator» seguía ejecutándose en la última comprobación, por lo que no se puede afirmar aún que las pruebas terminaran en verde. La autorización add-only y la aparición real en el carrete **no se pueden verificar en CI** y exigen ensayo físico.
