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

## 2026-10-25 — DEV 0.1.2 fotografía y revisión (pendiente de prueba física)

- Diseñada captura `AVCapturePhotoOutput` solicitando JPEG, calidad alta y mayores dimensiones admitidas por formato activo.
- `fileDataRepresentation()` se conserva sin recodificar; registro del tamaño original de píxeles y bytes mediante ImageIO.
- La foto queda solo en el directorio temporal privado de la app. Vista de revisión, opción repetir (descartar) y compartir el fichero original mediante el sistema.
- Sin permiso de Fotos, sin cuenta, sin red, sin filtros, sin nivel todavía.
- El código y documentación están en GitHub; **no consta Build Succeeded ni ejecución física de 0.1.2**.

## Esquema exigido para futuras sesiones

Fecha/hora · versión · commit · entorno/dispositivo · objetivo · cambios · pruebas ejecutadas · evidencias · fallos abiertos · conclusión · siguiente iteración.

Nunca registrar identificadores personales de los teléfonos, fotos de terceros, claves, documentos sensibles ni datos privados en este repositorio público.
