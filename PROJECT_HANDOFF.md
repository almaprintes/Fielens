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
