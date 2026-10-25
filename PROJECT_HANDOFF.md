# PROJECT_HANDOFF — Fielens

**Actualización:** 2026-10-25 (segunda sesión)

## Estado confirmado (por ejecución reportada desde Mac/iPhone)

- Xcode 26.6, macOS 26.5, Apple Git 2.50.1.
- Clonado `almaprintes/Fielens` en `~/Developer/Fielens` (rama main).
- Xcode project creado en `apps/ios/Fielens/Fielens.xcodeproj` **en el Mac**, aún no confirmado en GitHub.
- Resuelto soporte de plataforma iOS 26.5 y firma de desarrollo mediante equipo personal.
- El usuario confirmó **Build Succeeded** y la ejecución de **Hello, world!** en el iPhone físico con desarrollador confiable.
- Estado de código funcional: únicamente la plantilla iOS inicial. No hay todavía cámara, nivel ni captura.
- La etiqueta experimental para el siguiente hito es DEV 0.1.0; no se ha configurado/verificado aún número de versión en el bundle.

## Criterios de producto

- Cámara asistida universal; no exclusiva para documentos.
- Captura fiel, procesamiento local por defecto, conservar originales.
- El nivel respecto a gravedad no garantiza perpendicularidad a un soporte inclinado.
- Estrategia de medición en `docs/EXPERIMENT_001.md`.
- Objetivo Shipaton 2027: comprobar bases oficiales antes de publicación pública; no convertir las pruebas privadas en un lanzamiento prematuro.

## Seguridad del repositorio

GitHub informa visibilidad **pública**. `.gitignore` incluye exclusión de estado personal de Xcode y archivos sensibles conocidos. Revisar la lista de archivos antes de su primer push local. No incluir certificados, claves, documentos personales, capturas sensibles ni datos internos de otros proyectos.

## Próximas acciones

1. Guardar el proyecto Xcode local inicial en main (inspeccionar primero el staging y después push).
2. Implementar por incrementos verificados: preview AVFoundation y permisos; captura/revisión local; Core Motion nivel de dos ejes; contraste con EXP-001.
3. Confirmar dispositivo físico, versión iOS, formato de capturas y condiciones de ensayo. Solo avanzar tras medir.
4. Actualizar documentación con commits, resultados y fallos.

## Investigación inicial

- `docs/RESEARCH_2026-10-23.md`
- `docs/TECHNICAL_FEASIBILITY_2026-10-23.md`
- `docs/EXPERIMENT_001.md`

No se ha elegido aún el framework definitivo para Android u otras plataformas.

## DEV 0.1.1 (2026-10-25)

- Confirmado desde GitHub que ya está publicada en main la plantilla Xcode inicial y el commit de primer Hello World en dispositivo.
- Incorporados en main CameraSession.swift, CameraPreview.swift, CameraViewModel.swift y nueva ContentView.swift.
- Ajustadas configuraciones de la app: permiso NSCameraUsageDescription, versión DEV 0.1.1 (build 2).
- Diseño técnico: AVFoundation en cola serie para configurar e iniciar/detener, UIKit preview desde SwiftUI, autorización en UI, sin captura ni micrófono ni guardado.
- **No probado aún el nuevo código en Mac/iPhone**. Próxima acción obligatoria: pull + ⌘B + ⌘R en iPhone, anotar errores y observar comportamiento.
- Protocolo: docs/DEV_0.1.1_CAMERA.md. EXP-001 sigue abierto; todavía no hay nivel ni datos experimentales.
- Fase siguiente *solo tras prueba*: fotografía real con revisión y conservación de original; después Core Motion. No confundir estado del dispositivo horizontal con perpendicularidad respecto a soportes inclinados.
