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
- DEV 0.1.2: **implementada en GitHub pero todavía NO compilada ni probada en iPhone**. Incluye `AVCapturePhotoOutput`, intento de JPEG de máxima resolución admitida, revisión, dimensiones, bytes y ShareLink original. Archivos en almacenamiento privado temporal; no guardado permanente.
- El nivel con Core Motion, autodetección de bordes y comparación de calidad todavía **no existen**.

## Acciones prioritarias

1. `cd ~/Developer/Fielens && git pull --ff-only`.
2. Abrir Xcode, seleccionar iPhone, `⌘B`. Registrar errores exactos o Build Succeeded.
3. Si compila, `⌘R`, probar cámara→disparo→revisión→repetir→compartir JPEG en Archivos, registrar dimensiones, orientación y bytes.
4. Ejecutar pruebas automáticas `OriginalPhotoTests` en iPhone o destino de pruebas disponible.
5. Documentar cualquier corrección, rendimiento y comportamiento de primer plano/cámara interrumpida.
6. Solo después estudiar DEV 0.1.3 (nivel Core Motion de dos ejes y calibración). No confundir gravedad con perpendicularidad respecto a plano inclinado.

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
