# Diario de desarrollo — Fielens

**Objetivo:** conservar una narración cronológica de cambios, pruebas físicas, errores, arreglos y decisiones. El registro de hitos verificables y estados está en [MILESTONES.md](MILESTONES.md). El trabajo pendiente y el código se consultan directamente en GitHub.

## 2026-10-23 — Nacimiento y estrategia

- Problema definido: la gente comparte fotografías torcidas, mal enfocadas y con sombras, reflejos o recortes.
- Alcance ampliado por decisión del creador: **cualquier soporte físico sensible a compartir**, no solo documentos.
- Elemento original de la propuesta: asistencia en tiempo real antes del disparo, validada con pruebas, no solo corrección posterior.
- Nombre aceptado: **Fielens**. Es nombre de proyecto, aún sin garantías de disponibilidad registral o de tiendas.
- Meta estratégica: Shipaton 2027, con posible estreno agosto/septiembre de 2027, sujeto a normativa oficial.
- Creado repositorio `almaprintes/Fielens`, documentación básica, reglas de desarrollo y planificación experimental.

## 2026-10-23 — Investigación inicial

- Comparados documentalmente Apple, Adobe Scan, Genius Scan, PhotoScan, SwiftScan y otros. Captura automática, detección de bordes y eliminación de reflejos no son por sí solas novedades.
- APIs candidatas: AVFoundation (cámara), Core Motion (movimiento), Vision (rectángulos) y Core Image (transformación). Android pendiente.
- Definido EXP-001: medir si la guía mejora los resultados frente a captura sin ayuda.
- Importante: nivelación respecto de gravedad **no implica** perpendicularidad a una superficie inclinada.

## 2026-10-25 — Infraestructura y primera instalación iPhone

- Entorno comunicado: Xcode 26.6, macOS 26.5, Git 2.50.1.
- Clonado en `~/Developer/Fielens`, rama main.
- Creado proyecto SwiftUI iOS con Swift Testing y UI tests en `apps/ios/Fielens/Fielens.xcodeproj`.
- Xcode inicialmente pedía componente iOS 26.5: se diagnosticó espacio limitado. Identificados 25 GB de modelos OpenVINO de Audacity, borrados sin afectar repositorios; el Mac pasó de ~11 a 35 GiB disponibles.
- Firma de desarrollo: el equipo de Xcode estaba ausente; configurada cuenta Personal Team. El creador confirmó Build Succeeded y `Hello, world!` ejecutado en el iPhone.
- Detectado repositorio Git anidado creado por Xcode; respaldada su `.git` fuera de Fielens y el código se integró en el repo raíz.
- GitHub rechazaba password por HTTPS; instalada herramienta `gh` y autorizada mediante navegador, sin compartir tokens.
- Primera plantilla iOS subida a GitHub; commit local original `070d908`.

## 2026-10-25 — DEV 0.1.1 cámara

- Añadido AVFoundation con `AVCaptureSession` en cola serie, preview SwiftUI/UIKit, solicitud de permiso y mensajes de estados.
- Error real de primera compilación (seis problemas de Xcode): faltaba `import Combine` y un cierre `onChange` no coincidía con la sobrecarga elegida; corregidos en main.
- **Confirmado por el creador a las 23:00:** «funciona!!!» en su iPhone, cámara en directo.
- Por comprobar: interrupciones, recuperación en primer plano, orientación y permiso denegado. No hay datos métricos ni foto guardada.

## 2026-10-25 — DEV 0.1.2 fotografía y revisión (primera captura en iPhone)

- Diseñada captura `AVCapturePhotoOutput` solicitando JPEG, calidad alta y mayores dimensiones admitidas por formato activo.
- `fileDataRepresentation()` se conserva sin recodificar; registro del tamaño original de píxeles y bytes mediante ImageIO.
- La foto queda solo en el directorio temporal privado de la app. Vista de revisión, opción repetir (descartar) y compartir el fichero original mediante el sistema.
- Sin permiso de Fotos, sin cuenta, sin red, sin filtros, sin nivel todavía.
- **23:17, informe del creador desde el iPhone:** primera fotografía realizada y resolución mostrada por Fielens: **8064 × 6048 píxeles (48,77 MP), 11,5 MB**. Demuestra el funcionamiento del flujo de captura y obtención de metadatos en dispositivo; compilación y ejecución quedan implícitas por la prueba reportada, sin disponer del log de compilación.
- Resolución calculada: **48.771.072 píxeles**, relación **4:3**; el tamaño en disco lo indica la app y se considera aproximado (formato localizado). La alta resolución **no** demuestra nitidez, exactitud geométrica ni fidelidad del color.
- **Prueba aún parcial:** no consta validación de exportar JPEG sin transformación, de repetir/descartar, de permisos, orientación, ciclos de vida ni de tests automáticos. El hito H-008 permanece abierto hasta completar estas pruebas.

## Esquema exigido para futuras sesiones

Fecha/hora · versión · commit · entorno/dispositivo · objetivo · cambios · pruebas ejecutadas · evidencias · fallos abiertos · conclusión · siguiente iteración.

Nunca registrar identificadores personales de los teléfonos, fotos de terceros, claves, documentos sensibles ni datos privados en este repositorio público.

### 23:22 — Fotografía de prueba compartida en conversación

- El creador compartió una imagen de ensayo con un ratón sobre soporte y teclado en escena de luz desigual. Observación visual: sombras intensas en la parte superior izquierda, luz lateral fuerte, algunas teclas menos nítidas.
- **Metadatos comprobados de la copia recibida en el chat:** JPEG de **1536 × 2048 píxeles**, **503.960 bytes** (aprox. 0,50 MB), sin etiquetas EXIF expuestas. **No coincide** con los 8064 × 6048 píxeles y 11,5 MB reportados por Fielens en la captura anterior.
- No hay evidencia suficiente para atribuir el cambio de dimensiones al código de Fielens; los sistemas de envío y mensajería pueden crear copias redimensionadas. Para validar integridad, guardar el fichero desde la hoja de compartir de Fielens en Archivos y comparar con el tamaño/dimensiones registrados antes de exportar.
- La recepción en el chat tampoco prueba por sí sola que el botón **Repetir** ni la exportación de archivo sin cambios estén validados. **Ambas pruebas siguen pendientes de confirmación**.
- Imagen de ensayo **no incorporada al repositorio público**.

### 23:25 — Confirmación de exportación a Archivos

- El creador aclara que utilizó «Compartir original → Guardar en Archivos» en Fielens y que allí el fichero ocupa **11,7 MB**.
- La aplicación informó previamente **8064 × 6048 píxeles, 48,77 MP, 11,5 MB**. La discrepancia de tamaños de visualización requiere determinar las unidades y redondeo o comparar el mismo archivo; no se asume corrupción.
- La imagen llegada al chat es mucho menor (**1536 × 2048**): se sospecha redimensionado por el canal de conversación, pero no se ha comprobado la cadena de procesamiento.
- **Estado:** captura y exportación en Archivos funcionan según prueba manual del creador; aún falta confirmar las dimensiones del JPEG en Archivos, identidad exacta del contenido, el botón Repetir, orientación y regresiones.

## 2026-10-25 23:28 — Confirmación y comienzo DEV 0.1.3

- El creador confirma «funciona» después de la solicitud de probar **Repetir**. Se registra como confirmación funcional del botón en la 0.1.2, sin afirmar pruebas de múltiples ciclos, identidad hash del JPEG o recuperación tras interrupciones.
- Implementada DEV 0.1.3 en GitHub: `LevelMath.swift`, `LevelMotionModel.swift`, `LevelOverlay.swift`, actualización `ContentView.swift`, Info.plist generado con `NSMotionUsageDescription` y versión 0.1.3 (build 4). Añadidas pruebas `LevelMathTests.swift`.
- Indicador usa Core Motion fusionado a unos **20 Hz**, filtro ligero alfa 0,25 y publicación de muestra en actor principal. Solo se evalúan X/Y de la gravedad y el teléfono con pantalla hacia arriba. Tolerancia ±2° **experimental**. Los datos no se guardan ni envían.
- El nivel se detiene en segundo plano, al pasar a revisión fotográfica y al desaparecer la pantalla. Se pretende mantener intacta la captura JPEG de la 0.1.2.
- **Estado real:** código subido y revisado documentalmente; no disponemos de compilación ni prueba del nivel en un iPhone. No marcarlo como hito validado todavía.
- Referencia del plan de pruebas: [DEV_0.1.3_LEVEL.md](DEV_0.1.3_LEVEL.md). Próximo paso `git pull --ff-only`, `⌘B`, `⌘R`; registrar precisión observada, fallos y estabilidad en el dispositivo.


## 2026-10-25 23:41–23:43 — Primera prueba física del nivel DEV 0.1.3

- El creador reporta «funciona casi perfecto» y facilita dos capturas reales de DEV 0.1.3. Queda confirmada su ejecución en iPhone y lectura de Core Motion.
- Captura A: **X = −0,2°, Y = −0,2°**. Captura B: **X = −0,1°, Y = −0,4°**. Indicador verde («Alineado con el horizonte») en ambos casos, coherente con tolerancia experimental ±2°.
- Máximo valor absoluto visto: **0,4°**; esto NO mide el error absoluto ni la precisión del instrumento, pues no hay nivel físico de referencia ni condiciones controladas. La diferencia entre capturas de 0,1°/0,2° tampoco representa repetibilidad cuantificada.
- Descubierta limitación de la prueba: el saliente del módulo de cámaras impide apoyar plana la trasera; se apoyó el iPhone en borde de mesa. Para calibrar debe existir una referencia independiente y un apoyo estable con cámara libre.
- La vista previa se ve negra en las capturas pese al estado «Cámara activa». Puede ser escena oscura/objetivo obstruido o regresión; verificar con hoja iluminada antes de diagnosticar. NO subir las imágenes del usuario al repositorio público.
- **Estado H-009:** lectura y presentación funcionales; faltan pruebas de inclinación, pose vertical/invertida, reanudación, lectura sobre referencia nivelada, preview y fotografías, más tests automáticos.

### Aclaración del creador — 2026-10-25 23:45

La pantalla de cámara negra de las dos capturas se debía a que era de noche y no había luz. El creador confirma que no era un fallo. No atribuir una regresión a esas capturas. El nivel digital funciona en la prueba inicial; calibración, pruebas de inclinación y regresiones generales siguen pendientes.

## 2026-10-25 — CI remoto sin Mac del creador

- Por solicitud del creador, que apagó el Mac, se habilitó GitHub Actions en `main` usando `macos-26` y Xcode 26.6, sin firma ni distribución pública.
- **Compilación verificada:** [run #1](https://github.com/almaprintes/Fielens/actions/runs/40246527085), SHA `adb1b0be4a0e5b6e469a7df5c3ee4dd99fc11061`, resultado **success** en el job `Compile iOS without signing`.
- Se extendió el workflow para añadir ejecución de pruebas `Swift Testing` del target `FielensTests` con un simulador iOS 26.5 en GitHub; resultado de primera ejecución pendiente al incorporar el job. No se ejecutan tests UI ni se accede a cámara física.
- Política: el build en la nube asegura compilabilidad bajo el SDK indicado; NO equivale a prueba en dispositivo ni a calidad fotográfica medida.
- [Manual CI](IOS_CI.md).

## 2026-10-25 — EXP-002: selección de objeto y futuro nivel relativo al plano

- El creador propone tocar el objeto en pantalla, detectar su contorno y orientar el móvil **perpendicular al objeto** en lugar de solo respecto a la gravedad.
- Contrastado con APIs Apple: Vision detecta rectángulos por cuatro esquinas; máscaras de instancia pueden identificar algunos objetos, pero una silueta arbitraria no determina el plano real. ARKit puede detectar planos, con capacidades variables por dispositivo.
- Se define distinción estricta: superficie plana rectangular (candidata a estimar pose calibrada) frente a planos irregulares y objetos 3D (requieren datos adicionales o no tienen normal única). No prometer perpendicularidad perfecta.
- Implementada **DEV 0.1.4a** como primer módulo aislado: `SurfaceGeometry.swift`, `RectangularSurfaceDetector.swift`, `SurfaceGeometryTests.swift`. Contornos válidos convexos y selección por toque normalizado; detección con `VNDetectRectanglesRequest` en una imagen `CGImage`, sin conexión con preview todavía.
- Documentado protocolo y futuro flujo de UX en `docs/SURFACE_TARGETING_DESIGN.md`.
- **Estado:** código subido a GitHub, todavía sin test en dispositivo ni contornos dibujados, pendiente de comprobar CI. Sin cambios en pipeline de captura JPEG ni en la app visible.

### Verificación de compilación remota del módulo EXP-002

- [GitHub Actions run](https://github.com/almaprintes/Fielens/actions/runs/40247295733): job de compilación iOS (Xcode 26.6, sin firma) **success** para el commit `687dc7ffe436543b2d681f76ba61387013ec7591` con el detector y pruebas de geometría ya en el repo.
- El job de pruebas Swift en simulador aún no había concluido al registrar esta comprobación. No afirmar tests verdes ni uso de cámara en iPhone.

## 2026-10-26 — DEV 0.1.4: resolución adecuada al destino

- El creador pide poder elegir distintas resoluciones: enviar un DNI por WhatsApp no justifica 48,77 MP.
- Decisión experimental: **captura a máxima resolución + elección de resolución de exportación** para poder compartir la misma fotografía en varios tamaños sin volver a capturar. La opción inicial es «Compartir» 2400 px de lado mayor (≈4,3 MP si 4:3). Además: Ligera 1600 px, Detalle 4000 px, Original sin cambios. Las cifras son cotas máximas, no promesas de tamaño en MB ni nitidez.
- Implementado con ImageIO en `PhotoExportService.swift`, integración en `ContentView.swift` tanto antes de fotografiar como al revisar, procesamiento fuera del hilo principal, hoja de compartir y borrado de copia temporal al cerrar. El original de la sesión no se modifica.
- Privacidad: los derivados no copian EXIF original; la elección «Original» conserva todos los metadatos. No hay envío remoto automático ni pruebas con identificaciones reales.
- Añadidos `PhotoExportTests.swift` para original sin cambios, resolución de derivados, no ampliación y exclusión de GPS. Identificado como DEV 0.1.4 build 5. El motor EXP-002 de detección de rectángulos sigue independiente de interfaz.
- **Estado:** cambios subidos a `main`; pendiente confirmar CI de commit final, tests completos y prueba funcional en el iPhone. [Protocolo](DEV_0.1.4_EXPORT.md).


## Aclaración y corrección de UX — 2026-10-26 07:56

El creador precisa que el selector **después de tomar la foto funciona correctamente**. La incidencia afecta solo al menú desplegable sobre la vista previa de cámara, antes del disparo. La reparación final **conserva el Picker ya probado de revisión** y cambia exclusivamente el selector previo al disparo por un botón legible que abre una hoja con cuatro filas de tamaño, una selección marcada y cierre inmediato. Ambas pantallas siguen compartiendo la elección de exportación. Commit de ajuste final: `f541d4ae`. Confirmar compilación cloud y probar físicamente el desplegable previo; no cambiar el sistema de captura fotográfica ni afirmar que la elección reduce la resolución del sensor.
